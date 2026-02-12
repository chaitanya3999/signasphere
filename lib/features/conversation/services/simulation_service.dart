import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final simulationServiceProvider = Provider((ref) => SimulationService());

class SimulationService {
  final Random _random = Random();

  String generateResponse(String input) {
    final lowerInput = input.toLowerCase();

    // 1. Greetings
    if (lowerInput.contains('hi') || lowerInput.contains('hello') || lowerInput.contains('hey')) {
      return _randomChoice([
        "Hello! How can I help you today?",
        "Hi there! I'm listening.",
        "Greetings! Ready to translate.",
      ]);
    }

    // 2. Basics
    if (lowerInput.contains('name')) {
      return "I am Signasphere, your bridge between Sign and Speech.";
    }
    if (lowerInput.contains('how are you')) {
      return "I'm functioning perfectly and ready to help!";
    }
    if (lowerInput.contains('thank')) {
      return _randomChoice([
        "You're very welcome!",
        "Happy to help!",
        "Anytime!",
      ]);
    }

    // 3. Emergency / Medical
    if (lowerInput.contains('help') || lowerInput.contains('emergency')) {
      return "I am detecting an emergency. Please call 911 if this is critical. How can I assist you now?";
    }
    if (lowerInput.contains('doctor') || lowerInput.contains('hospital')) {
      return "I can help you communicate with the doctor. Please verify your symptoms.";
    }
    if (lowerInput.contains('pain') || lowerInput.contains('hurt')) {
      return "I understand you are in pain. Can you describe where it hurts?";
    }

    // 4. Directions
    if (lowerInput.contains('where') || lowerInput.contains('location') || lowerInput.contains('bathroom') || lowerInput.contains('restroom')) {
      return "I can help you ask for directions. Are you looking for a specific place?";
    }

    // 5. Fallback
    return _randomChoice([
      "I see. Could you tell me more?",
      "I'm listening. Please go on.",
      "Understood. What else?",
      "That's interesting. Continue please.",
    ]);
  }

  String _randomChoice(List<String> options) {
    return options[_random.nextInt(options.length)];
  }

  Duration getTypingDelay() {
    return Duration(milliseconds: 1500 + _random.nextInt(1500)); // 1.5s to 3s
  }
}
