import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../models/loan_model.dart';
import '../../providers/clients_provider.dart';
import '../../providers/loans_provider.dart';
import '../../services/data_service.dart';
import '../../services/receipt_pdf_service.dart';
import '../payments/new_payment_screen.dart';

class LoanDetailScreen extends ConsumerWidget {
  final String? loanId;
  final Loan? loan;

  const LoanDetailScreen({
    super.key,
    this.loanId,
    this.loan,
  }) : assert(loanId != null || loan != null, 'Debe proveerse loanId o loan');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveLoanId = loanId ?? loan!.id;
    final loanAsync = ref.watch(loanByIdProvider(effectiveLoanId));

    return loanAsync.when(
      data: (fetchedLoan) {
        final currentLoan = fetchedLoan ?? loan;
        if (currentLoan == null) {
          return Scaffold(
            backgroundColor: AppColors.bgDark,
            appBar: AppBar(title: const Text('Detalle de Préstamo')),
            body: const Center(
              child: Text('Préstamo no encontrado', style: TextStyle(color: AppColors.textMuted)),
            ),
          );
        }

        final clientAsync = ref.watch(clientByIdProvider(currentLoan.clientId));
        final payments = DataService.paymentsOfLoan(currentLoan.id);
        final schedule = currentLoan.installmentSchedule;
        final paid = DataService.totalPaidOfLoan(currentLoan.id);
        final pending = (currentLoan.totalToPay - paid).clamp(0.0, double.infinity);

        return Scaffold(
          backgroundColor: AppColors.bgDark,
          appBar: AppBar(
            backgroundColor: AppColors.surfaceDark,
            elevation: 0,
            title: Text(
              'Préstamo #${currentLoan.id.length >= 6 ? currentLoan.id.substring(0, 6).toUpperCase() : currentLoan.id}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textLight),
            ),
            actions: [
              IconButton(
                tooltip: 'Imprimir Historial de Pagos (PDF)',
                icon: const Icon(Icons.picture_as_pdf, color: AppColors.neonCyan),
                onPressed: () {
                  final client = clientAsync.value;
                  ReceiptPdfService.printPaymentHistory(
                    loan: currentLoan,
                    client: client,
                    payments: payments,
                  );
                },
              ),
              IconButton(
                tooltip: 'Enviar Historial por WhatsApp',
                icon: const Icon(Icons.share, color: AppColors.success),
                onPressed: () {
                  final client = clientAsync.value;
                  ReceiptPdfService.sharePaymentHistoryViaWhatsApp(
                    loan: currentLoan,
                    client: client,
                    payments: payments,
                  );
                },
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Cabecera con datos del cliente y préstamo
                Container(
                  padding: const EdgeInsets.all(16.0),
                  color: AppColors.surfaceDark,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      clientAsync.when(
                        data: (client) => Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                client?.name ?? 'Cliente Desconocido',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textLight,
                                ),
                              ),
                            ),
                            if (client != null && client.phone.isNotEmpty)
                              Text(client.phone, style: const TextStyle(color: AppColors.neonCyan)),
                          ],
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => const SizedBox(),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _statItem('Capital', 'Bs. ${currentLoan.principal.round()}'),
                          _statItem('Total a Pagar', 'Bs. ${currentLoan.totalToPay.round()}'),
                          _statItem('Saldo Pendiente', 'Bs. ${pending.round()}', isHighlight: true),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Cuotas pagadas: ${currentLoan.paidInstallments} de ${currentLoan.installments}',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                          ),
                          Text(
                            currentLoan.status == LoanStatus.completed ? 'COMPLETADO' : 'ACTIVO',
                            style: TextStyle(
                              color: currentLoan.status == LoanStatus.completed
                                  ? AppColors.success
                                  : AppColors.neonCyan,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.cardBorder),

                // Lista de Cuotas
                Expanded(
                  child: schedule.isEmpty
                      ? const Center(
                          child: Text('No hay cuotas programadas', style: TextStyle(color: AppColors.textMuted)),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          itemCount: schedule.length,
                          itemBuilder: (context, index) {
                            final number = index + 1;
                            final expected = schedule[index];
                            final isPaid = number <= currentLoan.paidInstallments;

                            final daysPerInstallment = currentLoan.frequency.days > 0
                                ? currentLoan.frequency.days
                                : 1;
                            final installmentDueDate = currentLoan.startDate
                                .add(Duration(days: daysPerInstallment * number));
                            final dueDateStr = DateFormat('dd/MM/yyyy').format(installmentDueDate);

                            return Card(
                              color: AppColors.cardDark,
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: isPaid
                                      ? AppColors.success.withOpacity(0.3)
                                      : AppColors.cardBorder,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Row(
                                  children: [
                                    Icon(
                                      isPaid ? Icons.check_circle : Icons.schedule,
                                      color: isPaid ? AppColors.success : AppColors.warning,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Cuota $number — Bs. ${expected.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              color: AppColors.textLight,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Vence: $dueDateStr  •  ${isPaid ? "PAGADO" : "PENDIENTE"}',
                                            style: TextStyle(
                                              color: isPaid ? AppColors.success : AppColors.textMuted,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Botón Imprimir Cuota individual
                                    IconButton(
                                      tooltip: 'Imprimir / PDF',
                                      icon: const Icon(Icons.print, color: AppColors.neonCyan, size: 20),
                                      onPressed: () {
                                        final client = clientAsync.value;
                                        ReceiptPdfService.printReceipt(
                                          loan: currentLoan,
                                          client: client,
                                          installmentNumber: number,
                                          installmentAmount: expected,
                                          dueDate: installmentDueDate,
                                          isPaid: isPaid,
                                        );
                                      },
                                    ),

                                    // Botón WhatsApp Cuota individual
                                    IconButton(
                                      tooltip: 'Enviar Cuota por WhatsApp',
                                      icon: const Icon(Icons.chat, color: AppColors.success, size: 20),
                                      onPressed: () {
                                        final client = clientAsync.value;
                                        ReceiptPdfService.shareViaWhatsApp(
                                          loan: currentLoan,
                                          client: client,
                                          installmentNumber: number,
                                          installmentAmount: expected,
                                          dueDate: installmentDueDate,
                                          isPaid: isPaid,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Container(
              padding: const EdgeInsets.all(12),
              color: AppColors.surfaceDark,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: pending <= 0
                    ? null
                    : () {
                        final client = clientAsync.value;
                        if (client != null) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => NewPaymentScreen(
                                loan: currentLoan,
                                client: client,
                              ),
                            ),
                          );
                        }
                      },
                icon: const Icon(Icons.payments),
                label: Text(
                  pending <= 0 ? 'Préstamo Completado' : 'Registrar Nuevo Cobro',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: AppColors.bgDark,
        body: Center(child: CircularProgressIndicator(color: AppColors.neonCyan)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.bgDark,
        body: Center(
          child: Text('Error al cargar préstamo: $e', style: const TextStyle(color: AppColors.alarmRed)),
        ),
      ),
    );
  }

  static Widget _statItem(String label, String value, {bool isHighlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: isHighlight ? AppColors.alarmRed : AppColors.textLight,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
