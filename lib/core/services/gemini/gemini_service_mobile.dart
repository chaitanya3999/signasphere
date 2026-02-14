import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../../features/conversation/data/conversation_repository.dart';
import 'gemini_service_base.dart';

/// Mobile implementation using SambaNova REST API
class GeminiServiceMobile implements GeminiServiceBase {
  final http.Client _client = http.Client();
  bool _useBackupToken = false;
  bool _isRequestActive = false;
  final List<Completer<void>> _lockQueue = [];

  @override
  Future<String> generateResponse({
    required String userMessage,
    required List<ChatMessage> history,
    String? systemPrompt,
  }) async {
    // Sequential Execution Lock
    if (_isRequestActive) {
      final completer = Completer<void>();
      _lockQueue.add(completer);
      await completer.future;
    }

    _isRequestActive = true;
    try {
      return await _executeWithRetry(
        userMessage: userMessage,
        history: history,
        systemPrompt: systemPrompt,
      );
    } finally {
      // Release lock and trigger next in queue
      if (_lockQueue.isNotEmpty) {
        final next = _lockQueue.removeAt(0);
        next.complete();
      } else {
        _isRequestActive = false;
      }
    }
  }

  Future<String> _executeWithRetry({
    required String userMessage,
    required List<ChatMessage> history,
    String? systemPrompt,
    int retryCount = 0,
  }) async {
    final sanitized = _sanitizeInput(userMessage);
    if (sanitized.isEmpty) {
      throw GeminiServiceException('Message cannot be empty.');
    }

    final messages = _buildMessages(sanitized, history, systemPrompt);

    // SambaNova / OpenAI Compatible Body
    final body = jsonEncode({
      'stream': false,
      'model': ApiConfig.geminiModel,
      'messages': messages,
    });

    final currentToken = _useBackupToken ? ApiConfig.backupAuthToken : ApiConfig.primaryAuthToken;
    print('[GeminiService] Using ${_useBackupToken ? "Backup" : "Primary"} Token (Retry: $retryCount)');

    try {
      final response = await _client
          .post(
            Uri.parse('${ApiConfig.sambaNovaBaseUrl}/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $currentToken',
            },
            body: body,
          )
          .timeout(
            const Duration(seconds: ApiConfig.requestTimeoutSeconds),
          );

      print('[GeminiService] Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return _parseResponse(response.bodyBytes);
      } else if (response.statusCode == 429) {
        if (retryCount == 0) {
          // Fallback to backup token immediately on first 429
          print('[GeminiService] Rate limited. Switching to backup token.');
          _useBackupToken = !_useBackupToken; // Toggle token
          return _executeWithRetry(
            userMessage: userMessage,
            history: history,
            systemPrompt: systemPrompt,
            retryCount: retryCount + 1,
          );
        } else if (retryCount < 3) {
          // Exponential backoff: 2s, 4s, 8s
          final backoffSeconds = pow(2, retryCount).toInt();
          print('[GeminiService] Rate limited on backup. Waiting ${backoffSeconds}s before retry $retryCount...');
          await Future.delayed(Duration(seconds: backoffSeconds));
          return _executeWithRetry(
            userMessage: userMessage,
            history: history,
            systemPrompt: systemPrompt,
            retryCount: retryCount + 1,
          );
        } else {
          throw GeminiServiceException(
            'AI is overloaded. Please try again in 1 minute.',
          );
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw GeminiServiceException(
          'Authentication failed (${response.statusCode}). Check API Key.',
        );
      } else {
        // Try to parse error message from body
        try {
           final errJson = jsonDecode(response.body);
           String msg = "API Error";
           if (errJson['error'] != null) {
              if (errJson['error'] is String) {
                  msg = errJson['error'];
              } else if (errJson['error']['message'] != null) {
                  msg = errJson['error']['message'];
              }
           }
           throw GeminiServiceException(msg);
        } catch (_) {}

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
      'content': systemPrompt ?? ApiConfig.systemPrompt,
    });

    final relevantHistory = history.where((m) => !m.isTyping).toList();
    
    final startIndex = relevantHistory.length > ApiConfig.maxContextMessages
        ? relevantHistory.length - ApiConfig.maxContextMessages
        : 0;

    for (int i = startIndex; i < relevantHistory.length; i++) {
        final msg = relevantHistory[i];
        final role = msg.isMe ? 'user' : 'assistant'; // OpenAI/Llama uses 'assistant'
        messages.add({
          'role': role,
          'content': msg.text,
        });
    }

    messages.add({
      'role': 'user',
      'content': currentMessage,
    });

    return messages;
  }

  String _parseResponse(dynamic responseBodyBytes) {
    try {
      final jsonString = utf8.decode(responseBodyBytes);
      final json = jsonDecode(jsonString);

      if (json['choices'] != null && (json['choices'] as List).isNotEmpty) {
        final choice = json['choices'][0];
        if (choice['message'] != null && choice['message']['content'] != null) {
          return (choice['message']['content'] as String).trim();
        }
      }
      
      throw GeminiServiceException('Empty response from SambaNova.');
    } catch (e) {
      if (e is GeminiServiceException) rethrow;
      throw GeminiServiceException('Failed to parse AI response.');
    }
  }
}

GeminiServiceBase createGeminiService() => GeminiServiceMobile();
