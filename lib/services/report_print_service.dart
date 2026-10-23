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
  // 1. Imprimir Arqueo / Cierre Diario de Cobranzas
  static Future<void> printDailyCollection({
    required String collectorName,
    required DateTime date,
    required List<Payment> payments,
    required List<Client> clients,
    Map<String, AppUser>? collectorsMap,
  }) async {
    final pdf = pw.Document();
    final fmtDate = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final fmtDay = DateFormat('dd/MM/yyyy').format(date);
    final company = ConfigService.companyName;

    final totalCollected = payments.fold<double>(0.0, (sum, p) => sum + p.amount);
    final cashTotal = payments
        .where((p) => p.method == PaymentMethod.cash)
        .fold<double>(0.0, (sum, p) => sum + p.amount);
    final qrTransferTotal = payments
        .where((p) => p.method != PaymentMethod.cash)
        .fold<double>(0.0, (sum, p) => sum + p.amount);

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
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(company,
                          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                      pw.Text('ARQUEO Y REPORTE DE COBRANZAS',
                          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Fecha del reporte: $fmtDay', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Impreso: $fmtDate', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
              pw.Divider(thickness: 1, height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('COBRADOR RESPONSABLE: $collectorName',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                    pw.Text('ESTADO: ACTIVO', style: const pw.TextStyle(fontSize: 11)),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),
              // Resumen Financiero
              pw.Row(
                children: [
                  _statBox('TOTAL COBRADO', 'Bs. ${totalCollected.toStringAsFixed(2)}', PdfColors.green700),
                  pw.SizedBox(width: 8),
                  _statBox('EFECTIVO EN MANO', 'Bs. ${cashTotal.toStringAsFixed(2)}', PdfColors.blue700),
                  pw.SizedBox(width: 8),
                  _statBox('QR / TRANSFERENCIA', 'Bs. ${qrTransferTotal.toStringAsFixed(2)}', PdfColors.purple700),
                  pw.SizedBox(width: 8),
                  _statBox('TOTAL PAGOS', '${payments.length}', PdfColors.grey800),
                ],
              ),
              pw.SizedBox(height: 18),
              pw.Text('DETALLE DE COBROS REALIZADOS',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _th('Hora'),
                      _th('Cliente'),
                      _th('Cobrado Por'),
                      _th('Método'),
                      _th('Monto Cobrado'),
                      _th('Saldo Posterior'),
                    ],
                  ),
                  ...payments.map((p) {
                    final c = clients.firstWhere(
                      (x) => x.id == p.clientId,
                      orElse: () => Client(
                        id: '',
                        name: 'Cliente Desconocido',
                        phone: '',
                        documentId: '',
                        address: '',
                        createdAt: DateTime.now(),
                      ),
                    );
                    final whoCollected = collectorsMap?[p.collectorId]?.name ??
                        (p.collectorId.isNotEmpty ? p.collectorId : collectorName);

                    return pw.TableRow(
                      children: [
                        _td(DateFormat('HH:mm').format(p.paidAt)),
                        _td(c.name),
                        _td(whoCollected, bold: true),
                        _td(p.method.name.toUpperCase()),
                        _td('Bs. ${p.amount.toStringAsFixed(2)}', align: pw.TextAlign.right, bold: true),
                        _td('Bs. ${p.pendingAfter.toStringAsFixed(2)}', align: pw.TextAlign.right),
                      ],
                    );
                  }),
                ],
              ),
              pw.Spacer(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _signatureLine('Firma de Conformidad\n$collectorName'),
                  _signatureLine('Firma / Sello de Administración'),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Arqueo_Cobranzas_${DateFormat('yyyyMMdd').format(date)}.pdf',
    );
  }

  // 2. Imprimir Hoja de Ruta de Cobranza del Día
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
                    if (clientLoans.isEmpty) return pw.TableRow(children: [_td(''), _td(''), _td(''), _td(''), _td(''), _td('')]);

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
