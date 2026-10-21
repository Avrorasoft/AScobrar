import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../models/client_model.dart';
import '../../models/payment_model.dart';
import '../../providers/clients_provider.dart';
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
  StreamSubscription? _paymentsSub;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _paymentsSub = DataService.payments.watch().listen((_) {
      if (mounted) setState(() {});
    });
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _paymentsSub?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

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
    final Map<String, AppUser> collectorsMap = {for (var u in collectorsList) u.id: u};

    // Consulta unificada a través de allPayments()
    final allPaymentsList = DataService.allPayments();
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

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Reporte Diario de Caja', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Cambiar Fecha',
            icon: const Icon(Icons.calendar_month, color: AppColors.neonCyan),
            onPressed: _pickDate,
          ),
          IconButton(
            tooltip: 'Refrescar Datos',
            icon: const Icon(Icons.refresh, color: AppColors.neonCyan),
            onPressed: () => setState(() {}),
          ),
          IconButton(
            tooltip: 'Imprimir / Exportar Reporte',
            icon: const Icon(Icons.print, color: AppColors.warning),
            onPressed: dayPayments.isEmpty
                ? null
                : () async {
                    await DailyReportPdfService.printDailyReport(
                      date: _selectedDate,
                      payments: dayPayments,
                      clientsMap: clientsMap,
                    );
                  },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selector y Fecha
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event, color: AppColors.neonCyan, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Fecha de Arqueo', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                          Text(dateStr, style: const TextStyle(color: AppColors.textLight, fontSize: 17, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cardDark,
                        foregroundColor: AppColors.neonCyan,
                        side: const BorderSide(color: AppColors.neonCyan),
                      ),
                      onPressed: _pickDate,
                      icon: const Icon(Icons.edit_calendar, size: 16),
                      label: const Text('Elegir'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Tarjetas de Resumen
              Row(
                children: [
                  Expanded(
                    child: _metricBox(
                      title: 'Total Recaudado',
                      value: 'Bs. ${totalRecaudado.toStringAsFixed(2)}',
                      icon: Icons.account_balance_wallet,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _metricBox(
                      title: 'En Efectivo',
                      value: 'Bs. ${totalEfectivo.toStringAsFixed(2)}',
                      icon: Icons.payments,
                      color: AppColors.neonCyan,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _metricBox(
                      title: 'QR / Transf.',
                      value: 'Bs. ${totalTransferencias.toStringAsFixed(2)}',
                      icon: Icons.qr_code,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Rendición por Cobrador
              if (rendicionPorCobrador.isNotEmpty) ...[
                const Text(
                  'Rendición por Cobrador',
                  style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 10),
                ...rendicionPorCobrador.entries.map((entry) {
                  final data = entry.value;
                  return Card(
                    color: AppColors.surfaceDark,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: AppColors.cardBorder),
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.cardDark,
                        child: Icon(Icons.badge, color: AppColors.neonCyan),
                      ),
                      title: Text(data['name'], style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        'Efectivo: Bs. ${(data['efectivo'] as double).toStringAsFixed(2)} • QR: Bs. ${(data['transferencia'] as double).toStringAsFixed(2)}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Bs. ${(data['total'] as double).toStringAsFixed(2)}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('${data['cobrosCount']} cobros', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 20),
              ],

              // Listado Detallado de Pagos
              const Text(
                'Detalle de Pagos Registrados',
                style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 10),

              if (dayPayments.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('No hay cobros registrados para la fecha seleccionada.', style: TextStyle(color: AppColors.textMuted)),
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
                      color: AppColors.cardDark,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: AppColors.cardBorder),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.surfaceDark,
                          child: Icon(
                            isCash ? Icons.money : Icons.qr_code,
                            color: isCash ? AppColors.success : AppColors.warning,
                          ),
                        ),
                        title: Text(clientName, style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          'Hora: $hora • Cobrador: $collectorName • ${isCash ? "Efectivo" : "QR"}',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                        ),
                        trailing: Text(
                          'Bs. ${p.amount.toStringAsFixed(2)}',
                          style: const TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricBox({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(color: AppColors.textLight, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
