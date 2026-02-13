import 'dart:convert';
import 'dart:math';

class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String passwordHash;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final int avatarColor;
  final bool isPremium;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.passwordHash,
    required this.createdAt,
    required this.lastLoginAt,
    required this.avatarColor,
    this.isPremium = false,
  });

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }

  String get firstName => fullName.trim().split(' ').first;

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? passwordHash,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    int? avatarColor,
    bool? isPremium,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      avatarColor: avatarColor ?? this.avatarColor,
      isPremium: isPremium ?? this.isPremium,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'passwordHash': passwordHash,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'avatarColor': avatarColor,
      'isPremium': isPremium,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      passwordHash: json['passwordHash'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLoginAt: DateTime.parse(json['lastLoginAt'] as String),
      avatarColor: json['avatarColor'] as int,
      isPremium: json['isPremium'] as bool? ?? false,
    );
  }

  static int generateAvatarColor() {
    final colors = [
      0xFF6C63FF, 0xFF00D2D3, 0xFFE53935, 0xFFFF8F00,
      0xFF43A047, 0xFFE91E63, 0xFF1E88E5, 0xFF8E24AA,
      0xFFFF7043, 0xFF26A69A,
    ];
    return colors[Random().nextInt(colors.length)];
  }

  static String encodeList(List<UserModel> users) {
    return jsonEncode(users.map((u) => u.toJson()).toList());
  }

  static List<UserModel> decodeList(String jsonStr) {
    final List<dynamic> list = jsonDecode(jsonStr);
    return list.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
