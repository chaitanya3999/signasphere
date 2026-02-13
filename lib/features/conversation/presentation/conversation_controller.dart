import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/gemini_service.dart';
import '../../../../core/config/api_config.dart';
import '../data/conversation_repository.dart';

final gptModeProvider = StateProvider<bool>((ref) => false); 

final conversationControllerProvider = StateNotifierProvider<ConversationController, List<ChatMessage>>((ref) {
  final repo = ref.watch(conversationRepositoryProvider);
  final gemini = ref.watch(geminiServiceProvider);
  return ConversationController(repo, gemini, ref);
});

class ConversationController extends StateNotifier<List<ChatMessage>> {
  final ConversationRepository _repository;
  final GeminiService _gemini;
  final Ref _ref;
  bool _isProcessing = false;

  ConversationController(this._repository, this._gemini, this._ref) : super([]) {
    _loadMessages();
  }

  void _loadMessages() {
    state = _repository.getMessages();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || _isProcessing) return;

    _isProcessing = true;

    // 1. Add User Message
    final userMsg = ChatMessage(
      id: DateTime.now().toString(),
      text: text,
      isMe: true,
      timestamp: DateTime.now(),
      status: 'sending',
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
    
    state = [...state, typingMsg];

    try {
      // 3. Call Gemini API
      // Wait at least 1 second for natural feel
      final stopwatch = Stopwatch()..start();
      
      // Update typing indicator if it takes too long
      Future.delayed(const Duration(seconds: 4), () {
        if (_isProcessing && state.any((m) => m.id == 'typing')) {
          state = state.map((m) {
            if (m.id == 'typing') {
              return ChatMessage(
                id: 'typing',
                text: 'Still thinking...',
                isMe: false,
                timestamp: DateTime.now(),
                isTyping: true,
              );
            }
            return m;
          }).toList();
        }
      });

      final isGptMode = _ref.read(gptModeProvider);
      final systemPrompt = isGptMode ? ApiConfig.systemPromptGpt : ApiConfig.systemPrompt;

      final responseText = await _gemini.generateResponse(
        userMessage: text,
        history: state.where((m) => m.id != 'typing' && m.id != userMsg.id).toList(),
        systemPrompt: systemPrompt,
      );

      // Ensure minimum delay
      if (stopwatch.elapsedMilliseconds < 1000) {
        await Future.delayed(Duration(milliseconds: 1000 - stopwatch.elapsedMilliseconds));
      }

      // 4. Remove typing indicator
      state = state.where((m) => m.id != 'typing').toList();

      // 5. Streaming-like Reveal
      final responseMsgId = DateTime.now().toString();
      final words = responseText.split(' ');
      String currentText = '';

      // Create placeholder message
      var responseMsg = ChatMessage(
        id: responseMsgId,
        text: '',
        isMe: false,
        timestamp: DateTime.now(),
        source: 'gemini',
      );
      state = [...state, responseMsg];

      for (int i = 0; i < words.length; i++) {
        currentText += '${words[i]} ';
        
        // Update the last message
        state = state.map((m) {
          if (m.id == responseMsgId) {
            return m.copyWith(text: currentText.trim());
          }
          return m;
        }).toList();

        // Speed adjustment: faster for long messages
        final delay = words.length > 50 ? 30 : 50;
        await Future.delayed(Duration(milliseconds: delay));
      }

      // Final save
      responseMsg = state.firstWhere((m) => m.id == responseMsgId);
      await _repository.saveMessage(responseMsg);

    } catch (e) {
      // Handle Error
      state = state.where((m) => m.id != 'typing').toList();
      
      final errorMsg = ChatMessage(
        id: DateTime.now().toString(),
        text: e is GeminiServiceException 
            ? e.message 
            : "Sorry, I'm having trouble connecting. Please try again.",
        isMe: false,
        timestamp: DateTime.now(),
        source: 'gemini',
        status: 'error',
      );
      
      state = [...state, errorMsg];
      await _repository.saveMessage(errorMsg);
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> retryLastMessage() async {
    if (_isProcessing) return;

    final lastUserMsg = state.lastWhere(
      (m) => m.isMe,
      orElse: () => ChatMessage(id: '', text: '', isMe: true, timestamp: DateTime.now()),
    );

    if (lastUserMsg.text.isNotEmpty) {
      // Remove last error message if exists
      if (state.isNotEmpty && !state.last.isMe && state.last.status == 'error') {
        state = state.sublist(0, state.length - 1);
      }
      await sendMessage(lastUserMsg.text);
    }
  }

  Future<void> clearHistory() async {
    await _repository.clearHistory();
    state = [];
  }
}
