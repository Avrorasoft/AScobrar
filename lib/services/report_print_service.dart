import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/client_model.dart';
import '../models/loan_model.dart';
import '../models/payment_model.dart';
import '../models/user_model.dart';
import '../services/config_service.dart';

class ReportPrintService {
  // Generador puro de bytes para Previsualización en pantalla
  static Future<Uint8List> buildFinancialReportPdf({
    required String periodTitle,
    required String periodRangeText,
    required String targetScopeTitle,
    required List<Payment> payments,
    required List<Client> clients,
    required Map<String, AppUser> collectorsMap,
  }) async {
    final pdf = pw.Document();
    final fmtPrinted = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final company = ConfigService.companyName;

    final totalCollected = payments.fold<double>(0.0, (sum, p) => sum + p.amount);
    final cashTotal = payments
        .where((p) => p.method == PaymentMethod.cash)
        .fold<double>(0.0, (sum, p) => sum + p.amount);
    final qrTransferTotal = payments
        .where((p) => p.method != PaymentMethod.cash)
        .fold<double>(0.0, (sum, p) => sum + p.amount);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            // Cabecera
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(company,
                        style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                    pw.Text('REPORTE FINANCIERO DE COBRANZAS',
                        style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Período: $periodTitle',
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Rango: $periodRangeText', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Impreso: $fmtPrinted', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                  ],
                ),
              ],
            ),
            pw.Divider(thickness: 1, height: 16),

            // Alcance del Reporte
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('ALCANCE: $targetScopeTitle',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  pw.Text('TOTAL TRANSACCIONES: ${payments.length}',
                      style: const pw.TextStyle(fontSize: 11)),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // Resumen de Montos
            pw.Row(
              children: [
                _statBox('TOTAL RECAUDADO', 'Bs. ${totalCollected.toStringAsFixed(2)}', PdfColors.green700),
                pw.SizedBox(width: 8),
                _statBox('EFECTIVO EN CAJA', 'Bs. ${cashTotal.toStringAsFixed(2)}', PdfColors.blue700),
                pw.SizedBox(width: 8),
                _statBox('QR / TRANSFERENCIAS', 'Bs. ${qrTransferTotal.toStringAsFixed(2)}', PdfColors.purple700),
              ],
            ),
            pw.SizedBox(height: 16),

            // Detalle de Transacciones
            pw.Text('DETALLE DE INGRESOS',
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _th('Fecha / Hora'),
                    _th('Cliente'),
                    _th('Cobrador'),
                    _th('Método'),
                    _th('Monto Cobrado'),
                    _th('Saldo Post.'),
                  ],
                ),
                ...payments.map((p) {
                  final client = clients.firstWhere(
                    (c) => c.id == p.clientId,
                    orElse: () => Client(
                      id: '',
                      name: 'Cliente Desconocido',
                      phone: '',
                      documentId: '',
                      address: '',
                      createdAt: DateTime.now(),
                    ),
                  );
                  final collectorName = collectorsMap[p.collectorId]?.name ??
                      (p.collectorId.isNotEmpty ? p.collectorId : 'Administración');

                  return pw.TableRow(
                    children: [
                      _td(DateFormat('dd/MM HH:mm').format(p.paidAt)),
                      _td(client.name),
                      _td(collectorName, bold: true),
                      _td(p.method.name.toUpperCase()),
                      _td('Bs. ${p.amount.toStringAsFixed(2)}', align: pw.TextAlign.right, bold: true),
                      _td('Bs. ${p.pendingAfter.toStringAsFixed(2)}', align: pw.TextAlign.right),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 24),

            // Firmas de Rendición
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _signatureLine('Firma de Conformidad / Responsable'),
                _signatureLine('Firma / Sello de Administración'),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // 1. Reporte Financiero Multitemporal (General o Individual)
  static Future<void> printFinancialReport({
    required String periodTitle,
    required String periodRangeText,
    required String targetScopeTitle,
    required List<Payment> payments,
    required List<Client> clients,
    required Map<String, AppUser> collectorsMap,
  }) async {
    final bytes = await buildFinancialReportPdf(
      periodTitle: periodTitle,
      periodRangeText: periodRangeText,
      targetScopeTitle: targetScopeTitle,
      payments: payments,
      clients: clients,
      collectorsMap: collectorsMap,
    );
    await Printing.layoutPdf(
      onLayout: (format) async => bytes,
      name: 'Reporte_${periodTitle}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  // 2. Hoja de Ruta de Cobranza
  static Future<void> printDailyRoute({
    required String collectorName,
    required List<Client> clients,
    required List<Loan> activeLoans,
  }) async {
    final pdf = pw.Document();
    final fmtDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
    final company = ConfigService.companyName;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('$company - HOJA DE RUTA',
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Fecha: $fmtDate', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.Text('COBRADOR ASIGNADO: $collectorName',
                  style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
              pw.Divider(thickness: 1, height: 16),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _th('#'),
                      _th('Cliente'),
                      _th('Dirección'),
                      _th('Cuota Diaria'),
                      _th('Saldo Pend.'),
                      _th('Firma / Cobrado'),
                    ],
                  ),
                  ...clients.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final client = entry.value;
                    final clientLoans = activeLoans.where((l) => l.clientId == client.id).toList();
                    if (clientLoans.isEmpty) {
                      return pw.TableRow(children: [_td(''), _td(''), _td(''), _td(''), _td(''), _td('')]);
                    }

                    final loan = clientLoans.first;
                    final cuota = loan.installments > 0 ? (loan.principal / loan.installments) : 0.0;

                    return pw.TableRow(
                      children: [
                        _td('$idx'),
                        _td(client.name, bold: true),
                        _td(client.address),
                        _td('Bs. ${cuota.toStringAsFixed(2)}', align: pw.TextAlign.right, bold: true),
                        _td('Bs. ${loan.pendingAmount.toStringAsFixed(2)}', align: pw.TextAlign.right),
                        _td(' [   ] Cobrado \n________________'),
                      ],
                    );
                  }).where((row) => row.children.isNotEmpty),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Hoja_De_Ruta_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  // Compatibilidad hacia atrás para llamadas puntuales de arqueo
  static Future<void> printDailyCollection({
    required String collectorName,
    required DateTime date,
    required List<Payment> payments,
    required List<Client> clients,
    Map<String, AppUser>? collectorsMap,
  }) async {
    await printFinancialReport(
      periodTitle: 'DIARIO',
      periodRangeText: DateFormat('dd/MM/yyyy').format(date),
      targetScopeTitle: collectorName.toUpperCase(),
      payments: payments,
      clients: clients,
      collectorsMap: collectorsMap ?? {},
    );
  }

  static pw.Widget _statBox(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(6),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: color, width: 1),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
            pw.SizedBox(height: 2),
            pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _signatureLine(String title) {
    return pw.Column(
      children: [
        pw.Container(width: 160, height: 1, color: PdfColors.black),
        pw.SizedBox(height: 4),
        pw.Text(title, textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 9)),
      ],
    );
  }

  static pw.Widget _th(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
    );
  }

  static pw.Widget _td(String text, {pw.TextAlign align = pw.TextAlign.left, bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(fontSize: 8, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal),
      ),
    );
  }
}
