import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb

class FeedbackService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Singleton pattern
  static final FeedbackService _instance = FeedbackService._internal();
  factory FeedbackService() => _instance;
  FeedbackService._internal();

  Future<void> playCorrect() async {
    try {
      if (!kIsWeb) {
        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate(duration: 50); // Light haptic
        }
      }
      
      await _audioPlayer.stop(); // Stop previous
      await _audioPlayer.play(AssetSource('sounds/correct.mp3'));
    } catch (e) {
      debugPrint("Error playing correct sound: $e");
    }
  }

  Future<void> playWrong() async {
    try {
      if (!kIsWeb) {
        if (await Vibration.hasVibrator() ?? false) {
           Vibration.vibrate(duration: 200); // Longer haptic
        }
      }

      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/wrong.mp3'));
    } catch (e) {
      debugPrint("Error playing wrong sound: $e");
    }
  }

  Future<void> hapticSelection() async {
    if (!kIsWeb) {
       // Just a light tick
       if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate(duration: 10);
       }
    }
  }
}
