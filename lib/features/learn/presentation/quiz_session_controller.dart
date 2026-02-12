import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/quiz_models.dart';
import '../domain/quiz_engine.dart';
import '../../../../core/services/feedback_service.dart';

final quizSessionControllerProvider = StateNotifierProvider.autoDispose<QuizSessionController, QuizSessionState>((ref) {
  final engine = ref.watch(quizEngineProvider);
  return QuizSessionController(engine);
});

class QuizSessionState {
  final List<QuizQuestion> questions;
  final int currentIndex;
  final int score;
  final bool isAnswered;
  final bool isCorrect;
  final bool isFinished;
  final String? feedbackMessage;
  
  // Timer for Full Test Mode (optional, but good for "Test")
  final int elapsedSeconds;

  QuizSessionState({
    required this.questions,
    this.currentIndex = 0,
    this.score = 0,
    this.isAnswered = false,
    this.isCorrect = false,
    this.isFinished = false,
    this.feedbackMessage,
    this.elapsedSeconds = 0,
  });
  
  QuizQuestion? get currentQuestion => 
      (questions.isNotEmpty && currentIndex < questions.length) 
      ? questions[currentIndex] 
      : null;

  double get progress => questions.isEmpty ? 0 : ((currentIndex + (isFinished ? 1 : 0)) / questions.length);

  QuizSessionState copyWith({
    List<QuizQuestion>? questions,
    int? currentIndex,
    int? score,
    bool? isAnswered,
    bool? isCorrect,
    bool? isFinished,
    String? feedbackMessage,
    int? elapsedSeconds,
  }) {
    return QuizSessionState(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      score: score ?? this.score,
      isAnswered: isAnswered ?? this.isAnswered,
      isCorrect: isCorrect ?? this.isCorrect,
      isFinished: isFinished ?? this.isFinished,
      feedbackMessage: feedbackMessage ?? this.feedbackMessage,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
    );
  }
}

class QuizSessionController extends StateNotifier<QuizSessionState> {
  final QuizEngine _engine;
  Timer? _timer;

  QuizSessionController(this._engine) : super(QuizSessionState(questions: []));

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void startQuiz(QuizType type, int count) {
    _timer?.cancel();
    final questions = _engine.generateQuiz(type, count);
    state = QuizSessionState(questions: questions);
    _startTimer();
  }
  
  void startFullTest(int count) {
     _timer?.cancel();
     final questions = _engine.generateFullTest(count);
     state = QuizSessionState(questions: questions);
     _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (!state.isFinished) {
        state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
      }
    });
  }

  void submitAnswer(bool correct) {
    if (state.isAnswered || state.isFinished) return;
    
    // Play feedback
    if (correct) {
      FeedbackService().playCorrect();
    } else {
      FeedbackService().playWrong();
    }
    
    state = state.copyWith(
      isAnswered: true,
      isCorrect: correct,
      score: correct ? state.score + 1 : state.score,
      feedbackMessage: correct ? "Correct!" : "Incorrect",
    );
    // No auto-advance: user must tap "Next" to proceed
  }

  void nextQuestion() {
    if (state.currentIndex < state.questions.length - 1) {
      state = state.copyWith(
        currentIndex: state.currentIndex + 1,
        isAnswered: false,
        isCorrect: false,
        feedbackMessage: null,
      );
    } else {
      _finishQuiz();
    }
  }

  void _finishQuiz() {
    _timer?.cancel();
    state = state.copyWith(isFinished: true);
  }
}
