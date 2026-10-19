import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/payment_model.dart';
import '../models/client_model.dart';

class DailyReportPdfService {
  DailyReportPdfService._();

  static Future<Uint8List> buildDailyReportPdf({
    required DateTime date,
    required String collectorName,
    required List<Payment> payments,
    required Map<String, Client> clientsMap,
    required double totalCash,
    required double totalDigital,
    required double totalGeneral,
  }) async {
    final pdf = pw.Document();
    final dateFmt = DateFormat('dd/MM/yyyy');
    final timeFmt = DateFormat('HH:mm');

    // Calculamos una altura finita según la cantidad de transacciones para rollo de 80 mm
    // Base mínima: 220 mm + 14 mm por cada pago
    final double calculatedHeightMm = (220.0 + (payments.length * 14.0)).clamp(220.0, 1800.0);
    final customRoll80 = PdfPageFormat(
      80 * PdfPageFormat.mm,
      calculatedHeightMm * PdfPageFormat.mm,
      marginAll: 4 * PdfPageFormat.mm,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: customRoll80,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text('CIERRE DIARIO DE CAJA', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 2),
                  pw.Text('AScobrar - Sistema Offline', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                  pw.SizedBox(height: 4),
                  pw.Divider(thickness: 0.8),
                ],
              ),
            ),
            pw.SizedBox(height: 2),
            _row('Fecha:', dateFmt.format(date)),
            _row('Cobrador:', collectorName),
            _row('Recibos Emitidos:', '${payments.length}'),
            pw.SizedBox(height: 4),
            pw.Divider(thickness: 0.8),
            pw.SizedBox(height: 2),

            pw.Text('DISCRIMINACION DE INGRESOS:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 3),
            _row('Efectivo en Caja:', 'Bs. ${totalCash.toStringAsFixed(2)}'),
            _row('Transferencias / QR:', 'Bs. ${totalDigital.toStringAsFixed(2)}'),
            pw.SizedBox(height: 3),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 0.8),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
              ),
              child: _row('TOTAL GENERAL:', 'Bs. ${totalGeneral.toStringAsFixed(2)}', isBold: true, fontSize: 9),
            ),

            pw.SizedBox(height: 6),
            pw.Divider(thickness: 0.8),
            pw.SizedBox(height: 2),
            pw.Text('DETALLE DE COBROS:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),

            if (payments.isEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 8),
                child: pw.Center(
                  child: pw.Text('No hubo recaudaciones registradas', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                ),
              )
            else
              ...payments.map((p) {
                final client = clientsMap[p.clientId];
                final clientName = client?.name ?? 'Cliente Desconocido';
                final methodStr = p.method == PaymentMethod.cash ? 'Efectivo' : 'QR/Transf.';

                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 3),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              clientName,
                              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                              maxLines: 1,
                            ),
                          ),
                          pw.Text('Bs. ${p.amount.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('${timeFmt.format(p.paidAt)} - $methodStr', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                          pw.Text('Saldo: Bs. ${p.pendingAfter.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                        ],
                      ),
                      pw.Divider(thickness: 0.3, color: PdfColors.grey400),
                    ],
                  ),
                );
              }),

            pw.SizedBox(height: 14),
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Container(width: 120, height: 0.5, color: PdfColors.black),
                  pw.SizedBox(height: 2),
                  pw.Text('Firma del Responsable', style: const pw.TextStyle(fontSize: 7)),
                  pw.SizedBox(height: 1),
                  pw.Text('AScobrar 100% Offline', style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  static Future<void> printDailyReport({
    required DateTime date,
    required String collectorName,
    required List<Payment> payments,
    required Map<String, Client> clientsMap,
    required double totalCash,
    required double totalDigital,
    required double totalGeneral,
  }) async {
    final pdfBytes = await buildDailyReportPdf(
      date: date,
      collectorName: collectorName,
      payments: payments,
      clientsMap: clientsMap,
      totalCash: totalCash,
      totalDigital: totalDigital,
      totalGeneral: totalGeneral,
    );

    await Printing.layoutPdf(
      name: 'Cierre_${DateFormat('yyyyMMdd').format(date)}_caja.pdf',
      onLayout: (format) async => pdfBytes,
    );
  }

  static Future<void> sendToAdminWhatsApp({
    required String adminPhone,
    required DateTime date,
    required String collectorName,
    required List<Payment> payments,
    required Map<String, Client> clientsMap,
    required double totalCash,
    required double totalDigital,
    required double totalGeneral,
  }) async {
    final dateFmt = DateFormat('dd/MM/yyyy');
    final timeFmt = DateFormat('HH:mm');

    final buffer = StringBuffer();
    buffer.writeln('*CIERRE DIARIO DE COBRANZA*');
    buffer.writeln('==============================');
    buffer.writeln('*Fecha:* ${dateFmt.format(date)}');
    buffer.writeln('*Cobrador:* $collectorName');
    buffer.writeln('*Cobros Realizados:* ${payments.length}');
    buffer.writeln('==============================');
    buffer.writeln('*Efectivo en Caja:* Bs. ${totalCash.toStringAsFixed(2)}');
    buffer.writeln('*Transferencias / QR:* Bs. ${totalDigital.toStringAsFixed(2)}');
    buffer.writeln('*TOTAL GENERAL:* Bs. ${totalGeneral.toStringAsFixed(2)}');
    buffer.writeln('==============================');

    if (payments.isNotEmpty) {
      buffer.writeln('*DETALLE DE RECAUDACIONES:*');
      for (final p in payments) {
        final client = clientsMap[p.clientId];
        final clientName = client?.name ?? 'Cliente Desconocido';
        final methodStr = p.method == PaymentMethod.cash ? 'Efectivo' : 'QR/Transf.';
        buffer.writeln('- ${timeFmt.format(p.paidAt)} | $clientName: *Bs. ${p.amount.toStringAsFixed(2)}* ($methodStr)');
      }
      buffer.writeln('==============================');
    }

    buffer.writeln('_Reporte generado por AScobrar (Offline)_');

    final cleanedPhone = adminPhone.replaceAll(RegExp(r'[^\d]'), '');
    final encodedMsg = Uri.encodeComponent(buffer.toString());
    final url = Uri.parse('https://wa.me/$cleanedPhone?text=$encodedMsg');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  static pw.Widget _row(String label, String value, {bool isBold = false, double fontSize = 8}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: fontSize, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value, style: pw.TextStyle(fontSize: fontSize, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }
}
