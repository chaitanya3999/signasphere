import 'package:flutter/foundation.dart';

@immutable
class GestureState {
  final String currentGesture; // Live transient letter
  final String sentence;       // Constructed sentence
  final String status;
  final bool isTracking;

  final String? lastRecognizedWord; // The specific word detected (e.g., "HELLO")
  final DateTime? lastWordTime;     // Timestamp for UI flash/fade logic

  final DateTime lastUpdated;
  final String? errorMessage;

  const GestureState({
    this.currentGesture = "...",
    this.sentence = "",
    this.status = "Initializing",
    this.isTracking = false,
    this.lastRecognizedWord,
    this.lastWordTime,
    required this.lastUpdated,
    this.errorMessage,
  });

  factory GestureState.initial() {
    return GestureState(
      lastUpdated: DateTime.now(),
    );
  }

  GestureState copyWith({
    String? currentGesture,
    String? sentence,
    String? status,
    bool? isTracking,
    String? lastRecognizedWord,
    DateTime? lastWordTime,
    DateTime? lastUpdated,
    String? errorMessage,
  }) {
    return GestureState(
      currentGesture: currentGesture ?? this.currentGesture,
      sentence: sentence ?? this.sentence,
      status: status ?? this.status,
      isTracking: isTracking ?? this.isTracking,
      lastRecognizedWord: lastRecognizedWord,
      lastWordTime: lastWordTime,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      errorMessage: errorMessage,
    );
  }
}