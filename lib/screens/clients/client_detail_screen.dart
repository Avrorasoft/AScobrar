import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../models/client_model.dart';
import '../../models/loan_model.dart';
import '../../models/payment_model.dart';
import '../../services/admin_security_service.dart';
import '../../services/data_service.dart';
import '../../services/receipt_pdf_service.dart';
import '../loans/loan_detail_screen.dart';
import '../loans/new_loan_screen.dart';
import '../payments/new_payment_screen.dart';
import 'new_client_screen.dart';

class ClientDetailScreen extends StatefulWidget {
  final Client client;

  const ClientDetailScreen({super.key, required this.client});

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  late Client _currentClient;

  @override
  void initState() {
    super.initState();
    _currentClient = widget.client;
  }

  void _reloadClient() {
    final updated = DataService.getClient(_currentClient.id);
    if (updated != null && mounted) {
      setState(() => _currentClient = updated);
    }
  }

  Future<void> _deleteClientWithSuperAdmin() async {
    final authorized = await AdminSecurityService.requestSuperAdminAuth(
      context: context,
      actionTitle: 'Eliminar Cliente y Créditos',
      actionWarning:
          'Se eliminará a "${_currentClient.name}" junto con todo su historial de préstamos y cobros. Esta acción requiere contraseña de SuperAdmin.',
    );

    if (!authorized) return;

    await AdminSecurityService.deleteClientCascade(_currentClient.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cliente ${_currentClient.name} eliminado permanentemente.'),
        backgroundColor: AppColors.success,
      ),
    );
    Navigator.pop(context, true);
  }

  Future<void> _deleteLoanWithSuperAdmin(Loan loan) async {
    final authorized = await AdminSecurityService.requestSuperAdminAuth(
      context: context,
      actionTitle: 'Eliminar Préstamo',
      actionWarning:
          'Se eliminará el préstamo de Bs. ${loan.principal.round()} y todos sus pagos asociados. Requiere contraseña de SuperAdmin.',
    );

    if (!authorized) return;

    await AdminSecurityService.deleteLoanCascade(loan.id);
    _reloadClient();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Préstamo eliminado correctamente.'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _deletePaymentWithSuperAdmin(Payment p) async {
    final authorized = await AdminSecurityService.requestSuperAdminAuth(
      context: context,
      actionTitle: 'Anular y Eliminar Pago',
      actionWarning:
          'Se eliminará el cobro de Bs. ${p.amount.round()} y el saldo volverá a sumarse a la deuda del préstamo. Requiere contraseña de SuperAdmin.',
    );

    if (!authorized) return;

    await DataService.deletePayment(p.id);
    _reloadClient();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pago eliminado y saldo actualizado.'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Widget _row(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 135,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textLight,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = _currentClient;
    final loans = DataService.loansOfClient(c.id);
    final payments = DataService.paymentsOfClient(c.id);
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: Text(
          c.name,
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textLight),
        ),
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Editar Cliente',
            icon: const Icon(Icons.edit, color: AppColors.neonCyan),
            onPressed: () async {
              final changed = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NewClientScreen(clientToEdit: c),
                ),
              );
              if (changed == true) _reloadClient();
            },
          ),
          IconButton(
            tooltip: 'Eliminar Cliente (Requiere SuperAdmin)',
            icon: const Icon(Icons.delete_forever, color: AppColors.alarmRed),
            onPressed: _deleteClientWithSuperAdmin,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.neonCyan,
        foregroundColor: AppColors.bgDark,
        icon: const Icon(Icons.add_card),
        label: const Text('Nuevo Préstamo', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NewLoanScreen(preselectedClientId: c.id),
            ),
          );
          _reloadClient();
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: AppColors.surfaceDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: AppColors.neonCyan.withOpacity(0.25)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'INFORMACIÓN DE CONTACTO Y EXPEDIENTE',
                      style: TextStyle(
                        color: AppColors.neonCyan,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const Divider(color: Colors.white12, height: 20),
                    _row('🆔 C.I. / Documento:', c.documentId),
                    _row('📱 Teléfono Principal:', c.phone),
                    if (c.phoneSecondary.isNotEmpty)
                      _row('📞 Tel. Secundario:', c.phoneSecondary),
                    _row('🏠 Dirección / Calle:', c.street.isNotEmpty ? c.street : c.address),
                    if (c.neighborhood.isNotEmpty)
                      _row('📍 Barrio / Zona:', c.neighborhood),
                    if (c.reference.isNotEmpty)
                      _row('🧭 Referencia:', c.reference),
                    if (c.business.isNotEmpty)
                      _row('🏪 Negocio / Rubro:', c.business),
                    if (c.guarantorName.isNotEmpty) ...[
                      const Divider(color: Colors.white12, height: 20),
                      _row('🤝 Garante:', c.guarantorName),
                      _row('📲 Tel. Garante:', c.guarantorPhone),
                      _row('🪪 C.I. Garante:', c.guarantorDocumentId),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'PRÉSTAMOS REGISTRADOS (${loans.length})',
              style: const TextStyle(
                color: AppColors.neonCyan,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            if (loans.isEmpty)
              const Card(
                color: AppColors.surfaceDark,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Este cliente no tiene préstamos registrados.',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              )
            else
              ...loans.map((loan) {
                final paid = DataService.totalPaidOfLoan(loan.id);
                final installmentAmount = loan.installments > 0
                    ? (loan.principal * (1 + loan.interestRate / 100)) / loan.installments
                    : 0.0;

                return Card(
                  color: AppColors.surfaceDark,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppColors.textMuted.withOpacity(0.15)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Capital: Bs. ${loan.principal.round()} (${loan.interestRate.round()}%)',
                              style: const TextStyle(
                                color: AppColors.textLight,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Eliminar Préstamo (Requiere SuperAdmin)',
                              icon: const Icon(Icons.delete_outline, color: AppColors.alarmRed, size: 20),
                              onPressed: () => _deleteLoanWithSuperAdmin(loan),
                            ),
                          ],
                        ),
                        Text(
                          'Pagado: Bs. ${paid.round()} • Saldo Pendiente: Bs. ${loan.pendingAmount.round()}',
                          style: const TextStyle(color: AppColors.neonCyan, fontSize: 13),
                        ),
                        Text(
                          'Cuotas: ${loan.paidInstallments}/${loan.installments} (Bs. ${installmentAmount.round()} c/u)',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.neonCyan,
                                  side: const BorderSide(color: AppColors.neonCyan),
                                ),
                                icon: const Icon(Icons.visibility, size: 17),
                                label: const Text('Ver Kardex'),
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => LoanDetailScreen(loan: loan),
                                    ),
                                  );
                                  _reloadClient();
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            if (loan.pendingAmount > 0)
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                    foregroundColor: AppColors.bgDark,
                                  ),
                                  icon: const Icon(Icons.payments, size: 17),
                                  label: const Text(
                                    'Cobrar',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => NewPaymentScreen(loan: loan, client: c),
                                      ),
                                    );
                                    _reloadClient();
                                  },
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 20),
            Text(
              'HISTORIAL DE COBROS (${payments.length})',
              style: const TextStyle(
                color: AppColors.neonCyan,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            if (payments.isEmpty)
              const Text(
                'Sin pagos registrados hasta la fecha.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              )
            else
              ...payments.map((p) {
                final loan = DataService.getLoan(p.loanId);
                return Card(
                  color: AppColors.surfaceDark,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.receipt_long, color: AppColors.success),
                    title: Text(
                      'Bs. ${p.amount.round()} • ${dateFmt.format(p.paidAt)}',
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      'Saldo restante: Bs. ${p.pendingAfter.round()}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (loan != null)
                          IconButton(
                            tooltip: 'Imprimir Recibo',
                            icon: const Icon(Icons.print, color: AppColors.neonCyan, size: 20),
                            onPressed: () {
                              ReceiptPdfService.printReceipt(
                                payment: p,
                                loan: loan,
                                client: c,
                                installmentNumber: loan.paidInstallments,
                                installmentAmount: p.amount,
                              );
                            },
                          ),
                        IconButton(
                          tooltip: 'Eliminar Pago (Requiere SuperAdmin)',
                          icon: const Icon(Icons.delete_outline, color: AppColors.alarmRed, size: 20),
                          onPressed: () => _deletePaymentWithSuperAdmin(p),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 70),
          ],
        ),
      ),
    );
  }
}
