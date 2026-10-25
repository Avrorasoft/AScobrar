import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../models/client_model.dart';
import '../../models/payment_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/clients_provider.dart';
import '../../providers/payments_provider.dart';
import '../../services/report_print_service.dart';
import '../../widgets/pdf_preview_screen.dart';

enum ReportPeriod { daily, weekly, monthly, yearly }

class DailyCollectionReportScreen extends ConsumerStatefulWidget {
  const DailyCollectionReportScreen({super.key});

  @override
  ConsumerState<DailyCollectionReportScreen> createState() => _DailyCollectionReportScreenState();
}

class _DailyCollectionReportScreenState extends ConsumerState<DailyCollectionReportScreen> {
  ReportPeriod _period = ReportPeriod.daily;
  DateTime _referenceDate = DateTime.now();
  String _selectedCollectorId = 'all'; // 'all' = General, o ID específico de cobrador

  DateTime _startOfWeek(DateTime date) {
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: date.weekday - 1));
  }

  DateTime _endOfWeek(DateTime date) {
    return _startOfWeek(date).add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
  }

  bool _isPaymentInPeriod(Payment p) {
    switch (_period) {
      case ReportPeriod.daily:
        return p.paidAt.year == _referenceDate.year &&
            p.paidAt.month == _referenceDate.month &&
            p.paidAt.day == _referenceDate.day;
      case ReportPeriod.weekly:
        final start = _startOfWeek(_referenceDate);
        final end = _endOfWeek(_referenceDate);
        return p.paidAt.isAfter(start.subtract(const Duration(seconds: 1))) &&
            p.paidAt.isBefore(end.add(const Duration(seconds: 1)));
      case ReportPeriod.monthly:
        return p.paidAt.year == _referenceDate.year &&
            p.paidAt.month == _referenceDate.month;
      case ReportPeriod.yearly:
        return p.paidAt.year == _referenceDate.year;
    }
  }

  String _getPeriodLabel() {
    const dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    const meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    switch (_period) {
      case ReportPeriod.daily:
        final dia = dias[_referenceDate.weekday - 1];
        final mes = meses[_referenceDate.month - 1];
        return '$dia ${_referenceDate.day} de $mes, ${_referenceDate.year}';
      case ReportPeriod.weekly:
        final start = _startOfWeek(_referenceDate);
        final end = _endOfWeek(_referenceDate);
        final mesStart = meses[start.month - 1];
        final mesEnd = meses[end.month - 1];
        return 'Semana: ${start.day} de $mesStart - ${end.day} de $mesEnd, ${end.year}';
      case ReportPeriod.monthly:
        final mes = meses[_referenceDate.month - 1].toUpperCase();
        return 'Mes: $mes ${_referenceDate.year}';
      case ReportPeriod.yearly:
        return 'Año: ${_referenceDate.year}';
    }
  }

  void _navigatePeriod(int delta) {
    setState(() {
      switch (_period) {
        case ReportPeriod.daily:
          _referenceDate = _referenceDate.add(Duration(days: delta));
          break;
        case ReportPeriod.weekly:
          _referenceDate = _referenceDate.add(Duration(days: delta * 7));
          break;
        case ReportPeriod.monthly:
          _referenceDate = DateTime(_referenceDate.year, _referenceDate.month + delta, 1);
          break;
        case ReportPeriod.yearly:
          _referenceDate = DateTime(_referenceDate.year + delta, 1, 1);
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(paymentsStreamProvider);
    final clientsAsync = ref.watch(clientsStreamProvider);
    final usersAsync = ref.watch(allUsersStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Módulo de Reportes de Cobranza', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: paymentsAsync.when(
        data: (allPayments) {
          final allClients = clientsAsync.value ?? [];
          final allUsers = usersAsync.value ?? [];

          final collectorsList = allUsers.where((u) => u.role == UserRole.collector).toList();
          final Map<String, Client> clientsMap = {for (var c in allClients) c.id: c};
          final Map<String, AppUser> collectorsMap = {for (var u in allUsers) u.id: u};

          // 1. Filtrar por período de tiempo
          var filteredPayments = allPayments.where(_isPaymentInPeriod).toList();

          // 2. Filtrar por Cobrador (General vs Individual)
          if (_selectedCollectorId != 'all') {
            filteredPayments = filteredPayments.where((p) => p.collectorId == _selectedCollectorId).toList();
          }

          final totalRecaudado = filteredPayments.fold<double>(0.0, (sum, p) => sum + p.amount);
          final totalEfectivo = filteredPayments
              .where((p) => p.method == PaymentMethod.cash)
              .fold<double>(0.0, (sum, p) => sum + p.amount);
          final totalTransferencia = filteredPayments
              .where((p) => p.method != PaymentMethod.cash)
              .fold<double>(0.0, (sum, p) => sum + p.amount);

          // Rendición por cobrador
          final Map<String, Map<String, dynamic>> rendicionPorCobrador = {};
          for (var p in filteredPayments) {
            final cId = p.collectorId.isNotEmpty ? p.collectorId : 'sin_asignar';
            if (!rendicionPorCobrador.containsKey(cId)) {
              final resolvedName = collectorsMap[cId]?.name ??
                  (cId == 'sin_asignar' ? 'Administración' : cId);
              rendicionPorCobrador[cId] = {
                'name': resolvedName,
                'efectivo': 0.0,
                'transferencia': 0.0,
                'total': 0.0,
                'cobrosCount': 0,
              };
            }
            final stats = rendicionPorCobrador[cId]!;
            stats['total'] = (stats['total'] as double) + p.amount;
            stats['cobrosCount'] = (stats['cobrosCount'] as int) + 1;
            if (p.method == PaymentMethod.cash) {
              stats['efectivo'] = (stats['efectivo'] as double) + p.amount;
            } else {
              stats['transferencia'] = (stats['transferencia'] as double) + p.amount;
            }
          }

          final currentScopeTitle = _selectedCollectorId == 'all'
              ? 'TODOS LOS COBRADORES (CONSOLIDADO GENERAL)'
              : 'COBRADOR: ${collectorsMap[_selectedCollectorId]?.name.toUpperCase() ?? _selectedCollectorId}';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Barra de selección de Período (Diario, Semanal, Mensual, Anual)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    _periodButton('Diario', ReportPeriod.daily),
                    _periodButton('Semanal', ReportPeriod.weekly),
                    _periodButton('Mensual', ReportPeriod.monthly),
                    _periodButton('Anual', ReportPeriod.yearly),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Barra de Filtro de Cobrador (General o Individual)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.neonCyan.withOpacity(0.3)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCollectorId,
                    dropdownColor: AppColors.surfaceDark,
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    items: [
                      const DropdownMenuItem(
                        value: 'all',
                        child: Row(
                          children: [
                            Icon(Icons.people, color: AppColors.neonCyan, size: 18),
                            SizedBox(width: 8),
                            Text('TODOS LOS COBRADORES (REPORTE GENERAL)'),
                          ],
                        ),
                      ),
                      ...collectorsList.map((col) {
                        return DropdownMenuItem(
                          value: col.id,
                          child: Row(
                            children: [
                              const Icon(Icons.person, color: Colors.greenAccent, size: 18),
                              SizedBox(width: 8),
                              Text('COBRADOR: ${col.name}'),
                            ],
                          ),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCollectorId = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Controles de fecha y botón imprimir
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, color: AppColors.neonCyan),
                        onPressed: () => _navigatePeriod(-1),
                      ),
                      Text(
                        _getPeriodLabel(),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, color: AppColors.neonCyan),
                        onPressed: () => _navigatePeriod(1),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonCyan),
                    icon: const Icon(Icons.print, size: 16),
                    label: const Text('Imprimir Reporte'),
                    onPressed: () {
                      final periodName = switch (_period) {
                        ReportPeriod.daily => 'DIARIO',
                        ReportPeriod.weekly => 'SEMANAL',
                        ReportPeriod.monthly => 'MENSUAL',
                        ReportPeriod.yearly => 'ANUAL',
                      };
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(
                          builder: (ctx) => PdfPreviewScreen(
                            title: 'Reporte Financiero - $periodName',
                            buildPdf: (format) => ReportPrintService.buildFinancialReportPdf(
                              periodTitle: periodName,
                              periodRangeText: _getPeriodLabel(),
                              targetScopeTitle: currentScopeTitle,
                              payments: filteredPayments,
                              clients: allClients,
                              collectorsMap: collectorsMap,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Resumen financiero
              Row(
                children: [
                  _statCard('TOTAL RECAUDADO', 'Bs. ${totalRecaudado.toStringAsFixed(2)}', const Color(0xFF00E676)),
                  const SizedBox(width: 8),
                  _statCard('EFECTIVO', 'Bs. ${totalEfectivo.toStringAsFixed(2)}', Colors.lightBlueAccent),
                  const SizedBox(width: 8),
                  _statCard('QR / TRANSF.', 'Bs. ${totalTransferencia.toStringAsFixed(2)}', Colors.purpleAccent),
                ],
              ),
              const SizedBox(height: 20),

              // Si es reporte general, mostrar desglose por cobrador
              if (_selectedCollectorId == 'all') ...[
                const Text('Rendición por Cobrador Real',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                if (rendicionPorCobrador.isEmpty)
                  _emptyNotice('No hay cobranzas registradas en este período')
                else
                  ...rendicionPorCobrador.entries.map((entry) {
                    final data = entry.value;
                    return Card(
                      color: AppColors.surfaceDark,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppColors.neonCyan.withOpacity(0.2),
                                  child: const Icon(Icons.person, color: AppColors.neonCyan, size: 18),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['name'] as String,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                                    ),
                                    Text(
                                      '${data['cobrosCount']} cobros realizados',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Bs. ${(data['total'] as double).toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF00E676)),
                                ),
                                Text(
                                  'Ef: Bs. ${(data['efectivo'] as double).toStringAsFixed(2)} | QR: Bs. ${(data['transferencia'] as double).toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 16),
              ],

              // Detalle de transacciones individuales
              Text(
                _selectedCollectorId == 'all'
                    ? 'Transacciones del Período (${filteredPayments.length})'
                    : 'Transacciones del Cobrador (${filteredPayments.length})',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),

              if (filteredPayments.isEmpty)
                _emptyNotice('Sin transacciones en este período y filtro')
              else
                ...filteredPayments.map((p) {
                  final clientName = clientsMap[p.clientId]?.name ?? 'Cliente Desconocido';
                  final collectorName = collectorsMap[p.collectorId]?.name ??
                      (p.collectorId.isNotEmpty ? p.collectorId : 'Administración');
                  final fechaStr = DateFormat('dd/MM/yyyy HH:mm').format(p.paidAt);

                  return Card(
                    color: AppColors.surfaceDark,
                    margin: const EdgeInsets.only(bottom: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        backgroundColor: Colors.white.withOpacity(0.08),
                        child: const Icon(Icons.payment, size: 16, color: AppColors.neonCyan),
                      ),
                      title: Text(clientName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text(
                        'Cobrador: $collectorName • $fechaStr • ${p.method.name.toUpperCase()}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                      trailing: Text(
                        'Bs. ${p.amount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00E676), fontSize: 13),
                      ),
                    ),
                  );
                }),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.neonCyan)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.redAccent))),
      ),
    );
  }

  Widget _periodButton(String label, ReportPeriod period) {
    final isSelected = _period == period;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _period = period),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.neonCyan : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.black : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 8, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _emptyNotice(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(message, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
      ),
    );
  }
}
