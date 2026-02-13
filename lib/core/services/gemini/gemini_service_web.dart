import 'dart:async';
import 'dart:js_interop';
import '../../config/api_config.dart';
import '../../../features/conversation/data/conversation_repository.dart';
import 'gemini_service_base.dart';

/// Web implementation using Puter.js
class GeminiServiceWeb implements GeminiServiceBase {
  @override
  Future<String> generateResponse({
    required String userMessage,
    required List<ChatMessage> history,
    String? systemPrompt,
  }) async {
    final sanitized = _sanitizeInput(userMessage);

    if (sanitized.isEmpty) {
      throw GeminiServiceException("Message cannot be empty.");
    }

    final prompt = _buildPrompt(sanitized, history, systemPrompt);

    try {
      final chatOptions = ChatOptions(model: ApiConfig.geminiModel);
      
      // Wait for Puter.js to load (handle race conditions)
      final puterInstance = await _waitForPuter();
      
      if (puterInstance == null) {
        throw GeminiServiceException("Puter.js not loaded. Please Reload Page.");
      }
      
      final ai = puterInstance.ai;
      if (ai == null) {
         throw GeminiServiceException("Puter.ai service not initialized.");
      }
      
      final promise = ai.chat(prompt.toJS, chatOptions);

      // Convert JSPromise to Dart Future safely
      final result = await promise.toDart;

      if (result.isA<JSString>()) {
        final str = (result as JSString).toDart;
        if (str.trim().isEmpty) throw GeminiServiceException("Empty AI response.");
        return str.trim();
      } else {
         // It might be an object, let's just toString it safely
         final str = result.toString();
         if (str.trim().isEmpty) throw GeminiServiceException("Empty AI response.");
         return str.trim();
      }
    } catch (e) {
      // Expose the actual error for debugging
      final errorMessage = e.toString();
      
      if (errorMessage.contains("ReferenceError") || errorMessage.contains("puter is not defined")) {
         throw GeminiServiceException("Puter.js script missing. Restart App.");
      }
      
      throw GeminiServiceException("AI Error: $errorMessage");
    }
  }

  /// Polls for Puter.js global object for up to 5 seconds
  /// If not found initially, attempts to inject the script.
  Future<PuterJS?> _waitForPuter() async {
    // Check immediately
    if (puter != null) return puter;
    
    // Attempt dynamic injection if not found immediately
    _injectPuterScript();

    // Poll every 100ms for 5 seconds (50 attempts)
    for (int i = 0; i < 50; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (puter != null) return puter;
    }
    
    return null;
  }
  
  /// Dynamically injects the Puter.js script into the document head
  void _injectPuterScript() {
    // Check if script already exists to avoid duplicates
    final existingScript = document.querySelector('script[src="${ApiConfig.puterJsSdkUrl}"]');
    if (existingScript != null) return;

    final script = document.createElement('script') as HTMLScriptElement;
    script.src = ApiConfig.puterJsSdkUrl;
    script.type = 'text/javascript';
    script.async = true;
    
    document.head?.appendChild(script);
  }

  @override
  void dispose() {}

  String _sanitizeInput(String input) {
    var sanitized = input.trim();
    if (sanitized.length > ApiConfig.maxInputLength) {
      sanitized = sanitized.substring(0, ApiConfig.maxInputLength);
    }
    return sanitized;
  }

  String _buildPrompt(String currentMessage, List<ChatMessage> history, String? systemPrompt) {
    final buffer = StringBuffer();
    buffer.writeln("SYSTEM:");
    buffer.writeln((systemPrompt ?? ApiConfig.systemPrompt).trim());
    buffer.writeln("");

    final relevantHistory = history.where((m) => !m.isTyping).toList();
    final startIndex = relevantHistory.length > ApiConfig.maxContextMessages
        ? relevantHistory.length - ApiConfig.maxContextMessages
        : 0;

    for (int i = startIndex; i < relevantHistory.length; i++) {
      final msg = relevantHistory[i];
      buffer.writeln(msg.isMe ? "USER:" : "ASSISTANT:");
      buffer.writeln(msg.text.trim());
      buffer.writeln("");
    }

    buffer.writeln("USER:");
    buffer.writeln(currentMessage.trim());
    buffer.writeln("");
    buffer.writeln("ASSISTANT:");

    return buffer.toString();
  }
}

// JS Interop definitions

@JS("puter")
external JSAny? get _puterNullable;

PuterJS? get puter {
  if (_puterNullable == null) return null;
  return _puterNullable as PuterJS;
}

extension type PuterJS._(JSObject _) implements JSObject {
  external PuterAI? get ai;
}

extension type PuterAI._(JSObject _) implements JSObject {
  external JSPromise<JSAny> chat(JSAny prompt, ChatOptions options);
}

@JS()
@anonymous
extension type ChatOptions._(JSObject _) implements JSObject {
  external factory ChatOptions({String model});
}

// DOM Interop for Injection
@JS('document')
external Document get document;

@JS()
extension type Document._(JSObject _) implements JSObject {
  external Element? querySelector(String selectors);
  external Element createElement(String tagName);
  external HTMLHeadElement? get head;
}

@JS()
extension type Element._(JSObject _) implements JSObject {
  external void appendChild(JSAny node);
}

@JS()
extension type HTMLHeadElement._(JSObject _) implements JSObject, Element {
   // Inherits appendChild
}

@JS()
extension type HTMLScriptElement._(JSObject _) implements JSObject, Element {
  external set src(String value);
  external set type(String value);
  external set async(bool value);
}

// Conditional imports handled at top of file usually. 
// Since gemini_service_mobile.dart was the default for io, we need to switch logic.
// In `gemini_service.dart`, we have:
// import 'gemini/gemini_service_stub.dart'
//     if (dart.library.io) 'gemini/gemini_service_mobile.dart'
//     if (dart.library.js_interop) 'gemini/gemini_service_web.dart';

// We need to change `gemini_service_mobile.dart` to actually use the bridge OR 
// change the conditional import to point to a new file that decides.
// HOWEVER, `gemini_service_web_bridge.dart` depends on `webview_flutter` which is IO only.
// So we can make `gemini_service_mobile.dart` use the bridge? 
// No, let's keep it clean.
// The user wants to replace REST with Web Bridge for Android.

// Let's modify `lib/core/services/gemini_service.dart` imports.

