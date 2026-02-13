import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/conversation/data/conversation_repository.dart';

// Abstract class defining the service contract
abstract class GeminiServiceBase {
  Future<String> generateResponse({
    required String userMessage,
    required List<ChatMessage> history,
    String? systemPrompt,
  });
  
  void dispose() {}
}

// Exception class
class GeminiServiceException implements Exception {
  final String message;
  GeminiServiceException(this.message);

  @override
  String toString() => "GeminiServiceException: $message";
}
