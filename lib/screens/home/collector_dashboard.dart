import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../models/client_model.dart';
import '../../models/loan_model.dart';
import '../../models/payment_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/clients_provider.dart';
import '../../providers/loans_provider.dart';
import '../../providers/payments_provider.dart';
import '../../services/config_service.dart';
import '../../services/data_service.dart';
import '../../services/receipt_pdf_service.dart';
import '../../services/report_print_service.dart';

class CollectorDashboard extends ConsumerStatefulWidget {
  const CollectorDashboard({super.key});

  @override
  ConsumerState<CollectorDashboard> createState() => _CollectorDashboardState();
}

class _CollectorDashboardState extends ConsumerState<CollectorDashboard> {
  String _searchQuery = '';
  StreamSubscription? _clientsSub;
  StreamSubscription? _loansSub;

  @override
  void initState() {
    super.initState();
    _clientsSub = DataService.clients.watch().listen((_) {
      if (mounted) {
        ref.invalidate(clientsStreamProvider);
        setState(() {});
      }
    });
    _loansSub = DataService.loans.watch().listen((_) {
      if (mounted) {
        ref.invalidate(loansStreamProvider);
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _clientsSub?.cancel();
    _loansSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider) ?? DataService.getCurrentUserSession();

    // Guarda estricta: Si no hay cobrador autenticado, expulsar a login
    if (currentUser == null || currentUser.role != UserRole.collector) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      });
      return const Scaffold(
        backgroundColor: AppColors.bgDark,
        body: Center(child: CircularProgressIndicator(color: AppColors.neonCyan)),
      );
    }

    final clientsList = ref.watch(clientsStreamProvider).value ?? [];
    final loansList = ref.watch(loansStreamProvider).value ?? [];
    final paymentsList = ref.watch(paymentsStreamProvider).value ?? [];
    final company = ConfigService.companyName;

    final collectorFullName = currentUser.name.trim().isNotEmpty
        ? currentUser.name.trim()
        : 'Cobrador Asignado';
    final collectorPhone = currentUser.phone.trim().isNotEmpty
        ? currentUser.phone.trim()
        : 'Sin teléfono';

    // Préstamos activos
    final activeLoans = loansList.where((l) => l.status == LoanStatus.active).toList();

    // Pagos cobrados hoy por este cobrador
    final now = DateTime.now();
    final todayPayments = paymentsList.where((p) {
      return (p.collectorId == currentUser.id || p.collectorId.isEmpty) &&
          p.paidAt.year == now.year &&
          p.paidAt.month == now.month &&
          p.paidAt.day == now.day;
    }).toList();

    final totalTodayCollected = todayPayments.fold<double>(0.0, (sum, p) => sum + p.amount);

