enum InterestType { simple, compound, flat }
enum PaymentFrequency { daily, weekly, biweekly, monthly, custom }
enum CalculationMethod { french, german, american, custom }
enum LoanStatus { active, overdue, completed, cancelled }

extension PaymentFrequencyExt on PaymentFrequency {
  int get days {
    switch (this) {
      case PaymentFrequency.daily:
        return 1;
      case PaymentFrequency.weekly:
        return 7;
      case PaymentFrequency.biweekly:
        return 14;
      case PaymentFrequency.monthly:
        return 30;
      case PaymentFrequency.custom:
        return 1;
    }
  }

  String get label {
    switch (this) {
      case PaymentFrequency.daily:
        return 'Diario';
      case PaymentFrequency.weekly:
        return 'Semanal';
      case PaymentFrequency.biweekly:
        return 'Quincenal';
      case PaymentFrequency.monthly:
        return 'Mensual';
      case PaymentFrequency.custom:
        return 'Personalizado';
    }
  }
}

class Loan {
  final String id;
  final String clientId;
  final String collectorId;
  final double principal;
  final double interestRate;
  final InterestType interestType;
  final PaymentFrequency frequency;
  final int installments;
  final DateTime startDate;
  final DateTime dueDate;
  final int graceDays;
  final double penaltyRate;
  final CalculationMethod method;
  final String? notes;
  final double paidAmount;
  final double pendingAmount;
  final int paidInstallments;
  final LoanStatus status;
  final int daysOverdue;
  final DateTime createdAt;
  final DateTime updatedAt;

