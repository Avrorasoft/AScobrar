import 'package:hive_flutter/hive_flutter.dart';
import '../models/client_model.dart';
import '../models/loan_model.dart';
import '../models/payment_model.dart';
import '../models/user_model.dart';

class DataService {
  DataService._();

  static const _clientsBox = 'clients';
  static const _loansBox = 'loans';
  static const _paymentsBox = 'payments';
  static const _settingsBox = 'settings';
  static const _usersBox = 'users';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_clientsBox);
    await Hive.openBox(_loansBox);
    await Hive.openBox(_paymentsBox);
    await Hive.openBox(_settingsBox);
    await Hive.openBox(_usersBox);
    await _initDefaultAdmin();
    await seedDemoData();
  }

  static Box get clients => Hive.box(_clientsBox);
  static Box get loans => Hive.box(_loansBox);
  static Box get payments => Hive.box(_paymentsBox);
  static Box get settings => Hive.box(_settingsBox);
  static Box get users => Hive.box(_usersBox);

  // ============================================================
  // USUARIOS Y AUTENTICACIÓN (100% POR TELÉFONO)
  // ============================================================

  static Future<void> _initDefaultAdmin() async {
    bool hasAdmin = false;
    for (final raw in users.values) {
      if (raw is Map) {
        final phone = (raw['phone'] ?? '').toString().trim();
        if (phone == '70000000') hasAdmin = true;
      }
    }

    if (!hasAdmin) {
      final adminUser = {
        'id': 'admin_default',
        'name': 'Administrador Principal',
        'phone': '70000000',
        'password': 'admin',
        'role': 'owner',
        'createdAt': DateTime.now().toIso8601String(),
        'isActive': true,
      };
      await users.put('admin_default', adminUser);
    }

    final alreadyProvisioned = settings.get('initial_users_provisioned', defaultValue: false);
    if (!alreadyProvisioned) {
      bool hasCollector = false;
      for (final raw in users.values) {
        if (raw is Map) {
          final role = raw['role']?.toString();
          if (role == 'collector') hasCollector = true;
        }
      }

      if (!hasCollector) {
        final collectorUser = {
          'id': 'collector_default',
          'name': 'Juan Carlos Pérez',
          'phone': '70000002',
          'password': '123456',
          'role': 'collector',
          'createdAt': DateTime.now().toIso8601String(),
          'isActive': true,
        };
        await users.put('collector_default', collectorUser);
      }
      await settings.put('initial_users_provisioned', true);
    }
  }

  static AppUser? authenticate({required String phone, required String password}) {
    final cleanPhone = phone.trim();
    final cleanPass = password.trim();

    for (final entry in users.toMap().entries) {
      final raw = entry.value;
      if (raw is Map) {
        final uPhone = (raw['phone'] ?? '').toString().trim();
        final uPass = (raw['password'] ?? '').toString().trim();
        final isActive = raw['isActive'] == true;

        if (uPhone == cleanPhone && uPass == cleanPass && isActive) {
          return AppUser.fromMap(Map<String, dynamic>.from(raw), entry.key.toString());
        }
      }
    }
    return null;
  }

  static List<AppUser> allCollectors() {
    final list = <AppUser>[];
    for (final entry in users.toMap().entries) {
      final raw = entry.value;
      if (raw is Map) {
        final role = raw['role']?.toString();
        if (role == 'collector') {
          list.add(AppUser.fromMap(Map<String, dynamic>.from(raw), entry.key.toString()));
        }
      }
    }
    return list;
  }

  static Future<void> createCollector({
    required String name,
    required String phone,
    String? password,
    String? initialPassword,
  }) async {
    final effectivePass = (password ?? initialPassword ?? '123456').trim();
    final newId = 'collector_${DateTime.now().millisecondsSinceEpoch}';
    final user = {
      'id': newId,
      'name': name.trim(),
      'phone': phone.trim(),
      'password': effectivePass,
      'role': 'collector',
      'createdAt': DateTime.now().toIso8601String(),
      'isActive': true,
    };
    await users.put(newId, user);
  }

  static Future<void> updateCollector(String userId, Map<String, dynamic> updated) async {
    await users.put(userId, updated);
  }

  static Future<void> updatePassword({required String userId, required String newPassword}) async {
    final raw = users.get(userId);
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      map['password'] = newPassword.trim();
      await users.put(userId, map);
    }
  }

  static Future<void> deleteCollector(String userId) async {
    await users.delete(userId);

    for (final key in loans.keys) {
      final val = loans.get(key);
      if (val is Map) {
        final cId = val['collectorId']?.toString();
        if (cId == userId || (userId == 'collector_default' && cId == '70000002')) {
          final updatedLoan = Map<String, dynamic>.from(val);
          updatedLoan['collectorId'] = 'admin_default';
          await loans.put(key, updatedLoan);
        }
      }
    }
    await settings.put('initial_users_provisioned', true);
  }

  static AppUser? getSessionByRole(UserRole role) {
    final activeId = settings.get('active_user_id_${role.name}');
    if (activeId != null) {
      final raw = users.get(activeId);
      if (raw is Map) {
        return AppUser.fromMap(Map<String, dynamic>.from(raw), activeId.toString());
      }
    }
    return null;
  }

  static AppUser? getCurrentUserSession() {
    final activeId = settings.get('active_user_id');
    if (activeId == null) return null;
    final raw = users.get(activeId);
    if (raw is Map) {
      return AppUser.fromMap(Map<String, dynamic>.from(raw), activeId.toString());
    }
    return null;
  }

  static Future<void> saveUserSession(dynamic userOrId) async {
    final String id = userOrId is AppUser ? userOrId.id : userOrId.toString();
    final raw = users.get(id);
    await settings.put('active_user_id', id);
    if (raw is Map) {
      final role = raw['role']?.toString();
      if (role != null) {
        await settings.put('active_user_id_$role', id);
      }
    }
  }

  static Future<void> clearUserSession() async {
    await settings.delete('active_user_id');
  }

  // ============================================================
  // CLIENTES (TELÉFONO Y DIRECCIÓN, SIN EMAIL)
  // ============================================================

  static List<Client> allClients() {
    final list = <Client>[];
    for (final entry in clients.toMap().entries) {
      final raw = entry.value;
      if (raw is Map) {
        final map = Map<String, dynamic>.from(raw);
        map['id'] = entry.key.toString();
        list.add(Client.fromMap(map));
      }
    }
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  static Client? getClient(String clientId) {
    final raw = clients.get(clientId);
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      map['id'] = clientId;
      return Client.fromMap(map);
    }
    return null;
  }

  static Future<String> createClient({
    required String name,
    required String documentId,
    required String phone,
    String? phoneSecondary,
    String? address,
    String? street,
    String? neighborhood,
    String? business,
  }) async {
    final newId = 'cli_${DateTime.now().millisecondsSinceEpoch}';
    final effectiveAddress = (street != null && street.isNotEmpty)
        ? street
        : (address ?? '');
    final map = {
      'id': newId,
      'name': name.trim(),
      'documentId': documentId.trim(),
      'phone': phone.trim(),
      'phoneSecondary': phoneSecondary?.trim() ?? '',
      'address': effectiveAddress.trim(),
      'street': effectiveAddress.trim(),
      'neighborhood': neighborhood?.trim() ?? '',
      'business': business?.trim() ?? '',
      'createdAt': DateTime.now().toIso8601String(),
    };
    await clients.put(newId, map);
    return newId;
  }

  static Future<void> updateClient(Client client) async {
    await clients.put(client.id, client.toMap());
  }

  // ============================================================
  // PRÉSTAMOS
  // ============================================================

  static List<Loan> allLoans() {
    final list = <Loan>[];
    for (final entry in loans.toMap().entries) {
      final raw = entry.value;
      if (raw is Map) {
        final map = Map<String, dynamic>.from(raw);
        map['id'] = entry.key.toString();
        list.add(Loan.fromMap(map));
      }
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  static Loan? getLoan(String loanId) {
    final raw = loans.get(loanId);
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      map['id'] = loanId;
      return Loan.fromMap(map);
    }
    return null;
  }

  static List<Loan> loansOfClient(String clientId) {
    return allLoans().where((l) => l.clientId == clientId).toList();
  }

  static Future<String> createLoan(Loan loan) async {
    await loans.put(loan.id, loan.toMap());
    return loan.id;
  }

  static Future<void> syncLoanFinancials(String loanId) async {
    final loan = getLoan(loanId);
    if (loan == null) return;

    final loanPayments = paymentsOfLoan(loanId);
    double totalPaid = 0.0;
    int covered = 0;

    for (final p in loanPayments) {
      totalPaid += p.amount;
      covered += p.installmentsCovered;
    }

    final totalCredit = loan.principal * (1.0 + (loan.interestRate / 100.0));
    final newPending = (totalCredit - totalPaid).clamp(0.0, double.infinity);

    final raw = loans.get(loanId);
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      map['pendingAmount'] = newPending;
      map['paidInstallments'] = covered;
      if (newPending <= 0.0) {
        map['status'] = 'paid';
      }
      await loans.put(loanId, map);
    }
  }

  // ============================================================
  // PAGOS Y RECAUDACIONES
  // ============================================================

  static List<Payment> allPayments() {
    final list = <Payment>[];
    for (final entry in payments.toMap().entries) {
      final raw = entry.value;
      if (raw is Map) {
        final map = Map<String, dynamic>.from(raw);
        map['id'] = entry.key.toString();
        list.add(Payment.fromMap(map));
      }
    }
    list.sort((a, b) => b.paidAt.compareTo(a.paidAt));
    return list;
  }

  static List<Payment> paymentsOfLoan(String loanId) {
    return allPayments().where((p) => p.loanId == loanId).toList();
  }

  static List<Payment> paymentsOfClient(String clientId) {
    return allPayments().where((p) => p.clientId == clientId).toList();
  }

  static double totalPaidOfLoan(String loanId) {
    final list = paymentsOfLoan(loanId);
    return list.fold<double>(0.0, (acc, p) => acc + p.amount);
  }

  static Future<void> registerPayment(Payment payment) async {
    await payments.put(payment.id, payment.toMap());

    final loanRaw = loans.get(payment.loanId);
    if (loanRaw is Map) {
      final updatedLoan = Map<String, dynamic>.from(loanRaw);
      final currentPending = (updatedLoan['pendingAmount'] as num?)?.toDouble() ?? 0.0;
      final currentPaidCount = (updatedLoan['paidInstallments'] as int?) ?? 0;
      final newPending = (currentPending - payment.amount).clamp(0.0, double.infinity);

      updatedLoan['pendingAmount'] = newPending;
      updatedLoan['paidInstallments'] = currentPaidCount + payment.installmentsCovered;
      if (newPending <= 0.0) {
        updatedLoan['status'] = 'paid';
      }
      await loans.put(payment.loanId, updatedLoan);
    }
  }

  static Future<void> deletePayment(String paymentId) async {
    final raw = payments.get(paymentId);
    if (raw is Map) {
      final loanId = raw['loanId']?.toString();
      await payments.delete(paymentId);
      if (loanId != null) {
        await syncLoanFinancials(loanId);
      }
    }
  }

  // ============================================================
  // DATOS DEMOSTRATIVOS
  // ============================================================

    static Future<void> seedDemoData() async {
    final alreadySeeded = settings.get('demo_data_seeded', defaultValue: false);
    if (alreadySeeded) return;
    await settings.put('demo_data_seeded', true);
    if (clients.isNotEmpty) return;

    final now = DateTime.now();

    const c1Id = 'demo_client_1';
    final c1 = {
      'id': c1Id,
      'name': 'Carlos Ribera Hurtado',
      'documentId': '4839201-BE',
      'phone': '71122334',
      'phoneSecondary': '',
      'address': 'Barrio Central, Calle Sucre #145',
      'street': 'Barrio Central, Calle Sucre #145',
      'neighborhood': 'Central',
      'business': 'Comercializadora de Almendra',
      'createdAt': now.subtract(const Duration(days: 30)).toIso8601String(),
    };
    await clients.put(c1Id, c1);

    const c2Id = 'demo_client_2';
    final c2 = {
      'id': c2Id,
      'name': 'María Elena Vaca',
      'documentId': '5920184-BE',
      'phone': '72233445',
      'phoneSecondary': '',
      'address': 'Av. Héroes del Chaco #45',
      'street': 'Av. Héroes del Chaco #45',
      'neighborhood': 'San José',
      'business': 'Snack El Trébol',
      'createdAt': now.subtract(const Duration(days: 20)).toIso8601String(),
    };
    await clients.put(c2Id, c2);

    const l1Id = 'demo_loan_1';
    final l1 = {
      'id': l1Id,
      'clientId': c1Id,
      'collectorId': 'admin_default',
      'principal': 2000.0,
      'interestRate': 10.0,
      'installments': 20,
      'paidInstallments': 5,
      'pendingAmount': 1650.0,
      'createdAt': now.subtract(const Duration(days: 15)).toIso8601String(),
      'dueDate': now.add(const Duration(days: 15)).toIso8601String(),
      'status': 'active',
    };
    await loans.put(l1Id, l1);

    const l2Id = 'demo_loan_2';
    final l2 = {
      'id': l2Id,
      'clientId': c2Id,
      'collectorId': 'admin_default',
      'principal': 1000.0,
      'interestRate': 15.0,
      'installments': 10,
      'paidInstallments': 2,
      'pendingAmount': 920.0,
      'createdAt': now.subtract(const Duration(days: 8)).toIso8601String(),
      'dueDate': now.add(const Duration(days: 22)).toIso8601String(),
      'status': 'active',
    };
    await loans.put(l2Id, l2);
  }
}

