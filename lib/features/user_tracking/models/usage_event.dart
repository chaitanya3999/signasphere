import 'dart:convert';

enum UsageEventType {
  appOpened,
  usedLiveSign,
  usedAvatar,
  usedConversation,
  usedLearn,
  emergencyOpened,
  quizCompleted;

  String get label {
    switch (this) {
      case UsageEventType.appOpened: return 'App Opened';
      case UsageEventType.usedLiveSign: return 'Live Sign';
      case UsageEventType.usedAvatar: return 'Avatar';
      case UsageEventType.usedConversation: return 'Conversation';
      case UsageEventType.usedLearn: return 'Learn';
      case UsageEventType.emergencyOpened: return 'Emergency';
      case UsageEventType.quizCompleted: return 'Quiz Completed';
    }
  }
}

class UsageEvent {
  final String id;
  final String userId;
  final UsageEventType type;
  final DateTime timestamp;

  const UsageEvent({
    required this.id,
    required this.userId,
    required this.type,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'type': type.name,
    'timestamp': timestamp.toIso8601String(),
  };

  factory UsageEvent.fromJson(Map<String, dynamic> json) => UsageEvent(
    id: json['id'] as String,
    userId: json['userId'] as String,
    type: UsageEventType.values.firstWhere((e) => e.name == json['type']),
    timestamp: DateTime.parse(json['timestamp'] as String),
  );

  static String encodeList(List<UsageEvent> events) =>
      jsonEncode(events.map((e) => e.toJson()).toList());

  static List<UsageEvent> decodeList(String jsonStr) {
    final List<dynamic> list = jsonDecode(jsonStr);
    return list.map((e) => UsageEvent.fromJson(e as Map<String, dynamic>)).toList();
  }
}
