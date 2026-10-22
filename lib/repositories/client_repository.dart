import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/client_model.dart';
import '../services/data_service.dart';

abstract class IClientRepository {
  Stream<List<Client>> getClients();
  Stream<List<Client>> getClientsByCollector(String collectorId);
  Future<Client?> getClientById(String id);
  Future<String> createClient(Client client);
  Future<void> updateClient(Client client);
  Future<void> deleteClient(String clientId);
}

class ClientRepository implements IClientRepository {
  final CollectionReference _clientsRef =
      FirebaseFirestore.instance.collection('clients');
  final CollectionReference _loansRef =
      FirebaseFirestore.instance.collection('loans');
  final CollectionReference _paymentsRef =
      FirebaseFirestore.instance.collection('payments');

  @override
  Stream<List<Client>> getClients() {
    return _clientsRef.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data() as Map);
        data['id'] = doc.id;
        return Client.fromMap(data);
      }).toList();
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    });
  }

  @override
  Stream<List<Client>> getClientsByCollector(String collectorId) {
    // Escucha en tiempo real todos los clientes de la ruta compartida
    return getClients();
  }

  @override
  Future<Client?> getClientById(String id) async {
    try {
      final doc = await _clientsRef.doc(id).get();
      if (!doc.exists || doc.data() == null) return null;
      final data = Map<String, dynamic>.from(doc.data() as Map);
      data['id'] = doc.id;
      return Client.fromMap(data);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String> createClient(Client client) async {
    final id = client.id.isNotEmpty
        ? client.id
        : 'cli_${DateTime.now().millisecondsSinceEpoch}';
    final toSave = client.copyWith(id: id);
    await _clientsRef.doc(id).set(toSave.toMap(), SetOptions(merge: true));

    // Mantener sincronizado local en DataService para compatibilidad
    await DataService.clients.put(id, toSave.toMap());
    return id;
  }

  @override
  Future<void> updateClient(Client client) async {
    await _clientsRef.doc(client.id).set(client.toMap(), SetOptions(merge: true));
    await DataService.clients.put(client.id, client.toMap());
  }

  @override
  Future<void> deleteClient(String clientId) async {
    final batch = FirebaseFirestore.instance.batch();

    // 1. Marcar para borrar documento del cliente
    batch.delete(_clientsRef.doc(clientId));

    // 2. Buscar y borrar en cascada sus prestamos en Firestore
    try {
      final loansSnap =
          await _loansRef.where('clientId', isEqualTo: clientId).get();
      for (final doc in loansSnap.docs) {
        // Borrar pagos de cada prestamo
        final paymentsSnap =
            await _paymentsRef.where('loanId', isEqualTo: doc.id).get();
        for (final pDoc in paymentsSnap.docs) {
          batch.delete(pDoc.reference);
        }
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      // Si falla lote masivo o se encuentra offline, borra individualmente
      await _clientsRef.doc(clientId).delete();
    }

    // 3. Limpieza local en Hive
    await DataService.clients.delete(clientId);
    final clientLoans = DataService.loansOfClient(clientId);
    for (final loan in clientLoans) {
      await DataService.loans.delete(loan.id);
    }
  }
}
