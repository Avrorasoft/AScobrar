import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_model.dart';
import '../models/loan_model.dart';
import '../services/data_service.dart';

abstract class IPaymentRepository {
  Stream<List<Payment>> getPayments();
  Stream<List<Payment>> getPaymentsByCollector(String collectorId);
  Future<List<Payment>> getPaymentsOfLoan(String loanId);
  Future<List<Payment>> getPaymentsOfClient(String clientId);
  Future<String> registerPayment(Payment payment);
  Future<void> deletePayment(String paymentId);
}

class PaymentRepository implements IPaymentRepository {
  final CollectionReference _paymentsRef =
      FirebaseFirestore.instance.collection('payments');
  final CollectionReference _loansRef =
      FirebaseFirestore.instance.collection('loans');

  @override
  Stream<List<Payment>> getPayments() {
    return _paymentsRef.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data() as Map);
        data['id'] = doc.id;
        return Payment.fromMap(data);
      }).toList();
      list.sort((a, b) => b.paidAt.compareTo(a.paidAt));
      return list;
    });
  }

  @override
  Stream<List<Payment>> getPaymentsByCollector(String collectorId) {
    return _paymentsRef.snapshots().map((snapshot) {
      final all = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data() as Map);
        data['id'] = doc.id;
        return Payment.fromMap(data);
      }).toList();

      final list = all.where((p) {
        return p.collectorId == collectorId ||
            p.collectorId.isEmpty ||
            p.collectorId == 'admin_default' ||
            (collectorId == 'collector_default' && p.collectorId == '70000002') ||
            (collectorId == '70000002' && p.collectorId == 'collector_default');
      }).toList();

      list.sort((a, b) => b.paidAt.compareTo(a.paidAt));
      return list;
    });
  }

  @override
  Future<List<Payment>> getPaymentsOfLoan(String loanId) async {
    try {
      final snap = await _paymentsRef.where('loanId', isEqualTo: loanId).get();
      final list = snap.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data() as Map);
        data['id'] = doc.id;
        return Payment.fromMap(data);
      }).toList();
      list.sort((a, b) => b.paidAt.compareTo(a.paidAt));
      return list;
    } catch (_) {
      return DataService.paymentsOfLoan(loanId);
    }
  }

  @override
  Future<List<Payment>> getPaymentsOfClient(String clientId) async {
    try {
      final snap = await _paymentsRef.where('clientId', isEqualTo: clientId).get();
      final list = snap.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data() as Map);
        data['id'] = doc.id;
        return Payment.fromMap(data);
      }).toList();
      list.sort((a, b) => b.paidAt.compareTo(a.paidAt));
      return list;
    } catch (_) {
      return DataService.paymentsOfClient(clientId);
    }
  }

  @override
  Future<String> registerPayment(Payment payment) async {
    final id = payment.id.isNotEmpty
        ? payment.id
        : 'pay_${DateTime.now().millisecondsSinceEpoch}';
    final toSave = payment.copyWith(id: id);

    await _paymentsRef.doc(id).set(toSave.toMap(), SetOptions(merge: true));

    // Actualizar saldo del prestamo en Firestore
    try {
      final loanDoc = await _loansRef.doc(payment.loanId).get();
      if (loanDoc.exists && loanDoc.data() != null) {
        final loanData = Map<String, dynamic>.from(loanDoc.data() as Map);
        final currentPending = (loanData['pendingAmount'] as num?)?.toDouble() ?? 0.0;
        final currentPaidCount = (loanData['paidInstallments'] as int?) ?? 0;
        final newPending = (currentPending - payment.amount).clamp(0.0, double.infinity);

        await _loansRef.doc(payment.loanId).update({
          'pendingAmount': newPending,
          'paidInstallments': currentPaidCount + payment.installmentsCovered,
          if (newPending <= 0.0) 'status': 'paid',
        });
      }
    } catch (_) {}

    // Respaldo local en Hive
    await DataService.registerPayment(toSave);
    return id;
  }

  @override
  Future<void> deletePayment(String paymentId) async {
    String? loanId;
    try {
      final doc = await _paymentsRef.doc(paymentId).get();
      if (doc.exists && doc.data() != null) {
        loanId = (doc.data() as Map)['loanId']?.toString();
      }
      await _paymentsRef.doc(paymentId).delete();
    } catch (_) {}

    await DataService.deletePayment(paymentId);

    if (loanId != null) {
      // Re-sincronizar balances financieros
      final snap = await _paymentsRef.where('loanId', isEqualTo: loanId).get();
      double totalPaid = 0.0;
      int covered = 0;
      for (final d in snap.docs) {
        final dMap = Map<String, dynamic>.from(d.data() as Map);
        totalPaid += (dMap['amount'] as num?)?.toDouble() ?? 0.0;
        covered += (dMap['installmentsCovered'] as int?) ?? 0;
      }
      try {
        final lDoc = await _loansRef.doc(loanId).get();
        if (lDoc.exists && lDoc.data() != null) {
          final l = Loan.fromMap(Map<String, dynamic>.from(lDoc.data() as Map));
          final totalCredit = l.principal * (1.0 + (l.interestRate / 100.0));
          final newPending = (totalCredit - totalPaid).clamp(0.0, double.infinity);
          await _loansRef.doc(loanId).update({
            'pendingAmount': newPending,
            'paidInstallments': covered,
            'status': newPending <= 0.0 ? 'paid' : 'active',
          });
        }
      } catch (_) {}
    }
  }
}
