import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/data_structures/ds_manager.dart';

const String _kMessagesKey = 'conversation_history';
const String _kCompressedKey = 'conversation_compressed';

final conversationRepositoryProvider = Provider<ConversationRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final huffman = ref.watch(huffmanProvider);
  return ConversationRepository(prefs, huffman);
});

class ChatMessage {
  final String id;
  final String text;
  final bool isMe;
  final DateTime timestamp;
  final bool isTyping;
  final String role;
  final String source;
  final String status;

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

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'isMe': isMe,
    'timestamp': timestamp.toIso8601String(),
    'isTyping': isTyping,
    'role': role,
    'source': source,
    'status': status,
  };

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

  ChatMessage copyWith({String? text, String? status}) {
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

// HUFFMAN CODING: Chat Compression
// Huffman Coding provides optimal lossless compression

class ConversationRepository {
  final SharedPreferences _prefs;
  final HuffmanCoding _huffman;

  ConversationRepository(this._prefs, this._huffman);

  List<ChatMessage> getMessages() {
    // Try compressed first
    final compressed = _prefs.getString(_kCompressedKey);
    if (compressed != null) {
      final jsonStr = _huffman.decompressFromJson(compressed);
      if (jsonStr != null) {
        final List<dynamic> jsonList = jsonDecode(jsonStr);
        print(
          '[DS:ConvRepo] Loaded ${jsonList.length} messages (Huffman decompressed)',
        );
        return jsonList.map((j) => ChatMessage.fromJson(j)).toList();
      }
    }

    // Fallback to uncompressed
    final jsonString = _prefs.getString(_kMessagesKey);
    if (jsonString == null) return [];
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => ChatMessage.fromJson(json)).toList();
  }

  Future<void> saveMessage(ChatMessage message) async {
    final messages = getMessages();
    messages.add(message);
    if (messages.length > 50) {
      messages.removeRange(0, messages.length - 50);
    }
    await _saveList(messages);
  }

  Future<void> saveMessages(List<ChatMessage> messages) async {
    if (messages.length > 50) {
      messages.removeRange(0, messages.length - 50);
    }
    await _saveList(messages);
  }

  Future<void> clearHistory() async {
    await _prefs.remove(_kMessagesKey);
    await _prefs.remove(_kCompressedKey);
  }

  Future<void> _saveList(List<ChatMessage> messages) async {
    final jsonList = messages.map((m) => m.toJson()).toList();
    final jsonStr = jsonEncode(jsonList);

    // Save uncompressed (backward compat)
    await _prefs.setString(_kMessagesKey, jsonStr);

    // Also save Huffman compressed version
    final compressed = _huffman.compressToJson(jsonStr);
    if (compressed != null) {
      await _prefs.setString(_kCompressedKey, compressed);
      print(
        '[DS:ConvRepo] Saved ${messages.length} messages '
        '(raw=${jsonStr.length} chars, compressed stored)',
      );
    }
  }
}
