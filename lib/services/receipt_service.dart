import 'package:intl/intl.dart';
import '../models/client_model.dart';
import '../models/loan_model.dart';
import '../models/payment_model.dart';
import '../models/user_model.dart';
import 'config_service.dart';
import 'data_service.dart';

class ReceiptService {
  ReceiptService._();

  static String generatePaymentReceiptText({
    required Payment payment,
    required Loan loan,
    required Client client,
  }) {
    final company = ConfigService.companyName;
    final currency = ConfigService.currency;
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(payment.paidAt.toLocal());

    // Identificación estricta del cobrador responsable
    String collectorName = 'Cobrador Autorizado';
    String collectorPhone = '';

    final collectors = DataService.allCollectors();
    final match = collectors.where((c) => c.id == payment.collectorId).toList();
    if (match.isNotEmpty) {
      collectorName = match.first.name;
      collectorPhone = match.first.phone;
    } else if (payment.collectorId == 'admin_default') {
      collectorName = 'Administración Central';
    }

    final isCash = payment.method == PaymentMethod.cash;
    final methodStr = isCash ? 'Efectivo en Mano' : 'Transferencia Bancaria / QR';

    return '''
================================
  $company
  COMPROBANTE OFICIAL DE PAGO
================================
Recibo N°: ${payment.id}
Fecha/Hora: $dateStr

DATOS DEL CLIENTE:
Cliente: ${client.name}
CI/NIT: ${client.documentId}
Teléfono: ${client.phone}

DETALLE DEL COBRO:
Monto Cobrado: $currency ${payment.amount.round()}
Forma de Pago: $methodStr
${payment.transactionId != null && payment.transactionId!.isNotEmpty ? 'N° Transacción/Ref: ${payment.transactionId}\n' : ''}Saldo Restante: $currency ${payment.pendingAfter.round()}

AUDITORÍA DE RUTA:
Cobrado por: $collectorName
${collectorPhone.isNotEmpty ? 'Tel. Cobrador: $collectorPhone\n' : ''}Operador ID: ${payment.collectorId}
Estado: Registrado en Sistema
================================
''';
  }
}
