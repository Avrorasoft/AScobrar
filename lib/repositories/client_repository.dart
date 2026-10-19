import 'dart:async';
import '../models/client_model.dart';
import '../services/data_service.dart';

abstract class IClientRepository {
  Stream<List<Client>> watchClients();
  Stream<List<Client>> get clientsStream;
  Stream<List<Client>> searchClients(String query);
  Future<Client?> getClient(String clientId);
  Future<Client?> getClientById(String clientId);
  Future<String> createClient(Client client);
  Future<void> updateClient(Client client);
  Future<void> deleteClient(String clientId);
  Stream<List<Client>> getClients();
  Stream<List<Client>> getClientsByCollector(String collectorId);
}

class ClientRepository implements IClientRepository {
  final _clientsStreamController = StreamController<List<Client>>.broadcast();

  ClientRepository() {
    _refreshStream();
  }

  void _refreshStream() {
    _clientsStreamController.add(DataService.allClients());
  }

  @override
  Stream<List<Client>> watchClients() {
    return _clientsStreamController.stream;
  }

  @override
  Stream<List<Client>> get clientsStream async* {
    yield DataService.allClients();
    yield* _clientsStreamController.stream;
  }

  @override
  Stream<List<Client>> searchClients(String query) async* {
    final all = DataService.allClients();
    if (query.trim().isEmpty) {
      yield all;
    } else {
      final q = query.toLowerCase();
      yield all.where((c) =>
          c.name.toLowerCase().contains(q) ||
          c.documentId.toLowerCase().contains(q) ||
          c.phone.contains(q) ||
          c.phoneSecondary.contains(q) ||
          c.neighborhood.toLowerCase().contains(q) ||
          c.business.toLowerCase().contains(q)
      ).toList();
    }
  }

  @override
  Future<Client?> getClient(String clientId) async {
    return DataService.getClient(clientId);
  }

  @override
  Future<Client?> getClientById(String clientId) async {
    return DataService.getClient(clientId);
  }

  @override
  Future<String> createClient(Client client) async {
    final id = await DataService.createClient(
      name: client.name,
      documentId: client.documentId,
      phone: client.phone,
      phoneSecondary: client.phoneSecondary,
      street: client.street,
      neighborhood: client.neighborhood,
      address: client.address,
      business: client.business,
    );
    _refreshStream();
    return id;
  }

  @override
  Future<void> updateClient(Client client) async {
    await DataService.updateClient(client);
    _refreshStream();
  }

  @override
  Future<void> deleteClient(String clientId) async {
    await DataService.clients.delete(clientId);
    _refreshStream();
  }

  @override
  Stream<List<Client>> getClients() async* {
    yield DataService.allClients();
    yield* _clientsStreamController.stream;
  }

  @override
  Stream<List<Client>> getClientsByCollector(String collectorId) async* {
    yield DataService.allClients();
    yield* _clientsStreamController.stream;
  }
}
