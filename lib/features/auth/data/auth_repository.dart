import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthRepository {
  static const String _kUsersKey = 'users_list';
  static const String _kSessionKey = 'logged_in_user';

  final SharedPreferences _prefs;

  AuthRepository(this._prefs);

  // ── Helpers ──

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  List<UserModel> getAllUsers() {
    final jsonStr = _prefs.getString(_kUsersKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    return UserModel.decodeList(jsonStr);
  }

  Future<void> _saveUsers(List<UserModel> users) async {
    await _prefs.setString(_kUsersKey, UserModel.encodeList(users));
  }

  // ── Public API ──

  bool isLoggedIn() {
    final userId = _prefs.getString(_kSessionKey);
    return userId != null && userId.isNotEmpty;
  }

  UserModel? getCurrentUser() {
    final userId = _prefs.getString(_kSessionKey);
    if (userId == null || userId.isEmpty) return null;
    final users = getAllUsers();
    try {
      return users.firstWhere((u) => u.id == userId);
    } catch (_) {
      return null;
    }
  }

  Future<UserModel> registerUser(String fullName, String email, String password) async {
    final users = getAllUsers();

    // Check duplicate email
    final exists = users.any((u) => u.email.toLowerCase() == email.toLowerCase());
    if (exists) {
      throw Exception('An account with this email already exists');
    }

    final now = DateTime.now();
    final user = UserModel(
      id: now.millisecondsSinceEpoch.toString(),
      fullName: fullName,
      email: email.toLowerCase().trim(),
      passwordHash: _hashPassword(password),
      createdAt: now,
      lastLoginAt: now,
      avatarColor: UserModel.generateAvatarColor(),
    );

    users.add(user);
    await _saveUsers(users);
    await _prefs.setString(_kSessionKey, user.id);
    return user;
  }

  Future<UserModel> loginUser(String email, String password) async {
    final users = getAllUsers();
    final hash = _hashPassword(password);

    final matches = users.where(
      (u) => u.email.toLowerCase() == email.toLowerCase().trim() && u.passwordHash == hash,
    );

    if (matches.isEmpty) {
      throw Exception('Invalid email or password');
    }

    final user = matches.first.copyWith(lastLoginAt: DateTime.now());

    // Update lastLoginAt
    final idx = users.indexWhere((u) => u.id == user.id);
    users[idx] = user;
    await _saveUsers(users);
    await _prefs.setString(_kSessionKey, user.id);
    return user;
  }

  Future<void> logout() async {
    await _prefs.remove(_kSessionKey);
  }

  Future<void> deleteAccount(String userId) async {
    final users = getAllUsers();
    users.removeWhere((u) => u.id == userId);
    await _saveUsers(users);
    await _prefs.remove(_kSessionKey);

    // Clean up user-specific data
    final keys = _prefs.getKeys().where((k) => k.contains(userId));
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }
}
