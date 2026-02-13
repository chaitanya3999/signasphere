import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../../features/conversation/data/conversation_repository.dart';
import 'gemini_service_base.dart';

/// Mobile implementation using REST API
class GeminiServiceMobile implements GeminiServiceBase {
  final http.Client _client = http.Client();

  @override
  Future<String> generateResponse({
    required String userMessage,
    required List<ChatMessage> history,
    String? systemPrompt,
  }) async {
    final sanitized = _sanitizeInput(userMessage);
    if (sanitized.isEmpty) {
      throw GeminiServiceException('Message cannot be empty.');
    }

    final messages = _buildMessages(sanitized, history, systemPrompt);

    final body = jsonEncode({
      'interface': 'puter-chat-completion',
      'driver': 'ai-chat',
      'method': 'complete',
      'args': {
        'messages': messages,
        'model': ApiConfig.geminiModel,
      },
    });

    try {
      final response = await _client
          .post(
            Uri.parse('${ApiConfig.puterBaseUrl}/drivers/call'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${ApiConfig.puterAuthToken}',
            },
            body: body,
          )
          .timeout(
            const Duration(seconds: ApiConfig.requestTimeoutSeconds),
          );

      if (response.statusCode == 200) {
        return _parseResponse(response.body);
      } else if (response.statusCode == 429) {
        throw GeminiServiceException(
          'Too many requests. Please wait a moment and try again.',
        );
      } else {
        throw GeminiServiceException(
          'API error (${response.statusCode}). Please try again.',
        );
      }
    } on GeminiServiceException {
      rethrow;
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw GeminiServiceException(
          'Request timed out. Please check your connection.',
        );
      }
      throw GeminiServiceException(
        'Connection failed. Please check your internet.',
      );
    }
  }

  @override
  void dispose() {
    _client.close();
  }

  String _sanitizeInput(String input) {
    String sanitized = input.trim();
    if (sanitized.length > ApiConfig.maxInputLength) {
      sanitized = sanitized.substring(0, ApiConfig.maxInputLength);
    }
    return sanitized;
  }

  List<Map<String, String>> _buildMessages(
    String currentMessage,
    List<ChatMessage> history,
    String? systemPrompt,
  ) {
    final messages = <Map<String, String>>[];

    messages.add({
      'role': 'system',
      'role': 'system',
      'content': systemPrompt ?? ApiConfig.systemPrompt,
    });

    final relevantHistory = history.where((m) => !m.isTyping).toList();
    
    final startIndex = relevantHistory.length > ApiConfig.maxContextMessages
        ? relevantHistory.length - ApiConfig.maxContextMessages
        : 0;

    for (int i = startIndex; i < relevantHistory.length; i++) {
      final msg = relevantHistory[i];
      messages.add({
        'role': msg.isMe ? 'user' : 'assistant',
        'content': msg.text,
      });
    }

    messages.add({
      'role': 'user',
      'content': currentMessage,
    });

    return messages;
  }

  String _parseResponse(String responseBody) {
    try {
      final json = jsonDecode(responseBody);

      if (json is Map) {
        if (json['result'] != null) {
          final result = json['result'];
          if (result is Map && result['message'] != null) {
            final content = result['message']['content'];
            if (content is String && content.isNotEmpty) return content.trim();
          }
          if (result is String && result.isNotEmpty) return result.trim();
        }
        
        if (json['message'] != null) {
          final msg = json['message'];
          if (msg is Map && msg['content'] is String) {
            return (msg['content'] as String).trim();
          }
        }
      }
      
      throw GeminiServiceException('Unexpected response format.');
    } catch (e) {
      if (e is GeminiServiceException) rethrow;
      throw GeminiServiceException('Failed to parse AI response.');
    }
  }
}

GeminiServiceBase createGeminiService() => GeminiServiceMobile();
