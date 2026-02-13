import 'dart:convert';

enum ContactCategory {
  family,
  friend,
  doctor,
  custom;

  String get label {
    switch (this) {
      case ContactCategory.family:
        return 'Family';
      case ContactCategory.friend:
        return 'Friend';
      case ContactCategory.doctor:
        return 'Doctor';
      case ContactCategory.custom:
        return 'Custom';
    }
  }

  static ContactCategory fromString(String value) {
    return ContactCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ContactCategory.custom,
    );
  }
}

class EmergencyContact {
  final String id;
  final String name;
  final String phone;
  final ContactCategory category;

  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.category,
  });

  EmergencyContact copyWith({
    String? id,
    String? name,
    String? phone,
    ContactCategory? category,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'category': category.name,
    };
  }

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      category: ContactCategory.fromString(json['category'] as String),
    );
  }

  static String encodeList(List<EmergencyContact> contacts) {
    return jsonEncode(contacts.map((c) => c.toJson()).toList());
  }

  static List<EmergencyContact> decodeList(String jsonStr) {
    final List<dynamic> list = jsonDecode(jsonStr);
    return list.map((e) => EmergencyContact.fromJson(e as Map<String, dynamic>)).toList();
  }
}
