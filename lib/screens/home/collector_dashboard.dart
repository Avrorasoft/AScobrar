import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../models/client_model.dart';
import '../../models/loan_model.dart';
import '../../models/payment_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/clients_provider.dart';
import '../../providers/loans_provider.dart';
import '../../services/config_service.dart';
import '../../services/data_service.dart';
import '../../services/receipt_pdf_service.dart';

class CollectorDashboard extends ConsumerStatefulWidget {
  const CollectorDashboard({super.key});

  @override
  ConsumerState<CollectorDashboard> createState() => _CollectorDashboardState();
}

class _CollectorDashboardState extends ConsumerState<CollectorDashboard> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final clientsList = ref.watch(clientsStreamProvider).value ?? [];
    final loansList = ref.watch(loansStreamProvider).value ?? [];
    final company = ConfigService.companyName;

    // Nombre y Apellido real del cobrador logueado
    final collectorFullName = (currentUser != null && currentUser.name.trim().isNotEmpty && !RegExp(r'^\d+$').hasMatch(currentUser.name.trim()))
        ? currentUser.name.trim()
        : 'Juan Carlos Pérez';
    final collectorPhone = currentUser?.phone ?? '70000002';

    // Filtrar préstamos activos
    final activeLoans = loansList.where((l) => l.status == LoanStatus.active).toList();
    final activeClients = clientsList.where((c) {
      final q = _searchQuery.toLowerCase();
      return c.name.toLowerCase().contains(q) ||
          c.documentId.contains(q) ||
          c.phone.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(company, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(
              'Cobrador: $collectorFullName',
              style: const TextStyle(fontSize: 12, color: AppColors.neonCyan),
            ),
          ],
        ),
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Cerrar Sesión',
            onPressed: () {
              ref.read(currentUserProvider.notifier).state = null;
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                style: const TextStyle(color: AppColors.textLight),
                decoration: InputDecoration(
                  hintText: 'Buscar cliente por nombre o CI...',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.search, color: AppColors.neonCyan),
                  filled: true,
                  fillColor: AppColors.surfaceDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),
            Expanded(
              child: activeClients.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay clientes registrados en esta ruta',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: activeClients.length,
                      itemBuilder: (context, index) {
                        final client = activeClients[index];
                        final clientLoans =
                            activeLoans.where((l) => l.clientId == client.id).toList();

                        return Card(
                          color: AppColors.surfaceDark,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: AppColors.textMuted.withOpacity(0.15)),
                          ),
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primaryMid.withOpacity(0.2),
                              child: Text(
                                client.name.isNotEmpty ? client.name[0].toUpperCase() : 'C',
                                style: const TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(
                              client.name,
                              style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'CI: ${client.documentId} • Tel: ${client.phone}',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                            children: clientLoans.isEmpty
                                ? [
                                    const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: Text(
                                        'Sin préstamos activos',
                                        style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                                      ),
                                    )
                                  ]
                                : clientLoans.map((loan) {
                                    final installmentVal = loan.principal / loan.installments;
                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.bgDark,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Saldo: Bs. ${loan.pendingAmount.round()}',
                                                style: const TextStyle(
                                                    color: AppColors.neonCyan, fontWeight: FontWeight.bold),
                                              ),
                                              Text(
                                                'Cuota: Bs. ${installmentVal.round()}',
                                                style: const TextStyle(
                                                    color: AppColors.success, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: AppColors.success,
                                                    foregroundColor: AppColors.bgDark,
                                                  ),
                                                  icon: const Icon(Icons.check_circle_outline, size: 18),
                                                  label: const Text('COBRAR CUOTA', style: TextStyle(fontWeight: FontWeight.bold)),
                                                  onPressed: () => _realizarCobro(
                                                    context: context,
                                                    loan: loan,
                                                    client: client,
                                                    collectorId: currentUser?.id ?? loan.collectorId,
                                                    collectorFullName: collectorFullName,
                                                    collectorPhone: collectorPhone,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _realizarCobro({
    required BuildContext context,
    required Loan loan,
    required Client client,
    required String collectorId,
    required String collectorFullName,
    required String collectorPhone,
  }) async {
    final installmentVal = loan.principal / loan.installments;
    final amountController = TextEditingController(text: installmentVal.round().toString());
    PaymentMethod selectedMethod = PaymentMethod.cash;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          title: Text(
            'Cobrar a ${client.name}',
            style: const TextStyle(color: AppColors.textLight, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cobrador: $collectorFullName',
                  style: const TextStyle(color: AppColors.neonCyan, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.textLight),
                decoration: const InputDecoration(
                  labelText: 'Monto a Cobrar (Bs.)',
                  labelStyle: TextStyle(color: AppColors.neonCyan),
                  filled: true,
                  fillColor: AppColors.bgDark,
                ),
              ),
              const SizedBox(height: 12),
              const Text('Forma de Pago:', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              Row(
                children: [
                  Radio<PaymentMethod>(
                    value: PaymentMethod.cash,
                    groupValue: selectedMethod,
                    onChanged: (val) => setDialogState(() => selectedMethod = val!),
                  ),
                  const Text('Efectivo', style: TextStyle(color: AppColors.textLight)),
                  const SizedBox(width: 8),
                  Radio<PaymentMethod>(
                    value: PaymentMethod.transfer,
                    groupValue: selectedMethod,
                    onChanged: (val) => setDialogState(() => selectedMethod = val!),
                  ),
                  const Text('QR / Transf.', style: TextStyle(color: AppColors.textLight)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonCyan),
              onPressed: () async {
                final double? parsedAmount = double.tryParse(amountController.text.trim());
                if (parsedAmount == null || parsedAmount <= 0) return;

                Navigator.pop(ctx);

                // Cálculo financiero de cuota
                final interestRate = loan.interestRate / 100.0;
                final totalCredit = loan.principal * (1.0 + interestRate);
                final interestPortion = totalCredit > 0 ? (loan.principal * interestRate) / totalCredit : 0.0;
                final interestPaid = parsedAmount * interestPortion;
                final capitalPaid = parsedAmount - interestPaid;
                final pendingAfter = (loan.pendingAmount - parsedAmount).clamp(0.0, double.infinity);
                final accumulatedPaid = ((totalCredit - loan.pendingAmount) + parsedAmount).clamp(0.0, totalCredit);
                final remainingInstallments = (loan.installments - (loan.paidInstallments + 1)).clamp(0, loan.installments);

                final payment = Payment(
                  id: 'PAY-${DateTime.now().millisecondsSinceEpoch}',
                  loanId: loan.id,
                  clientId: client.id,
                  collectorId: collectorId,
                  paidAt: DateTime.now(),
                  amount: parsedAmount,
                  installmentsCovered: 1,
                  remainingInstallments: remainingInstallments,
                  capitalPaid: capitalPaid,
                  interestPaid: interestPaid,
                  pendingAfter: pendingAfter,
                  accumulatedPaid: accumulatedPaid,
                  method: selectedMethod,
                );

                await DataService.registerPayment(payment);

                if (!context.mounted) return;

                showDialog(
                  context: context,
                  builder: (rCtx) => AlertDialog(
                    backgroundColor: AppColors.surfaceDark,
                    title: const Text('¡Cobro Exitoso!', style: TextStyle(color: AppColors.success)),
                    content: Text(
                      'Se registraron Bs. ${parsedAmount.round()} cobrados por $collectorFullName.',
                      style: const TextStyle(color: AppColors.textLight),
                    ),
                    actions: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonCyan),
                        icon: const Icon(Icons.print, size: 18),
                        label: const Text('Imprimir Recibo'),
                        onPressed: () {
                          ReceiptPdfService.printReceipt(
                            payment: payment,
                            loan: loan,
                            client: client,
                            installmentNumber: loan.paidInstallments + 1,
                            installmentAmount: parsedAmount,
                            collectorName: collectorFullName,
                            collectorPhone: collectorPhone,
                          );
                        },
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text('WhatsApp'),
                        onPressed: () {
                          ReceiptPdfService.shareViaWhatsApp(
                            payment: payment,
                            loan: loan,
                            client: client,
                            installmentNumber: loan.paidInstallments + 1,
                            installmentAmount: parsedAmount,
                            collectorName: collectorFullName,
                            collectorPhone: collectorPhone,
                          );
                        },
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(rCtx),
                        child: const Text('Cerrar', style: TextStyle(color: AppColors.textMuted)),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Confirmar Cobro', style: TextStyle(color: AppColors.bgDark, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
