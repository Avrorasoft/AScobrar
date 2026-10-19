import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/alarm_model.dart';
import '../models/loan_model.dart';
import '../services/data_service.dart';
import '../services/loan_calculator.dart';
import 'loans_provider.dart';

/// Provider reactivo de alarmas de mora que se actualiza automáticamente al cambiar los préstamos
final alarmsProvider = Provider<List<Alarm>>((ref) {
  // Observa el stream reactivo de préstamos para recalcularse ante cualquier alta, baja o reseteo
  final loansAsync = ref.watch(loansStreamProvider);
  final loans = loansAsync.value ?? DataService.allLoans();

  final alarms = <Alarm>[];

  for (final loan in loans) {
    if (loan.status == LoanStatus.completed ||
        loan.status == LoanStatus.cancelled) {
      continue;
    }

    final client = DataService.getClient(loan.clientId);
    if (client == null) continue;

    final totalPaid = DataService.totalPaidOfLoan(loan.id);
    final daysOverdue = LoanCalculator.daysOverdue(
      startDate: loan.startDate,
      frequencyDays: loan.frequency.days,
      paidInstallments: loan.paidInstallments,
    );

    if (daysOverdue <= 0) continue;

    final overdueAmount =
        (loan.totalToPay - totalPaid).clamp(0.0, double.infinity);

    if (overdueAmount <= 0) continue;

    final severity = daysOverdue >= 8
        ? AlarmSeverity.red
        : daysOverdue >= 4
            ? AlarmSeverity.orange
            : AlarmSeverity.yellow;

    alarms.add(Alarm(
      id: loan.id,
      loanId: loan.id,
      clientId: client.id,
      collectorId: loan.collectorId,
      severity: severity,
      daysOverdue: daysOverdue,
      overdueAmount: overdueAmount,
      detectedAt: DateTime.now(),
      clientName: client.name,
      phone: client.phone,
      address: client.fullAddress,
    ));
  }

  return alarms;
});