  Loan({
    required this.id,
    required this.clientId,
    required this.collectorId,
    required this.principal,
    required this.interestRate,
    this.interestType = InterestType.simple,
    this.frequency = PaymentFrequency.weekly,
    required this.installments,
    required this.startDate,
    required this.dueDate,
    this.graceDays = 0,
    this.penaltyRate = 0,
    this.method = CalculationMethod.french,
    this.notes,
    this.paidAmount = 0,
    this.pendingAmount = 0,
    this.paidInstallments = 0,
    this.status = LoanStatus.active,
    this.daysOverdue = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  double get totalInterest => principal * interestRate / 100;
  double get totalToPay => principal + totalInterest;

  double get installmentAmount =>
      installments > 0 ? totalToPay / installments : 0;

  double get progressPercent =>
      totalToPay > 0 ? (paidAmount / totalToPay).clamp(0.0, 1.0) : 0.0;

  double get remainingAmount =>
      (totalToPay - paidAmount).clamp(0.0, double.infinity);

  int get remainingInstallments =>
      (installments - paidInstallments).clamp(0, installments);

  double get baseInstallment {
    if (installments <= 0) return 0;
    return (totalToPay / installments).floorToDouble();
  }

  double get lastInstallment {
    if (installments <= 0) return 0;
    return totalToPay - (baseInstallment * (installments - 1));
  }

  double installmentAmountAt(int n) {
    if (n <= 0 || n > installments) return 0;
    return n == installments ? lastInstallment : baseInstallment;
  }

  List<double> get installmentSchedule =>
      List.generate(installments, (i) => installmentAmountAt(i + 1));

  Loan copyWith({
    String? id,
    String? clientId,
    String? collectorId,
    double? principal,
    double? interestRate,
    InterestType? interestType,
    PaymentFrequency? frequency,
    int? installments,
    DateTime? startDate,
    DateTime? dueDate,
    int? graceDays,
    double? penaltyRate,
    CalculationMethod? method,
    String? notes,
    double? paidAmount,
    double? pendingAmount,
    int? paidInstallments,
    LoanStatus? status,
    int? daysOverdue,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Loan(
        id: id ?? this.id,
        clientId: clientId ?? this.clientId,
        collectorId: collectorId ?? this.collectorId,
        principal: principal ?? this.principal,
        interestRate: interestRate ?? this.interestRate,
        interestType: interestType ?? this.interestType,
        frequency: frequency ?? this.frequency,
        installments: installments ?? this.installments,
        startDate: startDate ?? this.startDate,
        dueDate: dueDate ?? this.dueDate,
        graceDays: graceDays ?? this.graceDays,
        penaltyRate: penaltyRate ?? this.penaltyRate,
        method: method ?? this.method,
        notes: notes ?? this.notes,
        paidAmount: paidAmount ?? this.paidAmount,
        pendingAmount: pendingAmount ?? this.pendingAmount,
        paidInstallments: paidInstallments ?? this.paidInstallments,
        status: status ?? this.status,
        daysOverdue: daysOverdue ?? this.daysOverdue,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    try {
      final dynamic dyn = value;
      if (dyn.toDate != null && dyn.toDate is Function) {
        return dyn.toDate() as DateTime;
      }
    } catch (_) {}
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    return DateTime.now();
  }

  static double _parseDouble(dynamic val, [double def = 0.0]) {
    if (val == null) return def;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? def;
  }

  static int _parseInt(dynamic val, [int def = 0]) {
    if (val == null) return def;
    if (val is num) return val.toInt();
    return int.tryParse(val.toString()) ?? def;
  }

  static LoanStatus _parseStatus(dynamic val) {
    if (val == null) return LoanStatus.active;
    if (val is int) {
      return LoanStatus.values[val.clamp(0, LoanStatus.values.length - 1)];
    }
    final s = val.toString().toLowerCase().trim();
    if (s.contains('overdue') || s.contains('mora')) return LoanStatus.overdue;
    if (s.contains('completed') || s.contains('pagado') || s.contains('finalizado')) {
      return LoanStatus.completed;
    }
    if (s.contains('cancelled') || s.contains('cancelado') || s.contains('anulado')) {
      return LoanStatus.cancelled;
    }
    return LoanStatus.active;
  }

  static InterestType _parseInterestType(dynamic val) {
    if (val == null) return InterestType.simple;
    if (val is int) {
      return InterestType.values[val.clamp(0, InterestType.values.length - 1)];
    }
    final s = val.toString().toLowerCase();
    if (s.contains('compound')) return InterestType.compound;
    if (s.contains('flat')) return InterestType.flat;
    return InterestType.simple;
  }

  static PaymentFrequency _parseFrequency(dynamic val) {
    if (val == null) return PaymentFrequency.weekly;
    if (val is int) {
      return PaymentFrequency.values[val.clamp(0, PaymentFrequency.values.length - 1)];
    }
    final s = val.toString().toLowerCase();
    if (s.contains('daily') || s.contains('diario')) return PaymentFrequency.daily;
    if (s.contains('biweekly') || s.contains('quincenal')) return PaymentFrequency.biweekly;
    if (s.contains('monthly') || s.contains('mensual')) return PaymentFrequency.monthly;
    if (s.contains('custom')) return PaymentFrequency.custom;
    return PaymentFrequency.weekly;
  }

  static CalculationMethod _parseMethod(dynamic val) {
    if (val == null) return CalculationMethod.french;
    if (val is int) {
      return CalculationMethod.values[val.clamp(0, CalculationMethod.values.length - 1)];
    }
    final s = val.toString().toLowerCase();
    if (s.contains('german')) return CalculationMethod.german;
    if (s.contains('american')) return CalculationMethod.american;
    if (s.contains('custom')) return CalculationMethod.custom;
    return CalculationMethod.french;
  }

  factory Loan.fromMap(Map m) => Loan(
        id: m['id']?.toString() ?? '',
        clientId: m['clientId']?.toString() ?? '',
        collectorId: m['collectorId']?.toString() ?? '',
        principal: _parseDouble(m['principal']),
        interestRate: _parseDouble(m['interestRate']),
        interestType: _parseInterestType(m['interestType']),
        frequency: _parseFrequency(m['frequency']),
        installments: _parseInt(m['installments'], 1),
        startDate: _parseDateTime(m['startDate']),
        dueDate: _parseDateTime(m['dueDate']),
        graceDays: _parseInt(m['graceDays'], 0),
        penaltyRate: _parseDouble(m['penaltyRate']),
        method: _parseMethod(m['method']),
        notes: m['notes']?.toString(),
        paidAmount: _parseDouble(m['paidAmount']),
        pendingAmount: _parseDouble(m['pendingAmount']),
        paidInstallments: _parseInt(m['paidInstallments'], 0),
        status: _parseStatus(m['status']),
        daysOverdue: _parseInt(m['daysOverdue'], 0),
        createdAt: _parseDateTime(m['createdAt']),
        updatedAt: _parseDateTime(m['updatedAt']),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'clientId': clientId,
        'collectorId': collectorId,
        'principal': principal,
        'interestRate': interestRate,
        'interestType': interestType.index,
        'frequency': frequency.index,
        'installments': installments,
        'startDate': startDate.millisecondsSinceEpoch,
        'dueDate': dueDate.millisecondsSinceEpoch,
        'graceDays': graceDays,
        'penaltyRate': penaltyRate,
        'method': method.index,
        'notes': notes,
        'paidAmount': paidAmount,
        'pendingAmount': pendingAmount,
        'paidInstallments': paidInstallments,
        'status': status.index,
        'daysOverdue': daysOverdue,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
      };
}
