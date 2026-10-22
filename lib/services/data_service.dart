import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/client_model.dart';
import '../models/loan_model.dart';
import '../models/payment_model.dart';
import '../models/user_model.dart';

class DataService {
  static late Box _usersBox;
  static late Box _clientsBox;
  static late Box _loansBox;
  static late Box _paymentsBox;
  static late Box _sessionBox;
  static late Box _settingsBox;

  static Box get users => _usersBox;
  static Box get clients => _clientsBox;
  static Box get loans => _loansBox;
  static Box get payments => _paymentsBox;
  static Box get session => _sessionBox;
  static Box get settings => _settingsBox;

  static Future<void> init() async {
    await Hive.initFlutter();
    _usersBox = await Hive.openBox('users');
    _clientsBox = await Hive.openBox('clients');
    _loansBox = await Hive.openBox('loans');
    _paymentsBox = await Hive.openBox('payments');
    _sessionBox = await Hive.openBox('session');
    _settingsBox = await Hive.openBox('settings');

    if (_usersBox.isEmpty) {
      final defaultOwner = AppUser(
        id: 'owner_1',
        phone: '77777777',
        name: 'Administrador',
        role: UserRole.owner,
        createdAt: DateTime.now(),
      );
      final map = defaultOwner.toMap();
      map['password'] = 'admin';
      await _usersBox.put(defaultOwner.id, map);

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(defaultOwner.id)
            .set(map, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  // --- Sesión ---
  static AppUser? getCurrentUserSession() {
    final raw = _sessionBox.get('current_user');
    if (raw == null) return null;
    final map = Map<String, dynamic>.from(raw as Map);
    final id = map['id']?.toString() ?? 'session_user';
    return AppUser.fromMap(map, id);
  }

  static Future<void> saveUserSession(AppUser user) async {
    await _sessionBox.put('current_user', user.toMap());
  }

  static Future<void> clearUserSession() async {
    await _sessionBox.delete('current_user');
  }

  static AppUser? authenticate({required String phone, required String password}) {
    for (final key in _usersBox.keys) {
      final raw = _usersBox.get(key);
      if (raw == null) continue;
      final map = Map<String, dynamic>.from(raw as Map);
      final id = key.toString();
      final pPhone = (map['phone'] ?? '').toString().trim();
      final pPass = (map['password'] ?? '').toString().trim();
      if (pPhone == phone.trim() && pPass == password.trim()) {
        return AppUser.fromMap(map, id);
      }
    }
    return null;
  }

  // --- Cobradores y Usuarios ---
  static List<AppUser> allCollectors() {
    final List<AppUser> list = [];
    for (final key in _usersBox.keys) {
      final raw = _usersBox.get(key);
      if (raw == null) continue;
      final map = Map<String, dynamic>.from(raw as Map);
      final id = key.toString();
      final user = AppUser.fromMap(map, id);
      if (user.role == UserRole.collector) {
        list.add(user);
      }
    }
    return list;
  }

  static Future<void> createCollector({
    required String name,
    required String phone,
    required String initialPassword,
  }) async {
    final id = 'col_${DateTime.now().millisecondsSinceEpoch}';
    final user = AppUser(
      id: id,
      name: name,
      phone: phone,
      role: UserRole.collector,
      createdAt: DateTime.now(),
    );

    final map = user.toMap();
    map['password'] = initialPassword;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(id)
          .set(map, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error guardando en Firestore: $e');
    }

    await _usersBox.put(id, map);
  }

  static Future<void> deleteCollector(String id) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(id).delete();
    } catch (_) {}
    await _usersBox.delete(id);
  }

  static Future<void> updatePassword({
    required String userId,
    required String newPassword,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set({'password': newPassword}, SetOptions(merge: true));
    } catch (_) {}

    final raw = _usersBox.get(userId);
    if (raw != null) {
      final map = Map<String, dynamic>.from(raw as Map);
      map['password'] = newPassword;
      await _usersBox.put(userId, map);
    }
  }

  // --- Clientes ---
  static List<Client> allClients() {
    final List<Client> list = [];
    for (final raw in _clientsBox.values) {
      if (raw == null) continue;
      list.add(Client.fromMap(Map<String, dynamic>.from(raw as Map)));
    }
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  static Client? getClient(String id) {
    final raw = _clientsBox.get(id);
    if (raw == null) return null;
    return Client.fromMap(Map<String, dynamic>.from(raw as Map));
  }

  // --- Préstamos ---
  static List<Loan> allLoans() {
    final List<Loan> list = [];
    for (final raw in _loansBox.values) {
      if (raw == null) continue;
      list.add(Loan.fromMap(Map<String, dynamic>.from(raw as Map)));
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  static Loan? getLoan(String id) {
    final raw = _loansBox.get(id);
    if (raw == null) return null;
    return Loan.fromMap(Map<String, dynamic>.from(raw as Map));
  }

  static List<Loan> loansOfClient(String clientId) {
    return allLoans().where((l) => l.clientId == clientId).toList();
  }

  // --- Pagos ---
  static List<Payment> allPayments() {
    final List<Payment> list = [];
    for (final raw in _paymentsBox.values) {
      if (raw == null) continue;
      list.add(Payment.fromMap(Map<String, dynamic>.from(raw as Map)));
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
    return list.fold<double>(0.0, (sum, p) => sum + p.amount);
  }

  static Future<void> registerPayment(Payment payment) async {
    await _paymentsBox.put(payment.id, payment.toMap());
    await syncLoanFinancials(payment.loanId);
  }

  static Future<void> deletePayment(String paymentId) async {
    final raw = _paymentsBox.get(paymentId);
    if (raw == null) return;
    final payment = Payment.fromMap(Map<String, dynamic>.from(raw as Map));
    await _paymentsBox.delete(paymentId);
    await syncLoanFinancials(payment.loanId);
  }

  static Future<void> syncLoanFinancials(String loanId) async {
    final rawLoan = _loansBox.get(loanId);
    if (rawLoan == null) return;
    final loan = Loan.fromMap(Map<String, dynamic>.from(rawLoan as Map));
    final loanPayments = paymentsOfLoan(loanId);

    final totalPaid = loanPayments.fold<double>(0.0, (sum, p) => sum + p.amount);
    final totalCovered = loanPayments.fold<int>(0, (sum, p) => sum + p.installmentsCovered);

    final interestRate = loan.interestRate / 100.0;
    final totalCredit = loan.principal * (1.0 + interestRate);
    final newPending = (totalCredit - totalPaid).clamp(0.0, double.infinity);

    final updated = loan.copyWith(
      pendingAmount: newPending,
      paidInstallments: totalCovered,
      status: newPending <= 0.0 ? LoanStatus.completed : LoanStatus.active,
    );
    await _loansBox.put(loan.id, updated.toMap());
  }
}
