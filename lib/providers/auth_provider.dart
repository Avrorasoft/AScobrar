import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/data_service.dart';

final currentUserProvider = StateNotifierProvider<CurrentUserNotifier, AppUser?>((ref) {
  return CurrentUserNotifier();
});

// Alias para compatibilidad con código que use authStateProvider
final authProvider = currentUserProvider;
final authStateProvider = Provider<AsyncValue<AppUser?>>((ref) {
  final user = ref.watch(currentUserProvider);
  return AsyncValue.data(user);
});

class CurrentUserNotifier extends StateNotifier<AppUser?> {
  CurrentUserNotifier() : super(DataService.getCurrentUserSession());

  Future<bool> login(String phone, String password) async {
    final user = DataService.authenticate(phone: phone, password: password);
    if (user != null) {
      await DataService.saveUserSession(user);
      state = user;
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