    final activeClients = clientsList.where((c) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch = c.name.toLowerCase().contains(q) ||
          c.documentId.contains(q) ||
          c.phone.contains(q);
      final hasActiveLoan = activeLoans.any((l) => l.clientId == c.id);
      return matchesSearch && hasActiveLoan;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(company, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Row(
              children: [
                const Icon(Icons.person, size: 13, color: AppColors.neonCyan),
                const SizedBox(width: 4),
                Text(
                  'Cobrador: $collectorFullName ($collectorPhone)',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print, color: AppColors.neonCyan),
            tooltip: 'Imprimir Arqueo del Día',
            onPressed: () {
              ReportPrintService.printDailyCollection(
                collectorName: collectorFullName,
                collectorPhone: collectorPhone,
                date: DateTime.now(),
                payments: todayPayments,
                clients: clientsList,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.map, color: AppColors.neonCyan),
            tooltip: 'Imprimir Hoja de Ruta',
            onPressed: () {
              ReportPrintService.printDailyRoute(
                collectorName: collectorFullName,
                collectorPhone: collectorPhone,
                clients: activeClients,
                activeLoans: activeLoans,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Cerrar Sesión',
            onPressed: () async {
              await DataService.clearUserSession();
              ref.read(currentUserProvider.notifier).state = null;
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Resumen de caja del día para el cobrador
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.neonCyan.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TOTAL COBRADO HOY',
                          style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        'Bs. ${totalTodayCollected.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF00E676)),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Cobros: ${todayPayments.length}',
                          style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('Clientes en ruta: ${activeClients.length}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
            // Buscador
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Buscar cliente, CI o teléfono...',
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: AppColors.neonCyan, size: 18),
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.surfaceDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
            const SizedBox(height: 8),
            // Lista de clientes y créditos
            Expanded(
              child: activeClients.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline, size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isEmpty ? 'No hay créditos activos en ruta' : 'Sin coincidencias',
                            style: const TextStyle(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: activeClients.length,
                      itemBuilder: (context, index) {
                        final client = activeClients[index];
                        final clientLoans = activeLoans.where((l) => l.clientId == client.id).toList();

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          color: AppColors.surfaceDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.white.withOpacity(0.08)),
                          ),
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.neonCyan.withOpacity(0.15),
                              child: Text(
                                client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
                                style: const TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(
                              client.name,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            subtitle: Text(
                              'CI: ${client.documentId} | Tel: ${client.phone}\nCobrador: $collectorFullName',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                            ),
                            children: clientLoans.map((loan) {
                              final installmentVal = loan.installments > 0
                                  ? (loan.principal / loan.installments)
                                  : 0.0;
                              return Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Pendiente: Bs. ${loan.pendingAmount.toStringAsFixed(2)}',
                                            style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold)),
                                        Text('Cuota ref: Bs. ${installmentVal.toStringAsFixed(2)}',
                                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                      ],
                                    ),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.payment, size: 14),
                                      label: const Text('Cobrar', style: TextStyle(fontSize: 12)),
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonCyan),
                                      onPressed: () {
                                        _showCobroDialog(
                                          context: context,
                                          client: client,
                                          loan: loan,
                                          collectorId: currentUser.id,
                                          collectorFullName: collectorFullName,
                                          collectorPhone: collectorPhone,
                                        );
                                      },
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

  void _showCobroDialog({
    required BuildContext context,
    required Client client,
    required Loan loan,
    required String collectorId,
    required String collectorFullName,
    required String collectorPhone,
  }) {
    final amountCtrl = TextEditingController(
      text: (loan.installments > 0 ? (loan.principal / loan.installments) : 0.0).toStringAsFixed(2),
    );
    PaymentMethod method = PaymentMethod.cash;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDState) {
            return AlertDialog(
              backgroundColor: AppColors.surfaceDark,
              title: Text('Registrar Cobro - ${client.name}', style: const TextStyle(fontSize: 14, color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Cobrador: $collectorFullName ($collectorPhone)',
                      style: const TextStyle(fontSize: 11, color: AppColors.neonCyan)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Monto a Cobrar (Bs.)', isDense: true),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<PaymentMethod>(
                    value: method,
                    dropdownColor: AppColors.surfaceDark,
                    items: PaymentMethod.values.map((m) {
                      return DropdownMenuItem(value: m, child: Text(m.name.toUpperCase(), style: const TextStyle(color: Colors.white)));
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setDState(() => method = v);
                    },
                    decoration: const InputDecoration(labelText: 'Método', isDense: true),
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
                    final entered = double.tryParse(amountCtrl.text) ?? 0.0;
                    if (entered <= 0) return;

                    Navigator.pop(ctx);

                    final paymentId = 'pay_${DateTime.now().millisecondsSinceEpoch}';
                    final interestRate = loan.interestRate / 100.0;
                    final totalCredit = loan.principal * (1.0 + interestRate);
                    final newPending = (loan.pendingAmount - entered).clamp(0.0, double.infinity);
                    final totalAccum = (totalCredit - newPending).clamp(0.0, double.infinity);

                    final payment = Payment(
                      id: paymentId,
                      loanId: loan.id,
                      clientId: client.id,
                      collectorId: collectorId,
                      paidAt: DateTime.now(),
                      amount: entered,
                      installmentsCovered: 1,
                      remainingInstallments: (loan.installments - (loan.paidInstallments + 1)).clamp(0, 9999),
                      capitalPaid: entered,
                      interestPaid: 0.0,
                      pendingAfter: newPending,
                      accumulatedPaid: totalAccum,
                      method: method,
                      synced: true,
                    );

                    await DataService.registerPayment(payment);
                    ref.invalidate(loansStreamProvider);
                    ref.invalidate(paymentsStreamProvider);
                    ref.invalidate(clientsStreamProvider);

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Pago guardado exitosamente en Firestore')),
                      );
                      ReceiptPdfService.printReceipt(
                        payment: payment,
                        loan: loan,
                        client: client,
                        installmentNumber: loan.paidInstallments + 1,
                        installmentAmount: entered,
                      );
                    }
                  },
                  child: const Text('Confirmar Cobro'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
