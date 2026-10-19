import 'package:cloud_firestore/cloud_firestore.dart';

class LoanScheduleCalculator {
  LoanScheduleCalculator._();

  /// Calcula la fecha final y los días calendario necesarios para cumplir N cuotas
  static DateTime computeEndDate({
    required DateTime startDate,
    required int totalInstallments,
    required String frequency,
    required bool includeSundays,
  }) {
    if (totalInstallments <= 0) return startDate;
    DateTime current = startDate;

    if (!includeSundays && current.weekday == DateTime.sunday) {
      current = current.add(const Duration(days: 1));
    }

    for (int i = 1; i < totalInstallments; i++) {
      current = _nextDate(current, frequency, includeSundays);
    }
    return current;
  }

  /// Calcula el monto total y la cuota diaria considerando la extensión de tiempo por domingos
  static Map<String, double> computeLoanFinancials({
    required double principal,
    required double baseInterestRatePercent,
    required int installments,
    required String frequency,
    required bool includeSundays,
    required DateTime startDate,
  }) {
    if (principal <= 0 || installments <= 0) {
      return {'total': 0.0, 'interest': 0.0, 'installment': 0.0, 'calendarDays': 0.0};
    }

    if (frequency != 'daily') {
      final interest = principal * (baseInterestRatePercent / 100.0);
      final total = principal + interest;
      return {
        'total': total,
        'interest': interest,
        'installment': total / installments,
        'calendarDays': installments.toDouble(),
      };
    }

    // Para cobros diarios:
    final endDate = computeEndDate(
      startDate: startDate,
      totalInstallments: installments,
      frequency: frequency,
      includeSundays: includeSundays,
    );

    // Duración real en días calendario
    final int calendarDays = endDate.difference(startDate).inDays + 1;

    // Tasa diaria equivalente calculada sobre base mensual de 30 días
    final double dailyRate = (baseInterestRatePercent / 100.0) / 30.0;
    
    // Al extenderse en el tiempo por los domingos, el interés financiado cubre los días calendario totales
    final double totalInterest = principal * (dailyRate * calendarDays);
    final double totalToPay = principal + totalInterest;
    final double installmentAmount = totalToPay / installments;

    return {
      'total': totalToPay,
      'interest': totalInterest,
      'installment': installmentAmount,
      'calendarDays': calendarDays.toDouble(),
    };
  }

  /// Genera el cronograma extendido en el calendario
  static List<Map<String, dynamic>> generateSchedule({
    required double principal,
    required double interestRatePercent,
    required int totalInstallments,
    required String frequency,
    required bool includeSundays,
    required DateTime startDate,
  }) {
    final financials = computeLoanFinancials(
      principal: principal,
      baseInterestRatePercent: interestRatePercent,
      installments: totalInstallments,
      frequency: frequency,
      includeSundays: includeSundays,
      startDate: startDate,
    );

    final double totalDebt = financials['total'] ?? (principal * (1 + interestRatePercent / 100.0));
    final int totalDebtCents = (totalDebt * 100).round();
    final int principalCents = (principal * 100).round();

    final int baseInstallmentCents = totalDebtCents ~/ totalInstallments;
    final int remainderInstallmentCents = totalDebtCents % totalInstallments;

    final int baseCapitalCents = principalCents ~/ totalInstallments;
    final int remainderCapitalCents = principalCents % totalInstallments;

    final List<Map<String, dynamic>> installments = [];
    DateTime currentDate = startDate;

    if (!includeSundays && currentDate.weekday == DateTime.sunday) {
      currentDate = currentDate.add(const Duration(days: 1));
    }

    for (int i = 1; i <= totalInstallments; i++) {
      if (i > 1) {
        currentDate = _nextDate(currentDate, frequency, includeSundays);
      }

      final bool isLast = (i == totalInstallments);
      final int installmentAmountCents =
          isLast ? (baseInstallmentCents + remainderInstallmentCents) : baseInstallmentCents;
      final int capitalAmountCents =
          isLast ? (baseCapitalCents + remainderCapitalCents) : baseCapitalCents;
      final int interestAmountCents = installmentAmountCents - capitalAmountCents;

      installments.add({
        'number': i,
        'dueDate': Timestamp.fromDate(currentDate),
        'expectedAmount': installmentAmountCents / 100.0,
        'capitalAmount': capitalAmountCents / 100.0,
        'interestAmount': interestAmountCents / 100.0,
        'paidAmount': 0.0,
        'status': 'pending',
      });
    }

    return installments;
  }

  static DateTime _nextDate(DateTime currentDate, String frequency, bool includeSundays) {
    DateTime date = currentDate;
    switch (frequency) {
      case 'daily':
        date = date.add(const Duration(days: 1));
        while (!includeSundays && date.weekday == DateTime.sunday) {
          date = date.add(const Duration(days: 1));
        }
        break;
      case 'weekly':
        date = date.add(const Duration(days: 7));
        break;
      case 'biweekly':
        date = date.add(const Duration(days: 14));
        break;
      case 'monthly':
        date = DateTime(date.year, date.month + 1, date.day);
        break;
      default:
        date = date.add(const Duration(days: 1));
    }
    return date;
  }
}
