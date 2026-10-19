import '../models/loan_model.dart';

class InterestCalculator {
  static double totalAmount(Loan loan) {
    final r = loan.interestRate / 100;
    final n = loan.installments;
    final C = loan.principal;
    switch (loan.interestType) {
      case InterestType.simple:
        return C + (C * r * n);
      case InterestType.compound:
        return C * _pow(1 + r, n.toDouble());
      case InterestType.flat:
        return C + (C * r * n);
    }
  }

  static double installmentAmount(Loan loan) {
    final r = loan.interestRate / 100;
    final n = loan.installments;
    final C = loan.principal;
    switch (loan.method) {
      case CalculationMethod.french:
        if (r == 0) return C / n;
        return C * r / (1 - _pow(1 + r, -n.toDouble()));
      case CalculationMethod.german:
        return C / n;
      case CalculationMethod.american:
        return C * r;
      case CalculationMethod.custom:
        return totalAmount(loan) / n;
    }
  }

  static double penalty(Loan loan, int daysOverdue) {
    return loan.pendingAmount * (loan.penaltyRate / 100) * daysOverdue;
  }

  static double _pow(double base, double exp) => _exp(exp * _ln(base));

  static double _ln(double x) {
    if (x <= 0) return 0;
    double y = (x - 1) / (x + 1);
    double y2 = y * y;
    double sum = 0, term = y;
    for (int i = 1; i < 20; i += 2) {
      sum += term / i;
      term *= y2;
    }
    return 2 * sum;
  }

  static double _exp(double x) {
    double sum = 1, term = 1;
    for (int i = 1; i < 30; i++) {
      term *= x / i;
      sum += term;
    }
    return sum;
  }
}
