import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/client_model.dart';
import '../repositories/client_repository.dart';
import '../services/data_service.dart';

final clientRepositoryProvider = Provider<IClientRepository>((ref) {
  return ClientRepository();
});

final clientsStreamProvider = StreamProvider<List<Client>>((ref) {
  return FirebaseFirestore.instance
      .collection('clients')
      .snapshots()
      .map((snapshot) {
    final list = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Client.fromMap(data);
    }).toList();

    // Sincronizar en segundo plano con Hive local
    for (final c in list) {
      DataService.clients.put(c.id, c.toMap());
    }

    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  });
});

final clientsProvider = clientsStreamProvider;

final clientByIdProvider = FutureProvider.family<Client?, String>((ref, id) {
  final clientRepo = ref.watch(clientRepositoryProvider);
  return clientRepo.getClientById(id);
});
final clientProvider = clientByIdProvider;

class ClientController extends StateNotifier<AsyncValue<void>> {
  final IClientRepository _clientRepository;

  ClientController(this._clientRepository) : super(const AsyncValue.data(null));

  Future<String?> createClient(Client client) async {
    state = const AsyncValue.loading();
    try {
      final clientId = await _clientRepository.createClient(client);
      state = const AsyncValue.data(null);
      return clientId;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return null;
    }
  }

  Future<void> updateClient(Client client) async {
    state = const AsyncValue.loading();
    try {
      await _clientRepository.updateClient(client);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

final clientControllerProvider =
    StateNotifierProvider<ClientController, AsyncValue<void>>((ref) {
  return ClientController(ref.watch(clientRepositoryProvider));
});
