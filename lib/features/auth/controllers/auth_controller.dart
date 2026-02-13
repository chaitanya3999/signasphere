import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_controller.dart';
import '../data/auth_repository.dart';
import '../models/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  return AuthRepository(prefs);
});

final authControllerProvider =
    AsyncNotifierProvider<AuthController, UserModel?>(AuthController.new);

class AuthController extends AsyncNotifier<UserModel?> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  Future<UserModel?> build() async {
    return _repo.getCurrentUser();
  }

  bool get isLoggedIn => _repo.isLoggedIn();

  Future<void> loadSession() async {
    state = AsyncData(_repo.getCurrentUser());
  }

  Future<String?> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      final user = await _repo.loginUser(email, password);
      state = AsyncData(user);
      return null; // success
    } catch (e) {
      state = const AsyncData(null);
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<String?> register(String fullName, String email, String password) async {
    state = const AsyncLoading();
    try {
      final user = await _repo.registerUser(fullName, email, password);
      state = AsyncData(user);
      return null; // success
    } catch (e) {
      state = const AsyncData(null);
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AsyncData(null);
  }

  Future<void> deleteAccount() async {
    final user = state.valueOrNull;
    if (user != null) {
      await _repo.deleteAccount(user.id);
    }
    state = const AsyncData(null);
  }
}
