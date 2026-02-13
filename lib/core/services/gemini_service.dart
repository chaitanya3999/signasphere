import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/conversation/data/conversation_repository.dart';
import 'gemini/gemini_service_base.dart';
export 'gemini/gemini_service_base.dart' show GeminiServiceException;
import 'gemini/gemini_service_stub.dart'
    if (dart.library.io) 'gemini/gemini_service_mobile.dart'
    if (dart.library.js_interop) 'gemini/gemini_service_web.dart';

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});

/// Gemini AI service (Cross-platform wrapper)
///
/// Automatically switches between:
/// - Puter.js (Web)
/// - REST API (Mobile/Desktop)
class GeminiService implements GeminiServiceBase {
  final GeminiServiceBase _delegate;

  GeminiService() : _delegate = createGeminiService();

  @override
  Future<String> generateResponse({
    required String userMessage,
    required List<ChatMessage> history,
    String? systemPrompt,
  }) {
    return _delegate.generateResponse(
      userMessage: userMessage, 
      history: history,
      systemPrompt: systemPrompt
    );
  }

  @override
  void dispose() {
    _delegate.dispose();
  }
}