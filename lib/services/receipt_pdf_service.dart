import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/client_model.dart';
import '../models/loan_model.dart';
import '../models/payment_model.dart';
import '../models/user_model.dart';
import '../services/data_service.dart';

class ReceiptPdfService {
  // Resuelve el nombre del cobrador garantizando que nunca sea nulo ni vacío
  static Future<String> _resolveCollectorName(Payment? payment, String? explicitName) async {
    if (explicitName != null && explicitName.trim().isNotEmpty) {
      return explicitName.trim();
    }

    final collectorId = payment?.collectorId ?? '';
    if (collectorId.isNotEmpty) {
      // 1. Buscar en Hive local
      final raw = DataService.users.get(collectorId);
      if (raw != null) {
        final map = Map<String, dynamic>.from(raw as Map);
        final name = (map['name'] ?? '').toString().trim();
        if (name.isNotEmpty) return name;
      }

      // 2. Buscar en Firestore
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(collectorId).get();
        if (doc.exists && doc.data() != null) {
          final name = (doc.data()!['name'] ?? '').toString().trim();
          if (name.isNotEmpty) return name;
        }
      } catch (_) {}
    }

    // 3. Cobrador de la sesión activa
    final sessionUser = DataService.getCurrentUserSession();
    if (sessionUser != null && sessionUser.name.trim().isNotEmpty) {
      return sessionUser.name.trim();
    }

    return 'Cobrador';
  }

  static Future<void> printReceipt({
    Payment? payment,
    required Loan loan,
    Client? client,
    required int installmentNumber,
    required double installmentAmount,
    DateTime? dueDate,
    bool? isPaid,
    String? collectorName,
  }) async {
    final doc = pw.Document();
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    final clientName = client?.name ?? 'Cliente';
    final clientDoc = client?.documentId ?? '-';
    final clientPhone = client?.phone ?? '-';
    final paidDate = payment != null ? dateFmt.format(payment.paidAt) : dateFmt.format(DateTime.now());
    final pendingAmount = payment != null ? payment.pendingAfter : loan.pendingAmount;

    // Resolver cobrador con garantía absoluta
    final finalCollectorName = await _resolveCollectorName(payment, collectorName);

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
                pw.Text('Cobrador: $finalCollectorName',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Cuota Número:'),
                    pw.Text('$installmentNumber', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Monto Abonado:'),
                    pw.Text('Bs. ${installmentAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Saldo Pendiente:'),
                    pw.Text('Bs. ${pendingAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.Center(
                  child: pw.Text('¡Gracias por su puntualidad!', style: const pw.TextStyle(fontSize: 10)),
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
    String? collectorName,
  }) async {
    final doc = pw.Document();
    final clientName = client?.name ?? 'Cliente';
    final finalCollectorName = await _resolveCollectorName(
        payments.isNotEmpty ? payments.last : null, collectorName);

    doc.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Historial de Pagos - $clientName', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Text('Cobrador: $finalCollectorName', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Fecha')),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Monto')),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Saldo')),
                    ],
                  ),
                  ...payments.map((p) => pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(DateFormat('dd/MM/yyyy HH:mm').format(p.paidAt))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Bs. ${p.amount.toStringAsFixed(2)}')),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Bs. ${p.pendingAfter.toStringAsFixed(2)}')),
                    ],
                  )),
                ],
              ),
            ],
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
  }) async {
    final phone = (client?.phone ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    final name = client?.name ?? 'Cliente';
    final amount = installmentAmount ?? payment?.amount ?? 0.0;
    final pending = payment != null ? payment.pendingAfter : loan.pendingAmount;
    final dueDateText = dueDate != null ? '\nVencimiento: ${DateFormat('dd/MM/yyyy').format(dueDate)}' : '';
    final statusText = isPaid != null ? (isPaid ? ' (PAGADA)' : ' (PENDIENTE)') : '';

    final finalCollectorName = await _resolveCollectorName(payment, collectorName);
    final collectorText = '\nCobrador: $finalCollectorName';

    final message = Uri.encodeComponent(
      'Hola *$name* 👋\n\n'
      'Le confirmamos el registro de la cuota *$installmentNumber$statusText* por *Bs. ${amount.toStringAsFixed(2)}*.$dueDateText$collectorText\n'
      'Saldo pendiente: *Bs. ${pending.toStringAsFixed(2)}*.\n\n'
      '¡Gracias por su puntualidad con AScobrar!',
    );

    final url = Uri.parse('https://wa.me/$phone?text=$message');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  static Future<void> sharePaymentHistoryViaWhatsApp({
    Client? client,
    Payment? payment,
    required Loan loan,
    required List<Payment> payments,
    String? collectorName,
  }) async {
    final phone = (client?.phone ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    final name = client?.name ?? 'Cliente';
    final totalPaid = payments.fold<double>(0.0, (sum, p) => sum + p.amount);

    final finalCollectorName = await _resolveCollectorName(
        payments.isNotEmpty ? payments.last : null, collectorName);
    final collectorText = '\nCobrador: $finalCollectorName\n';

    final buffer = StringBuffer();
    buffer.writeln('Hola *$name* 👋\n');
    buffer.writeln('Aquí tiene el resumen de sus pagos registrados:$collectorText');
    for (var p in payments) {
      final date = DateFormat('dd/MM/yyyy HH:mm').format(p.paidAt);
      buffer.writeln('• $date - *Bs. ${p.amount.toStringAsFixed(2)}* (Saldo: Bs. ${p.pendingAfter.toStringAsFixed(2)})');
    }
    buffer.writeln('\n*Total amortizado:* Bs. ${totalPaid.toStringAsFixed(2)}');
    buffer.writeln('*Saldo restante:* Bs. ${loan.pendingAmount.toStringAsFixed(2)}\n');
    buffer.writeln('¡Gracias por su puntualidad con AScobrar!');

    final url = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(buffer.toString())}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
