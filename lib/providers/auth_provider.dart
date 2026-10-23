import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/data_service.dart';

final currentUserProvider =
    StateNotifierProvider<CurrentUserNotifier, AppUser?>((ref) {
  return CurrentUserNotifier();
});

final authProvider = currentUserProvider;
final authStateProvider = Provider<AsyncValue<AppUser?>>((ref) {
  final user = ref.watch(currentUserProvider);
  return AsyncValue.data(user);
});

final allUsersStreamProvider = StreamProvider<List<AppUser>>((ref) {
  return FirebaseFirestore.instance.collection('users').snapshots().map((snap) {
    return snap.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      return AppUser.fromMap(data, doc.id);
    }).toList();
  });
});

final collectorsStreamProvider = StreamProvider<List<AppUser>>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: 'collector')
      .snapshots()
      .map((snap) {
    return snap.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      return AppUser.fromMap(data, doc.id);
    }).toList();
  });
});

class CurrentUserNotifier extends StateNotifier<AppUser?> {
  CurrentUserNotifier() : super(DataService.getCurrentUserSession());

  Future<bool> login(String phone, String password) async {
    final cleanPhone = phone.trim();
    final cleanPass = password.trim();

    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: cleanPhone)
          .where('password', isEqualTo: cleanPass)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final data = Map<String, dynamic>.from(doc.data());
        final user = AppUser.fromMap(data, doc.id);

        await DataService.saveUserSession(user);
        final toSave = user.toMap();
        toSave['password'] = cleanPass;
        await DataService.users.put(user.id, toSave);
        state = user;
        return true;
      }
    } catch (_) {}

    final localUser = await DataService.authenticate(phone: cleanPhone, password: cleanPass);
    if (localUser != null) {
      await DataService.saveUserSession(localUser);
      state = localUser;
      return true;
    }

    return false;
  }

  Future<void> logout() async {
    await DataService.clearUserSession();
    state = null;
  }

  void reloadSession() {
    state = DataService.getCurrentUserSession();
  }
}
