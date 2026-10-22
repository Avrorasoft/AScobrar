import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/loan_model.dart';
import '../models/payment_model.dart';
import '../services/data_service.dart';

abstract class ILoanRepository {
  Stream<List<Loan>> getLoans();
  Stream<List<Loan>> getLoansByCollector(String collectorId);
  Stream<List<Loan>> getLoansByClient(String clientId);
  Future<Loan?> getLoanById(String id);
  Future<String> createLoan(Loan loan, [dynamic cuotas]);
  Future<void> updateLoan(Loan loan);
  Future<void> deleteLoan(String loanId);
}

class LoanRepository implements ILoanRepository {
  final CollectionReference _loansRef =
      FirebaseFirestore.instance.collection('loans');
  final CollectionReference _paymentsRef =
      FirebaseFirestore.instance.collection('payments');

  @override
  Stream<List<Loan>> getLoans() {
    return _loansRef.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data() as Map);
        data['id'] = doc.id;
        return Loan.fromMap(data);
      }).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  @override
  Stream<List<Loan>> getLoansByCollector(String collectorId) {
    return getLoans();
  }

  @override
  Stream<List<Loan>> getLoansByClient(String clientId) {
    return _loansRef
        .where('clientId', isEqualTo: clientId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data() as Map);
        data['id'] = doc.id;
        return Loan.fromMap(data);
      }).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  @override
  Future<Loan?> getLoanById(String id) async {
    try {
      final doc = await _loansRef.doc(id).get();
      if (!doc.exists || doc.data() == null) return null;
      final data = Map<String, dynamic>.from(doc.data() as Map);
      data['id'] = doc.id;
      return Loan.fromMap(data);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String> createLoan(Loan loan, [dynamic cuotas]) async {
    final id = loan.id.isNotEmpty
        ? loan.id
        : 'loan_${DateTime.now().millisecondsSinceEpoch}';
    final toSave = loan.copyWith(id: id);
    await _loansRef.doc(id).set(toSave.toMap(), SetOptions(merge: true));
    await DataService.loans.put(id, toSave.toMap());
    return id;
  }

  @override
  Future<void> updateLoan(Loan loan) async {
    await _loansRef.doc(loan.id).set(loan.toMap(), SetOptions(merge: true));
    await DataService.loans.put(loan.id, loan.toMap());
  }

  @override
  Future<void> deleteLoan(String loanId) async {
    final batch = FirebaseFirestore.instance.batch();
    batch.delete(_loansRef.doc(loanId));

    try {
      final paymentsSnap =
          await _paymentsRef.where('loanId', isEqualTo: loanId).get();
      for (final doc in paymentsSnap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (_) {
      await _loansRef.doc(loanId).delete();
    }

    await DataService.loans.delete(loanId);
    final pList = DataService.paymentsOfLoan(loanId);
    for (final p in pList) {
      await DataService.payments.delete(p.id);
    }
  }
}
