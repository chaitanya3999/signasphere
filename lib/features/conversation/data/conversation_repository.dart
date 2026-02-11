import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final conversationRepositoryProvider = Provider<ConversationRepository>((ref) => MockConversationRepository());

final conversationStreamProvider = StreamProvider<List<ChatMessage>>((ref) {
  return ref.read(conversationRepositoryProvider).getMessages();
});

class ChatMessage {
  final String id;
  final String text;
  final bool isMe;
  final DateTime timestamp;
  final bool isTyping; // For typing indicators

  ChatMessage({
    required this.id,
    required this.text,
    required this.isMe,
    required this.timestamp,
    this.isTyping = false,
  });
}

abstract class ConversationRepository {
  Stream<List<ChatMessage>> getMessages();
  Future<void> sendMessage(String text);
}

class MockConversationRepository implements ConversationRepository {
  final _controller = StreamController<List<ChatMessage>>.broadcast();
  final List<ChatMessage> _messages = [
    ChatMessage(
      id: '1',
      text: "Hi! I wanted to ask about the appointment.",
      isMe: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
  ];

  MockConversationRepository() {
    _emit();
  }

  void _emit() {
    _controller.add(List.from(_messages));
  }

  @override
  Stream<List<ChatMessage>> getMessages() {
    return _controller.stream;
  }

  @override
  Future<void> sendMessage(String text) async {
    // 1. Add User Message
    _messages.add(ChatMessage(
      id: DateTime.now().toString(),
      text: text,
      isMe: true,
      timestamp: DateTime.now(),
    ));
    _emit();

    // 2. Simulate "Partner Typing"
    await Future.delayed(const Duration(milliseconds: 500));
    final typingMsg = ChatMessage(id: 'typing', text: '...', isMe: false, timestamp: DateTime.now(), isTyping: true);
    _messages.add(typingMsg);
    _emit();

    // 3. Wait random time
    await Future.delayed(const Duration(seconds: 2));

    // 4. Remove typing and add Partner Response
    _messages.remove(typingMsg);
    _messages.add(ChatMessage(
      id: DateTime.now().toString(),
      text: _generateResponse(text),
      isMe: false,
      timestamp: DateTime.now(),
    ));
    _emit();
  }

  String _generateResponse(String input) {
    input = input.toLowerCase();
    if (input.contains("hello") || input.contains("hi")) return "Hello! How can I help you today?";
    if (input.contains("time")) return "It is currently 2:30 PM.";
    if (input.contains("name")) return "I am your Signasphere assistant.";
    if (input.contains("thank")) return "You're welcome!";
    return "I understand. Could you tell me more?";
  }
}
