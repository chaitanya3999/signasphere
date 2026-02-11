import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

final sttServiceProvider = Provider<STTService>((ref) => STTService());

class STTService {
  final SpeechToText _speech = SpeechToText();
  bool _isAvailable = false;

  Future<bool> init() async {
    if (!_isAvailable) {
      try {
        _isAvailable = await _speech.initialize(
          onError: (e) => debugPrint("STT Error: $e"),
          onStatus: (s) => debugPrint("STT Status: $s"),
        );
      } catch (e) {
        debugPrint("STT Init Error: $e");
        _isAvailable = false;
      }
    }
    return _isAvailable;
  }

  Future<void> listen({required Function(String) onResult}) async {
    if (!_isAvailable) await init();
    
    if (_isAvailable) {
      _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            onResult(result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      );
    }
  }

  Future<void> stop() async {
    await _speech.stop();
  }
  
  bool get isListening => _speech.isListening;
}
