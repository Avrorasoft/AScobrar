import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/client_model.dart';
import '../models/loan_model.dart';
import '../models/payment_model.dart';

class ReceiptPdfService {
  static Future<void> printReceipt({
    Payment? payment,
    required Loan loan,
    Client? client,
    required int installmentNumber,
    required double installmentAmount,
    DateTime? dueDate,
    bool? isPaid,
    String? collectorName,
    String? collectorPhone,
  }) async {
    final doc = pw.Document();
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    final clientName = client?.name ?? 'Cliente';
    final clientDoc = client?.documentId ?? '-';
    final clientPhone = client?.phone ?? '-';
    final paidDate = payment != null ? dateFmt.format(payment.paidAt) : dateFmt.format(DateTime.now());
    final pendingAmount = payment != null ? payment.pendingAfter : loan.pendingAmount;

    doc.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    'ASCOBRAR - COMPROBANTE DE PAGO',
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.SizedBox(height: 15),
                pw.Text('Fecha: $paidDate'),
                pw.Text('Cliente: $clientName'),
                pw.Text('C.I.: $clientDoc'),
                pw.Text('Teléfono: $clientPhone'),
                if (collectorName != null && collectorName.isNotEmpty)
                  pw.Text('Cobrador: $collectorName'),
                if (collectorPhone != null && collectorPhone.isNotEmpty)
                  pw.Text('Contacto Cobrador: $collectorPhone'),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Text('Monto Cobrado: Bs. ${installmentAmount.round()}'),
                pw.Text('Cuota N°: $installmentNumber / ${loan.installments}'),
                if (dueDate != null)
                  pw.Text('Fecha Vencimiento Cuota: ${DateFormat('dd/MM/yyyy').format(dueDate)}'),
                if (isPaid != null)
                  pw.Text('Estado Cuota: ${isPaid ? "PAGADA" : "PENDIENTE"}'),
                pw.Text('Saldo Pendiente en Préstamo: Bs. ${pendingAmount.round()}'),
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text(
                    '¡Gracias por su puntualidad!',
                    style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
    );
  }

  static Future<void> printPaymentHistory({
    required Loan loan,
    Client? client,
    required List<Payment> payments,
  }) async {
    final doc = pw.Document();
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    final clientName = client?.name ?? 'Cliente';
    final clientDoc = client?.documentId ?? '-';

    doc.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    'ASCOBRAR - HISTORIAL DE PAGOS',
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.SizedBox(height: 15),
                pw.Text('Cliente: $clientName'),
                pw.Text('C.I.: $clientDoc'),
                pw.Text('Préstamo Capital: Bs. ${loan.principal.round()} (${loan.interestRate.round()}%)'),
                pw.Divider(),
                pw.SizedBox(height: 10),
                ...payments.map((p) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 6),
                      child: pw.Text(
                        '• ${dateFmt.format(p.paidAt)} - Bs. ${p.amount.round()} (Saldo: Bs. ${p.pendingAfter.round()})',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    )),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
    );
  }

  static Future<void> shareViaWhatsApp({
    Client? client,
    Payment? payment,
    required Loan loan,
    required int installmentNumber,
    double? installmentAmount,
    DateTime? dueDate,
    bool? isPaid,
    String? collectorName,
    String? collectorPhone,
  }) async {
    final phone = (client?.phone ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    final name = client?.name ?? 'Cliente';
    final amount = installmentAmount ?? payment?.amount ?? 0.0;
    final pending = payment?.pendingAfter ?? loan.pendingAmount;

    final dueDateText = dueDate != null
        ? '\nVencimiento: ${DateFormat('dd/MM/yyyy').format(dueDate)}'
        : '';
    final statusText = isPaid != null ? (isPaid ? ' (PAGADA)' : ' (PENDIENTE)') : '';
    final collectorText = (collectorName != null && collectorName.isNotEmpty)
        ? '\nCobrador en ruta: $collectorName'
        : '';
    final collectorContactText = (collectorPhone != null && collectorPhone.isNotEmpty)
        ? ' (Tel: $collectorPhone)'
        : '';

    final message = Uri.encodeComponent(
      'Hola *$name* 👋\n\n'
      'Le confirmamos el registro de la cuota *$installmentNumber$statusText* por *Bs. ${amount.round()}*.$dueDateText$collectorText$collectorContactText\n'
      'Saldo pendiente: *Bs. ${pending.round()}*.\n\n'
      '¡Gracias por su puntualidad con AScobrar!',
    );

    final url = Uri.parse('https://wa.me/$phone?text=$message');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  static Future<void> sharePaymentHistoryViaWhatsApp({
    Client? client,
    required Loan loan,
    required List<Payment> payments,
  }) async {
    final phone = (client?.phone ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    final name = client?.name ?? 'Cliente';
    final totalPaid = payments.fold<double>(0.0, (sum, p) => sum + p.amount);

    final message = Uri.encodeComponent(
      'Hola *$name* 👋\n\n'
      'Resumen de su estado de cuenta en AScobrar:\n'
      '• Capital Préstamo: Bs. ${loan.principal.round()}\n'
      '• Total Pagado: Bs. ${totalPaid.round()}\n'
      '• Saldo Pendiente: Bs. ${loan.pendingAmount.round()}\n\n'
      '¡Gracias por confiar en nosotros!',
    );

    final url = Uri.parse('https://wa.me/$phone?text=$message');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
