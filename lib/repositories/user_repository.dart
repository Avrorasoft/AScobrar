import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/data_service.dart';

abstract class IUserRepository {
  Stream<List<AppUser>> getUsers();
  Stream<List<AppUser>> getCollectors();
  Future<AppUser?> getUserById(String id);
  Future<String> saveUser(AppUser user);
  Future<void> deleteUser(String userId);
}

class UserRepository implements IUserRepository {
  final CollectionReference _usersRef =
      FirebaseFirestore.instance.collection('users');

  @override
  Stream<List<AppUser>> getUsers() {
    return _usersRef.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data() as Map);
        return AppUser.fromMap(data, doc.id);
      }).toList();
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    });
  }

  @override
  Stream<List<AppUser>> getCollectors() {
    return _usersRef
        .where('role', isEqualTo: 'collector')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data() as Map);
        return AppUser.fromMap(data, doc.id);
      }).toList();
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    });
  }

  @override
  Future<AppUser?> getUserById(String id) async {
    try {
      final doc = await _usersRef.doc(id).get();
      if (!doc.exists || doc.data() == null) return null;
      final data = Map<String, dynamic>.from(doc.data() as Map);
      return AppUser.fromMap(data, doc.id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String> saveUser(AppUser user) async {
    final id = user.id.isNotEmpty
        ? user.id
        : 'usr_${DateTime.now().millisecondsSinceEpoch}';
    final toSave = user.copyWith(id: id);

    await _usersRef.doc(id).set(toSave.toMap(), SetOptions(merge: true));
    await DataService.users.put(id, toSave.toMap());
    return id;
  }

  @override
  Future<void> deleteUser(String userId) async {
    try {
      await _usersRef.doc(userId).delete();
    } catch (_) {}
    await DataService.users.delete(userId);
  }
}
