import 'dart:async';
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
  List<Client> _getAllClients() {
    return DataService.allClients();
  }

  @override
  Stream<List<Client>> getClients() async* {
    yield _getAllClients();
    yield* DataService.clients.watch().map((_) => _getAllClients());
  }

  @override
  Stream<List<Client>> getClientsByCollector(String collectorId) async* {
    yield _getAllClients();
    yield* DataService.clients.watch().map((_) => _getAllClients());
  }

  @override
  Future<Client?> getClientById(String id) async {
    final clients = _getAllClients();
    try {
      return clients.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String> createClient(Client client) async {
    final id = client.id.isNotEmpty ? client.id : 'cli_${DateTime.now().millisecondsSinceEpoch}';
    final toSave = client.copyWith(id: id);
    await DataService.clients.put(id, toSave.toMap());
    return id;
  }

  @override
  Future<void> updateClient(Client client) async {
    await DataService.clients.put(client.id, client.toMap());
  }

  @override
  Future<void> deleteClient(String clientId) async {
    await DataService.clients.delete(clientId);
  }
}
