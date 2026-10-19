class LoanSummary {
  final double principal;
  final double totalToPay;
  final double totalPaid;
  final double remaining;
  final int totalInstallments;
  final int paidInstallments;
  final int remainingInstallments;
  final double nextInstallmentAmount;
  final DateTime? nextDueDate;
  final int daysOverdue;

  LoanSummary({
    required this.principal,
    required this.totalToPay,
    required this.totalPaid,
    required this.remaining,
    required this.totalInstallments,
    required this.paidInstallments,
    required this.remainingInstallments,
    required this.nextInstallmentAmount,
    this.nextDueDate,
    this.daysOverdue = 0,
  });

  double get progress => totalToPay == 0 ? 0 : totalPaid / totalToPay;
  bool get isPaid => remaining <= 0.01;
  bool get isOverdue => daysOverdue > 0;
}

class LoanCalculator {
  LoanCalculator._();

  /// Calcula la cuota fija usando método francés:
  /// Cuota = P * i / (1 - (1+i)^-n)
  static double fixedInstallment({
    required double principal,
    required double periodicRate, // ej. 0.05 = 5%
    required int installments,
  }) {
    if (periodicRate <= 0) return principal / installments;
    final i = periodicRate;
    final n = installments;
    return principal * i / (1 - _pow(1 + i, -n));
  }

  /// Interés total del préstamo
  static double totalInterest({
    required double principal,
    required double installmentAmount,
    required int installments,
  }) =>
      (installmentAmount * installments) - principal;

  /// Cuántas cuotas cubre un monto dado
  static int installmentsCovered({
    required double amount,
    required double installmentAmount,
  }) {
    if (installmentAmount <= 0) return 0;
    return (amount / installmentAmount).floor();
  }

  /// Fecha de la próxima cuota pendiente
  static DateTime nextDueDate({
    required DateTime startDate,
    required int frequencyDays,
    required int paidInstallments,
  }) =>
      startDate.add(Duration(days: frequencyDays * paidInstallments));

  /// Días de atraso desde la última cuota impaga
  static int daysOverdue({
    required DateTime startDate,
    required int frequencyDays,
    required int paidInstallments,
  }) {
    final due = nextDueDate(
      startDate: startDate,
      frequencyDays: frequencyDays,
      paidInstallments: paidInstallments,
    );
    final diff = DateTime.now().difference(due).inDays;
    return diff > 0 ? diff : 0;
  }

  static double _pow(double base, int exp) {
    double result = 1;
    if (exp >= 0) {
      for (var i = 0; i < exp; i++) {
        result *= base;
      }
    } else {
      for (var i = 0; i < -exp; i++) {
        result /= base;
      }
    }
    return result;
  }
}