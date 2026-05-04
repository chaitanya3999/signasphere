import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ttsServiceProvider = Provider<TTSService>((ref) => TTSService());

class TTSService {
  final FlutterTts _flutterTts = FlutterTts();
  Completer<void>? _speakCompleter;

  TTSService() {
    _init();
  }

  void _init() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.4);
    await _flutterTts.awaitSpeakCompletion(true);

    _flutterTts.setCompletionHandler(() {
      _speakCompleter?.complete();
      _speakCompleter = null;
    });

    _flutterTts.setErrorHandler((msg) {
      _speakCompleter?.completeError(msg);
      _speakCompleter = null;
    });

    _flutterTts.setCancelHandler(() {
      _speakCompleter?.complete();
      _speakCompleter = null;
    });
  }

  /// Speak text and return immediately (fire-and-forget).
  Future<void> speak(String text) async {
    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }

  /// Speak text and wait until speech completes before returning.
  Future<void> speakAndWait(String text) async {
    if (text.isEmpty) return;
    _speakCompleter = Completer<void>();
    await _flutterTts.speak(text);
    try {
      await _speakCompleter!.future.timeout(const Duration(seconds: 10));
    } catch (_) {
      // Timeout or error — continue gracefully
    }
    _speakCompleter = null;
  }

  /// Update speech rate (0.0 – 1.0). Slow kids mode ≈ 0.3, Normal ≈ 0.5
  Future<void> setSpeechRate(double rate) async {
    await _flutterTts.setSpeechRate(rate);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
    _speakCompleter?.complete();
    _speakCompleter = null;
  }
}
