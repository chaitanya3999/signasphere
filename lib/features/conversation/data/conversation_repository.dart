import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/theme_controller.dart';

// Key for storing messages
const String _kMessagesKey = 'conversation_history';

final conversationRepositoryProvider = Provider<ConversationRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ConversationRepository(prefs);
});



class ChatMessage {
  final String id;
  final String text;
  final bool isMe;
  final DateTime timestamp;
  final bool isTyping;
  final String role; // "user" | "assistant"
  final String source; // "gemini" | "local"
  final String status; // "sent" | "error" | "sending"

  ChatMessage({
    required this.id,
    required this.text,
    required this.isMe,
    required this.timestamp,
    this.isTyping = false,
    String? role,
    this.source = 'local',
    this.status = 'sent',
  }) : role = role ?? (isMe ? 'user' : 'assistant');

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isMe': isMe,
      'timestamp': timestamp.toIso8601String(),
      'isTyping': isTyping,
      'role': role,
      'source': source,
      'status': status,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      text: json['text'],
      isMe: json['isMe'],
      timestamp: DateTime.parse(json['timestamp']),
      isTyping: json['isTyping'] ?? false,
      role: json['role'],
      source: json['source'] ?? 'local',
      status: json['status'] ?? 'sent',
    );
  }

  ChatMessage copyWith({
    String? text,
    String? status,
  }) {
    return ChatMessage(
      id: id,
      text: text ?? this.text,
      isMe: isMe,
      timestamp: timestamp,
      isTyping: isTyping,
      role: role,
      source: source,
      status: status ?? this.status,
    );
  }
}

class ConversationRepository {
  final SharedPreferences _prefs;

  ConversationRepository(this._prefs);

  List<ChatMessage> getMessages() {
    final jsonString = _prefs.getString(_kMessagesKey);
    if (jsonString == null) return [];
    
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => ChatMessage.fromJson(json)).toList();
  }

  Future<void> saveMessage(ChatMessage message) async {
    final messages = getMessages();
    messages.add(message);
    
    // Keep only last 50 messages
    if (messages.length > 50) {
      messages.removeRange(0, messages.length - 50);
    }
    
    await _saveList(messages);
  }

  Future<void> saveMessages(List<ChatMessage> messages) async {
     // Keep only last 50 messages
    if (messages.length > 50) {
      messages.removeRange(0, messages.length - 50);
    }
    await _saveList(messages);
  }

  Future<void> clearHistory() async {
    await _prefs.remove(_kMessagesKey);
  }

  Future<void> _saveList(List<ChatMessage> messages) async {
    final jsonList = messages.map((m) => m.toJson()).toList();
    await _prefs.setString(_kMessagesKey, jsonEncode(jsonList));
  }
}
