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

class DailyCollectionReportScreen extends ConsumerStatefulWidget {
  const DailyCollectionReportScreen({super.key});

  @override
  ConsumerState<DailyCollectionReportScreen> createState() => _DailyCollectionReportScreenState();
}

class _DailyCollectionReportScreenState extends ConsumerState<DailyCollectionReportScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(paymentsStreamProvider);
    final clientsAsync = ref.watch(clientsStreamProvider);
    final usersAsync = ref.watch(allUsersStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Reporte Diario de Caja', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, color: AppColors.neonCyan),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
              }
            },
          ),
        ],
      ),
      body: paymentsAsync.when(
        data: (allPayments) {
          final allClients = clientsAsync.value ?? [];
          final allUsers = usersAsync.value ?? [];

          final Map<String, Client> clientsMap = {
            for (var c in allClients) c.id: c
          };
          final Map<String, AppUser> collectorsMap = {
            for (var u in allUsers) u.id: u
          };

          final dayPayments = allPayments.where((p) {
            return p.paidAt.year == _selectedDate.year &&
                p.paidAt.month == _selectedDate.month &&
                p.paidAt.day == _selectedDate.day;
          }).toList();

          final totalRecaudado = dayPayments.fold<double>(0.0, (sum, p) => sum + p.amount);
          final totalEfectivo = dayPayments
              .where((p) => p.method == PaymentMethod.cash)
              .fold<double>(0.0, (sum, p) => sum + p.amount);
          final totalTransferencia = dayPayments
              .where((p) => p.method != PaymentMethod.cash)
              .fold<double>(0.0, (sum, p) => sum + p.amount);

          // Rendición por Cobrador Real
          final Map<String, Map<String, dynamic>> rendicionPorCobrador = {};

          for (var p in dayPayments) {
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

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Barra de fecha y botón imprimir
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('EEEE dd MMMM, yyyy').format(_selectedDate),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonCyan),
                    icon: const Icon(Icons.print, size: 16),
                    label: const Text('Imprimir Reporte'),
                    onPressed: () {
                      ReportPrintService.printDailyCollection(
                        collectorName: 'Reporte General',
                        date: _selectedDate,
                        payments: dayPayments,
                        clients: allClients,
                        collectorsMap: collectorsMap,
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

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
              const SizedBox(height: 24),

              // Rendición por Cobrador Real
              const Text('Rendición por Cobrador Real',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 10),

              if (rendicionPorCobrador.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text('No hay cobranzas registradas en esta fecha',
                        style: TextStyle(color: AppColors.textMuted)),
                  ),
                )
              else
                ...rendicionPorCobrador.entries.map((entry) {
                  final data = entry.value;
                  return Card(
                    color: AppColors.surfaceDark,
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppColors.neonCyan.withOpacity(0.2),
                                child: const Icon(Icons.person, color: AppColors.neonCyan, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['name'] as String,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
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
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF00E676)),
                              ),
                              Text(
                                'Ef: Bs. ${(data['efectivo'] as double).toStringAsFixed(2)} | QR: Bs. ${(data['transferencia'] as double).toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 24),
              // Detalle individual de cobros
              const Text('Detalle de Cobros Realizados',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 10),

              if (dayPayments.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text('Sin cobros en la fecha', style: TextStyle(color: AppColors.textMuted)),
                  ),
                )
              else
                ...dayPayments.map((p) {
                  final clientName = clientsMap[p.clientId]?.name ?? 'Cliente Desconocido';
                  final collectorName = collectorsMap[p.collectorId]?.name ??
                      (p.collectorId.isNotEmpty ? p.collectorId : 'Administración');
                  final hora = DateFormat('HH:mm').format(p.paidAt);

                  return Card(
                    color: AppColors.surfaceDark,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.white.withOpacity(0.08),
                        child: Text(hora, style: const TextStyle(fontSize: 10, color: AppColors.neonCyan)),
                      ),
                      title: Text(clientName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        'Cobrador: $collectorName • ${p.method.name.toUpperCase()}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                      trailing: Text(
                        'Bs. ${p.amount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00E676), fontSize: 14),
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

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
