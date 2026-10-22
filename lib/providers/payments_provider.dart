import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/payment_model.dart';
import '../services/data_service.dart';

final paymentsStreamProvider = StreamProvider<List<Payment>>((ref) {
  return FirebaseFirestore.instance
      .collection('payments')
      .snapshots()
      .map((snapshot) {
    final list = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Payment.fromMap(data);
    }).toList();

    // Sincronizar en segundo plano con Hive local
    for (final p in list) {
      DataService.payments.put(p.id, p.toMap());
    }

    list.sort((a, b) => b.paidAt.compareTo(a.paidAt));
    return list;
  });
});
