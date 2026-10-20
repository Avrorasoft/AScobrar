import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/client_model.dart';
import '../models/user_model.dart';
import '../repositories/client_repository.dart';
import 'auth_provider.dart';

final clientRepositoryProvider = Provider<IClientRepository>((ref) {
  return ClientRepository();
});

final clientsStreamProvider = StreamProvider<List<Client>>((ref) {
  final user = ref.watch(currentUserProvider);
  final clientRepo = ref.watch(clientRepositoryProvider);

  if (user == null || user.role == UserRole.owner || user.isOwner) {
    return clientRepo.getClients();
  }

  return clientRepo.getClientsByCollector(user.id);
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
      final id = await _clientRepository.createClient(client);
      state = const AsyncValue.data(null);
      return id;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<void> updateClient(Client client) async {
    state = const AsyncValue.loading();
    try {
      await _clientRepository.updateClient(client);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteClient(String clientId) async {
    state = const AsyncValue.loading();
    try {
      await _clientRepository.deleteClient(clientId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final clientControllerProvider =
    StateNotifierProvider<ClientController, AsyncValue<void>>((ref) {
  return ClientController(ref.watch(clientRepositoryProvider));
});
