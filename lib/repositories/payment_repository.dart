import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_model.dart';

abstract class IPaymentRepository {
  Stream<List<Payment>> getPaymentsByLoan(String loanId);
  Stream<List<Payment>> getPaymentsByCollectorToday(String collectorId);
  Future<String> registerPayment({
    required Payment payment,
    required double newLoanBalance,
    required int updatedPaidInstallments,
    required List<int> affectedInstallmentNumbers,
  });
}

class PaymentRepository implements IPaymentRepository {
  final FirebaseFirestore _firestore;

  PaymentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _paymentsRef =>
      _firestore.collection('payments');

  @override
  Stream<List<Payment>> getPaymentsByLoan(String loanId) {
    return _paymentsRef
        .where('loanId', isEqualTo: loanId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map<Payment>((doc) {
              final Map<String, dynamic> data = Map<String, dynamic>.from(doc.data());
              data['id'] = doc.id;
              return Payment.fromMap(data);
            }).toList());
  }

  @override
  Stream<List<Payment>> getPaymentsByCollectorToday(String collectorId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return _paymentsRef
        .where('collectorId', isEqualTo: collectorId)
        .where('paidAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('paidAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((snapshot) => snapshot.docs.map<Payment>((doc) {
              final Map<String, dynamic> data = Map<String, dynamic>.from(doc.data());
              data['id'] = doc.id;
              return Payment.fromMap(data);
            }).toList());
  }

  @override
  Future<String> registerPayment({
    required Payment payment,
    required double newLoanBalance,
    required int updatedPaidInstallments,
    required List<int> affectedInstallmentNumbers,
  }) async {
    return await _firestore.runTransaction((transaction) async {
      final paymentDocRef = _paymentsRef.doc();
      final loanDocRef = _firestore.collection('loans').doc(payment.loanId);

      final paymentData = payment.toMap();
      paymentData['id'] = paymentDocRef.id;
      transaction.set(paymentDocRef, paymentData);

      transaction.update(loanDocRef, {
        'pendingAmount': newLoanBalance,
        'paidInstallments': updatedPaidInstallments,
        if (newLoanBalance <= 0) 'status': 'completed',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      for (final installmentNumber in affectedInstallmentNumbers) {
        final installmentRef =
            loanDocRef.collection('installments').doc('$installmentNumber');
        transaction.update(installmentRef, {
          'status': 'paid',
          'paidAt': Timestamp.fromDate(payment.paidAt),
          'paymentId': paymentDocRef.id,
        });
      }

      return paymentDocRef.id;
    });
  }
}
