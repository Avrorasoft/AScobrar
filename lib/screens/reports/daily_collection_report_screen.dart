import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/theme/app_colors.dart';
import '../../models/client_model.dart';
import '../../models/payment_model.dart';
import '../../models/user_model.dart';
import '../../providers/clients_provider.dart';
import '../../services/config_service.dart';
import '../../services/data_service.dart';

class DailyCollectionReportScreen extends ConsumerStatefulWidget {
  const DailyCollectionReportScreen({super.key});

  @override
  ConsumerState<DailyCollectionReportScreen> createState() =>
      _DailyCollectionReportScreenState();
}

class _DailyCollectionReportScreenState
    extends ConsumerState<DailyCollectionReportScreen> {
  DateTime _selectedDate = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryMid,
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

  Future<void> _imprimirArqueoDiario({
    required List<Payment> payments,
    required Map<String, Client> clientsMap,
    required Map<String, AppUser> collectorsMap,
    required Map<String, Map<String, dynamic>> rendicion,
    required double totalRecaudado,
    required double totalEfectivo,
    required double totalTransferencias,
  }) async {
    final pdf = pw.Document();
    final company = ConfigService.companyName;
    final currency = ConfigService.currency;
    final dateStr = DateFormat('dd/MM/yyyy').format(_selectedDate);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context ctx) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(company.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
                    pw.Text('ARQUEO Y RENDICIÓN DIARIA DE COBRADORES', style: const pw.TextStyle(fontSize: 11)),
                  ],
                ),
                pw.Text('Fecha: $dateStr', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
          pw.SizedBox(height: 10),

          // Resumen General
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Text('TOTAL: $currency ${totalRecaudado.round()}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                pw.Text('EFECTIVO EN MANO: $currency ${totalEfectivo.round()}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                pw.Text('TRANSFERENCIAS: $currency ${totalTransferencias.round()}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          pw.Text('TABLA DE RENDICIÓN POR COBRADOR:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: ['Cobrador', 'Teléfono', 'Efectivo a Entregar', 'Transferencias', 'Total Cobrado', 'N° Recibos'],
            data: rendicion.entries.map((e) {
              final user = collectorsMap[e.key];
              final name = user != null ? user.name : (e.key == 'admin_default' ? 'Administrador' : 'Cobrador (${e.key})');
              final phone = user != null ? user.phone : '-';
              return [
                name,
                phone,
                '$currency ${(e.value['efectivo'] as double).round()}',
                '$currency ${(e.value['transferencia'] as double).round()}',
                '$currency ${(e.value['total'] as double).round()}',
                '${e.value['conteo']}',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
          ),
          pw.SizedBox(height: 20),

          pw.Text('DETALLE DE COBROS:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: ['Hora', 'Cliente', 'Cobrador Responsable', 'Método', 'Monto'],
            data: payments.map((p) {
              final client = clientsMap[p.clientId];
              final user = collectorsMap[p.collectorId];
              final collectorName = user != null ? user.name : (p.collectorId == 'admin_default' ? 'Administrador' : p.collectorId);
              return [
                DateFormat('HH:mm:ss').format(p.paidAt.toLocal()),
                client?.name ?? 'Desconocido',
                collectorName,
                p.method == PaymentMethod.cash ? 'Efectivo' : 'Transferencia',
                '$currency ${p.amount.round()}',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
            cellStyle: const pw.TextStyle(fontSize: 8),
          ),
          pw.SizedBox(height: 30),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              pw.Column(children: [
                pw.Container(width: 140, height: 1, color: PdfColors.black),
                pw.SizedBox(height: 4),
                pw.Text('Firma del Administrador', style: const pw.TextStyle(fontSize: 9)),
              ]),
              pw.Column(children: [
                pw.Container(width: 140, height: 1, color: PdfColors.black),
                pw.SizedBox(height: 4),
                pw.Text('Firma de Conformidad Cobrador', style: const pw.TextStyle(fontSize: 9)),
              ]),
            ],
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: 'Arqueo_Diario_$dateStr',
    );
  }

  @override
  Widget build(BuildContext context) {
    final clientsList = ref.watch(clientsStreamProvider).value ?? [];
    final clientsMap = {for (var c in clientsList) c.id: c};

    final collectorsList = DataService.allCollectors();
    final Map<String, AppUser> collectorsMap = {for (var u in collectorsList) u.id: u};

    final allPaymentsRaw = DataService.payments.values.toList();
    final List<Payment> dayPayments = [];

    for (var p in allPaymentsRaw) {
      if (p is Map) {
        final payment = Payment.fromMap(Map<String, dynamic>.from(p));
        final isSameDay = payment.paidAt.year == _selectedDate.year &&
            payment.paidAt.month == _selectedDate.month &&
            payment.paidAt.day == _selectedDate.day;
        if (isSameDay) {
          dayPayments.add(payment);
        }
      }
    }

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
          'efectivo': 0.0,
          'transferencia': 0.0,
          'total': 0.0,
          'conteo': 0,
        };
      }

      final item = rendicionPorCobrador[cId]!;
      if (isCash) {
        item['efectivo'] = (item['efectivo'] as double) + p.amount;
      } else {
        item['transferencia'] = (item['transferencia'] as double) + p.amount;
      }
      item['total'] = (item['total'] as double) + p.amount;
      item['conteo'] = (item['conteo'] as int) + 1;
    }

    final formattedDate = DateFormat('dd/MM/yyyy').format(_selectedDate);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text(
          'Arqueo Diario & Rendición de Cobradores',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textLight),
        ),
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.print, color: AppColors.neonCyan),
            tooltip: 'Imprimir Arqueo Completo',
            onPressed: () => _imprimirArqueoDiario(
              payments: dayPayments,
              clientsMap: clientsMap,
              collectorsMap: collectorsMap,
              rendicion: rendicionPorCobrador,
              totalRecaudado: totalRecaudado,
              totalEfectivo: totalEfectivo,
              totalTransferencias: totalTransferencias,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today, color: AppColors.primaryMid),
            tooltip: 'Cambiar Fecha',
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fecha: $formattedDate',
                  style: const TextStyle(
                    color: AppColors.primaryMid,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.neonCyan,
                        foregroundColor: AppColors.bgDark,
                      ),
                      icon: const Icon(Icons.print, size: 18),
                      label: const Text('IMPRIMIR INFORME', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () => _imprimirArqueoDiario(
                        payments: dayPayments,
                        clientsMap: clientsMap,
                        collectorsMap: collectorsMap,
                        rendicion: rendicionPorCobrador,
                        totalRecaudado: totalRecaudado,
                        totalEfectivo: totalEfectivo,
                        totalTransferencias: totalTransferencias,
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryMid,
                        side: const BorderSide(color: AppColors.primaryMid),
                      ),
                      icon: const Icon(Icons.date_range, size: 18),
                      label: const Text('Elegir Día'),
                      onPressed: () => _selectDate(context),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _kpiCard(
                    title: 'TOTAL RECAUDADO',
                    amount: 'Bs. ${totalRecaudado.round()}',
                    subtitle: '${dayPayments.length} cobros',
                    color: AppColors.primaryMid,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _kpiCard(
                    title: 'EFECTIVO EN MANO',
                    amount: 'Bs. ${totalEfectivo.round()}',
                    subtitle: 'Dinero físico a entregar',
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _kpiCard(
                    title: 'TRANSFERENCIAS / QR',
                    amount: 'Bs. ${totalTransferencias.round()}',
                    subtitle: 'Ingreso bancario',
                    color: AppColors.neonCyan,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            const Text(
              'Rendición de Cuentas por Cobrador',
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Monto exacto en efectivo que cada cobrador debe entregar físicamente.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 14),

            if (rendicionPorCobrador.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.textMuted.withOpacity(0.2)),
                ),
                child: const Center(
                  child: Text(
                    'No se registraron cobros en esta fecha.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.textMuted.withOpacity(0.2)),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(AppColors.bgDark),
                    columns: const [
                      DataColumn(
                        label: Text('Cobrador / Operador',
                            style: TextStyle(color: AppColors.primaryMid, fontWeight: FontWeight.bold)),
                      ),
                      DataColumn(
                        label: Text('Efectivo a Entregar (Bs.)',
                            style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                      ),
                      DataColumn(
                        label: Text('Transferencia / QR (Bs.)',
                            style: TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.bold)),
                      ),
                      DataColumn(
                        label: Text('Total Cobrado (Bs.)',
                            style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
                      ),
                      DataColumn(
                        label: Text('Recibos',
                            style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                      ),
                    ],
                    rows: rendicionPorCobrador.entries.map((entry) {
                      final cId = entry.key;
                      final data = entry.value;
                      final user = collectorsMap[cId];
                      final name = user != null ? user.name : (cId == 'admin_default' ? 'Administrador' : 'Cobrador ($cId)');
                      final phone = user != null ? user.phone : '-';

                      final cash = (data['efectivo'] as double).round();
                      final trans = (data['transferencia'] as double).round();
                      final total = (data['total'] as double).round();
                      final count = data['conteo'] as int;

                      return DataRow(
                        cells: [
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(name, style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
                                Text('Tel: $phone', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                              ],
                            ),
                          ),
                          DataCell(
                            Text('Bs. $cash',
                                style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                          DataCell(
                            Text('Bs. $trans',
                                style: const TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                          DataCell(
                            Text('Bs. $total',
                                style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                          DataCell(
                            Text('$count cobro(s)', style: const TextStyle(color: AppColors.textMuted)),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),

            const SizedBox(height: 32),

            const Text(
              'Detalle Individual de Cobros Registrados',
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),

            if (dayPayments.isEmpty)
              const SizedBox.shrink()
            else
              ...dayPayments.map((p) {
                final client = clientsMap[p.clientId];
                final collector = collectorsMap[p.collectorId];
                final clientName = client?.name ?? 'Cliente Desconocido';
                final collectorName = collector?.name ?? (p.collectorId == 'admin_default' ? 'Administrador' : 'ID: ${p.collectorId}');
                final isCash = p.method == PaymentMethod.cash;

                return Card(
                  color: AppColors.surfaceDark,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: AppColors.textMuted.withOpacity(0.15)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: isCash ? AppColors.success.withOpacity(0.2) : AppColors.neonCyan.withOpacity(0.2),
                      child: Icon(
                        isCash ? Icons.money : Icons.qr_code_scanner,
                        color: isCash ? AppColors.success : AppColors.neonCyan,
                        size: 20,
                      ),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(clientName,
                            style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 15)),
                        Text('Bs. ${p.amount.round()}',
                            style: TextStyle(
                              color: isCash ? AppColors.success : AppColors.neonCyan,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            )),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.badge_outlined, size: 14, color: AppColors.primaryMid),
                            const SizedBox(width: 4),
                            Text('Cobrado por: $collectorName',
                                style: const TextStyle(color: AppColors.primaryMid, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Hora: ${DateFormat('HH:mm:ss').format(p.paidAt.toLocal())} • ${isCash ? 'Efectivo en mano' : 'Transferencia'}',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _kpiCard({
    required String title,
    required String amount,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(amount, style: const TextStyle(color: AppColors.textLight, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}
