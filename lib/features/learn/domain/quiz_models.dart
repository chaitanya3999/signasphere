import 'package:flutter/foundation.dart';

enum QuizType {
  guessWord,    // Image -> 4 Text Options
  selectSign,   // Text -> 4 Image Options
  matchPair,    // 4 Text <-> 4 Images
  flashcard,    // Front/Back
}

abstract class QuizQuestion {
  final String id;
  final QuizType type;

  QuizQuestion({required this.id, required this.type});
}

class GuessWordQuestion extends QuizQuestion {
  final String imagePath;
  final String correctLabel;
  final List<String> options; // Includes correctLabel

  GuessWordQuestion({
    required String id,
    required this.imagePath,
    required this.correctLabel,
    required this.options,
  }) : super(id: id, type: QuizType.guessWord);
}

class SelectSignQuestion extends QuizQuestion {
  final String promptLabel;
  final String correctImagePath;
  final List<String> optionImagePaths; // Includes correctImagePath
  final Map<String, String> imageToLabelMap; // Helper to know which image matches which label

  SelectSignQuestion({
    required String id,
    required this.promptLabel,
    required this.correctImagePath,
    required this.optionImagePaths,
    required this.imageToLabelMap,
  }) : super(id: id, type: QuizType.selectSign);
}

class MatchPairQuestion extends QuizQuestion {
  final Map<String, String> pairs; // Label -> ImagePath

  MatchPairQuestion({
    required String id,
    required this.pairs,
  }) : super(id: id, type: QuizType.matchPair);
}

class FlashcardQuestion extends QuizQuestion {
  final String label;
  final String imagePath;

  FlashcardQuestion({
    required String id,
    required this.label,
    required this.imagePath,
  }) : super(id: id, type: QuizType.flashcard);
}

class SignWord {
  final String label;
  final List<String> imagePaths;

  SignWord({
    required this.label,
    required this.imagePaths,
  });
}
