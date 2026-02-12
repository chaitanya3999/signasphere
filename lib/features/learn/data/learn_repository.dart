import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/theme_controller.dart';

final learnRepositoryProvider = Provider<LearnRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LearnRepository(prefs);
});

class QuizQuestion {
  final String id;
  final String prompt;
  final String correctAnswer;
  final List<String> options;

  QuizQuestion({
    required this.id,
    required this.prompt,
    required this.correctAnswer,
    required this.options,
  });
}

class LessonModule {
  final String id;
  final String title;
  final String subtitle;
  final int totalQuestions;
  final String difficulty;
  final String iconName; // Maps to phosphor icon name logically

  LessonModule({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.totalQuestions,
    required this.difficulty,
    required this.iconName,
  });
}

class LearnRepository {
  final SharedPreferences _prefs;

  LearnRepository(this._prefs);

  // --- Data ---

  final List<LessonModule> _modules = [
    LessonModule(id: 'basics', title: 'Basics: Alphabet', subtitle: 'Learn A-Z handshapes', totalQuestions: 5, difficulty: 'Beginner', iconName: 'textAa'),
    LessonModule(id: 'greetings', title: 'Greetings', subtitle: 'Hello, Goodbye, Thank you', totalQuestions: 5, difficulty: 'Beginner', iconName: 'handGrabbing'),
    LessonModule(id: 'emergency', title: 'Emergency Signs', subtitle: 'Help, Doctor, Pain', totalQuestions: 5, difficulty: 'Intermediate', iconName: 'siren'),
    LessonModule(id: 'daily', title: 'Daily Conversation', subtitle: 'Food, Time, Directions', totalQuestions: 5, difficulty: 'Intermediate', iconName: 'chatCircleDots'),
  ];

  final Map<String, List<QuizQuestion>> _quizzes = {
    'basics': [
      QuizQuestion(id: 'b1', prompt: 'Which sign represents the letter "A"?', correctAnswer: 'A', options: ['A', 'B', 'S']),
      QuizQuestion(id: 'b2', prompt: 'Which sign represents the letter "B"?', correctAnswer: 'B', options: ['B', 'C', 'A']),
      QuizQuestion(id: 'b3', prompt: 'Which sign represents the letter "C"?', correctAnswer: 'C', options: ['C', 'O', 'D']),
      QuizQuestion(id: 'b4', prompt: 'Which sign represents the letter "L"?', correctAnswer: 'L', options: ['L', 'D', 'V']),
      QuizQuestion(id: 'b5', prompt: 'Which sign represents the letter "O"?', correctAnswer: 'O', options: ['O', 'C', 'G']),
    ],
    'greetings': [
      QuizQuestion(id: 'g1', prompt: 'How do you sign "Hello"?', correctAnswer: 'Salute from forehead', options: ['Salute from forehead', 'Wave hand', 'Touch basics']),
      QuizQuestion(id: 'g2', prompt: 'How do you sign "Thank You"?', correctAnswer: 'Touch chin move forward', options: ['Touch chin move forward', 'Rub chest', 'Tap nose']),
      QuizQuestion(id: 'g3', prompt: 'How do you sign "Goodbye"?', correctAnswer: 'Open palm wave', options: ['Open palm wave', 'Clenched fist shake', 'Index finger point']),
    ],
    // Simplified specific questions for demo
    'emergency': [
       QuizQuestion(id: 'e1', prompt: 'Sign for "Help"?', correctAnswer: 'Fist on palm lift', options: ['Fist on palm lift', 'Tap shoulder', 'Rub stomach']),
    ],
    'daily': [
       QuizQuestion(id: 'd1', prompt: 'Sign for "Eat"?', correctAnswer: 'Tap mouth with fingertips', options: ['Tap mouth with fingertips', 'Drink motion', 'Rub belly']),
    ]
  };

  // --- Getters ---

  List<LessonModule> getModules() => _modules;

  List<QuizQuestion> getQuizForModule(String moduleId) {
    if (_quizzes.containsKey(moduleId)) return _quizzes[moduleId]!;
    // Fallback practice questions
    return _quizzes['basics']!;
  }

  // --- Persistence ---

  int getXP() => _prefs.getInt('user_xp') ?? 0;
  
  Future<void> addXP(int amount) async {
    final current = getXP();
    await _prefs.setInt('user_xp', current + amount);
  }

  int getStreak() => _prefs.getInt('user_streak') ?? 0;
  
  String? getLastQuizDate() => _prefs.getString('last_quiz_date');

  Future<void> updateStreak() async {
    final now = DateTime.now();
    final today = "${now.year}-${now.month}-${now.day}";
    final lastDate = getLastQuizDate();

    if (lastDate != today) {
       // Ideally check if yesterday to increment, else reset. 
       // For hackathon simpler: if lastDate != today, increment.
       final current = getStreak();
       await _prefs.setInt('user_streak', current + 1);
       await _prefs.setString('last_quiz_date', today);
    }
  }

  double getModuleProgress(String moduleId) => _prefs.getDouble('progress_$moduleId') ?? 0.0;

  Future<void> setModuleProgress(String moduleId, double progress) async {
    // Only update if higher
    final current = getModuleProgress(moduleId);
    if (progress > current) {
      await _prefs.setDouble('progress_$moduleId', progress);
    }
  }
}
