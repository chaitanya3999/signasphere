import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/conversation_repository.dart';
import '../services/simulation_service.dart';

final conversationControllerProvider = StateNotifierProvider<ConversationController, List<ChatMessage>>((ref) {
  final repo = ref.watch(conversationRepositoryProvider);
  final simulation = ref.watch(simulationServiceProvider);
  return ConversationController(repo, simulation);
});

class ConversationController extends StateNotifier<List<ChatMessage>> {
  final ConversationRepository _repository;
  final SimulationService _simulation;

  ConversationController(this._repository, this._simulation) : super([]) {
    _loadMessages();
  }

  void _loadMessages() {
    state = _repository.getMessages();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // 1. Add User Message
    final userMsg = ChatMessage(
      id: DateTime.now().toString(),
      text: text,
      isMe: true,
      timestamp: DateTime.now(),
    );
    
    state = [...state, userMsg];
    await _repository.saveMessage(userMsg);

    // 2. Show Typing Indicator
    final typingMsg = ChatMessage(
      id: 'typing',
      text: '...',
      isMe: false,
      timestamp: DateTime.now(),
      isTyping: true,
    );
    
    // Wait a bit before showing typing to feel natural
    await Future.delayed(const Duration(milliseconds: 500));
    state = [...state, typingMsg];

    // 3. Generate & Send Response
    final delay = _simulation.getTypingDelay();
    await Future.delayed(delay);

    final responseText = _simulation.generateResponse(text);
    final partnerMsg = ChatMessage(
      id: DateTime.now().toString(), 
      text: responseText,
      isMe: false,
      timestamp: DateTime.now(),
    );

    // Remove typing indicator and add response
    state = [
      ...state.where((m) => m.id != 'typing'),
      partnerMsg
    ];
    await _repository.saveMessage(partnerMsg);
  }

  Future<void> clearHistory() async {
    await _repository.clearHistory();
    state = [];
  }
}
