import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/payment_model.dart';
import '../services/data_service.dart';

final paymentsStreamProvider = StreamProvider<List<Payment>>((ref) {
  return FirebaseFirestore.instance
      .collection('payments')
      .snapshots()
      .map((snapshot) {
    final List<Payment> list = [];
    for (final doc in snapshot.docs) {
      try {
        final data = doc.data();
        data['id'] = doc.id;
        final p = Payment.fromMap(data);
        list.add(p);
        DataService.payments.put(p.id, p.toMap());
      } catch (e) {
        debugPrint('Error parseando pago ${doc.id}: $e');
      }
    }
    list.sort((a, b) => b.paidAt.compareTo(a.paidAt));
    return list;
  });
});
