import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../models/payment_model.dart';
import '../../providers/clients_provider.dart';
import '../../providers/payments_provider.dart';
import '../../services/config_service.dart';
import '../../services/data_service.dart';
import '../../services/daily_report_pdf_service.dart';

class DailyCollectionReportScreen extends ConsumerStatefulWidget {
  const DailyCollectionReportScreen({super.key});

  @override
  ConsumerState<DailyCollectionReportScreen> createState() =>
      _DailyCollectionReportScreenState();
}

class _DailyCollectionReportScreenState
    extends ConsumerState<DailyCollectionReportScreen> {
  DateTime _selectedDate = DateTime.now();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.neonCyan,
              onPrimary: AppColors.bgDark,
              surface: AppColors.surfaceDark,
              onSurface: AppColors.textLight,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientsList = ref.watch(clientsStreamProvider).value ?? [];
    final clientsMap = {for (var c in clientsList) c.id: c};

    final collectorsList = DataService.allCollectors();
    final Map<String, AppUser> collectorsMap = {
      for (var u in collectorsList) u.id: u
    };

    // Escucha en tiempo real de Firestore
    final paymentsAsync = ref.watch(paymentsStreamProvider);
    final allPaymentsList = paymentsAsync.value ?? DataService.allPayments();

    final List<Payment> dayPayments = allPaymentsList.where((p) {
      return p.paidAt.year == _selectedDate.year &&
          p.paidAt.month == _selectedDate.month &&
          p.paidAt.day == _selectedDate.day;
    }).toList();

    dayPayments.sort((a, b) => b.paidAt.compareTo(a.paidAt));

    double totalRecaudado = 0.0;
    double totalEfectivo = 0.0;
    double totalTransferencias = 0.0;

    final Map<String, Map<String, dynamic>> rendicionPorCobrador = {};

    for (var p in dayPayments) {
      totalRecaudado += p.amount;
      final isCash = p.method == PaymentMethod.cash;
      if (isCash) {
        totalEfectivo += p.amount;
      } else {
        totalTransferencias += p.amount;
      }

      final cId = p.collectorId.isNotEmpty ? p.collectorId : 'sin_asignar';
      if (!rendicionPorCobrador.containsKey(cId)) {
        rendicionPorCobrador[cId] = {
          'name': collectorsMap[cId]?.name ?? (cId == 'sin_asignar' ? 'Sin Asignar' : cId),
          'efectivo': 0.0,
          'transferencia': 0.0,
          'total': 0.0,
          'cobrosCount': 0,
        };
      }

      final stats = rendicionPorCobrador[cId]!;
      stats['total'] = (stats['total'] as double) + p.amount;
      stats['cobrosCount'] = (stats['cobrosCount'] as int) + 1;
      if (isCash) {
        stats['efectivo'] = (stats['efectivo'] as double) + p.amount;
      } else {
        stats['transferencia'] = (stats['transferencia'] as double) + p.amount;
      }
    }

    final dateStr = DateFormat('dd/MM/yyyy').format(_selectedDate);
    final currency = ConfigService.currency;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Reporte Diario de Caja', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surfaceDark,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: AppColors.neonCyan),
            tooltip: 'Imprimir / Descargar PDF',
            onPressed: () async {
              final pdfBytes = await DailyReportPdfService.buildDailyReportPdf(
                date: _selectedDate,
                collectorName: 'General',
                payments: dayPayments,
                clientsMap: clientsMap,
                totalCash: totalEfectivo,
                totalDigital: totalTransferencias,
                totalGeneral: totalRecaudado,
              );
              await Printing.layoutPdf(
                onLayout: (_) => pdfBytes,
                name: 'Reporte_Diario_$dateStr.pdf',
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: AppColors.surfaceDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: AppColors.neonCyan, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'Fecha: $dateStr',
                      style: const TextStyle(color: AppColors.textLight, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.edit_calendar, size: 18),
                      label: const Text('Cambiar'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Total Cobrado',
                    amount: totalRecaudado,
                    currency: currency,
                    color: AppColors.neonCyan,
                    icon: Icons.payments,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Efectivo',
                    amount: totalEfectivo,
                    currency: currency,
                    color: AppColors.success,
                    icon: Icons.attach_money,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Transferencias',
                    amount: totalTransferencias,
                    currency: currency,
                    color: AppColors.warning,
                    icon: Icons.account_balance,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Rendición por Cobrador',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textLight),
            ),
            const SizedBox(height: 12),
            if (rendicionPorCobrador.isEmpty)
              const Card(
                color: AppColors.surfaceDark,
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Text('No hay cobros registrados en esta fecha', style: TextStyle(color: AppColors.textMuted)),
                  ),
                ),
              )
            else
              ...rendicionPorCobrador.entries.map((entry) {
                final data = entry.value;
                return Card(
                  color: AppColors.surfaceDark,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.bgDark,
                      child: Icon(Icons.person, color: AppColors.neonCyan),
                    ),
                    title: Text(
                      data['name'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textLight),
                    ),
                    subtitle: Text(
                      '${data['cobrosCount']} cobros | Efectivo: $currency ${(data['efectivo'] as double).toStringAsFixed(2)} | Transf: $currency ${(data['transferencia'] as double).toStringAsFixed(2)}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                    trailing: Text(
                      '$currency ${(data['total'] as double).toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.neonCyan),
                    ),
                  ),
                );
              }),
            const SizedBox(height: 24),
            Text(
              'Detalle de Cobros del Día (${dayPayments.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textLight),
            ),
            const SizedBox(height: 12),
            if (dayPayments.isEmpty)
              const Card(
                color: AppColors.surfaceDark,
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('No hay movimientos', style: TextStyle(color: AppColors.textMuted)),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: dayPayments.length,
                itemBuilder: (context, index) {
                  final p = dayPayments[index];
                  final clientName = clientsMap[p.clientId]?.name ?? 'Cliente ${p.clientId}';
                  final collectorName = collectorsMap[p.collectorId]?.name ??
                      (p.collectorId.isNotEmpty ? p.collectorId : 'Sin asignar');
                  final hora = DateFormat('HH:mm').format(p.paidAt);
                  final isCash = p.method == PaymentMethod.cash;

                  return Card(
                    color: AppColors.surfaceDark,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        isCash ? Icons.money : Icons.credit_score,
                        color: isCash ? AppColors.success : AppColors.warning,
                      ),
                      title: Text(clientName, style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        'Cobrador: $collectorName  •  Hora: $hora',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                      trailing: Text(
                        '$currency ${p.amount.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.neonCyan),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required String currency,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$currency ${amount.toStringAsFixed(2)}',
            style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
