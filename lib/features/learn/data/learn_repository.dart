import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/data_structures/ds_manager.dart';

final learnRepositoryProvider = Provider<LearnRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final trie = ref.watch(trieProvider);
  final conceptGroups = ref.watch(conceptGroupProvider);
  final progressTree = ref.watch(progressTreeProvider);
  return LearnRepository(prefs, trie, conceptGroups, progressTree);
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
  final String iconName;

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
  final Trie _trie;
  final DisjointSet _conceptGroups;
  final SegmentTree _progressTree;

  LearnRepository(this._prefs, this._trie, this._conceptGroups, this._progressTree);

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
    return _quizzes['basics']!;
  }

  // --- TRIE: Word Search & Suggestions ---
  // WHY: Trie provides O(L) prefix search and autocomplete, which is impossible with 
  // standard HashMaps. This is perfect for the Learn Mode where kids type partial words 
  // and need instant suggestions. It also maps words to their sign video sequences.

  /// Search for a word in the Trie. O(L) lookup.
  bool wordExists(String word) => _trie.search(word);

  /// Get autocomplete suggestions from prefix. O(L + K).
  List<String> getSuggestions(String prefix) => _trie.getSuggestions(prefix);

  /// Get the sign video path for a word (if mapped).
  String? getSignPath(String word) => _trie.getSignSequence(word);

  /// Get all words in a Trie category.
  List<String> getWordsByCategory(String category) =>
      _trie.getWordsByCategory(category);

  // --- DISJOINT SET: Related Concepts ---
  // WHY: Union-Find (Disjoint Set) groups related concepts together dynamically 
  // (e.g., grouping 'apple' and 'banana' into 'FOOD'). It provides O(1) amortized 
  // time to check if concepts are related, which is faster and cleaner than 
  // maintaining complex nested maps or relational database structures.

  /// Get all items related to a concept (via Union-Find).
  List<String> getRelatedConcepts(String word) =>
      _conceptGroups.getGroup(word.toLowerCase());

  /// Get all concept groups.
  Map<String, List<String>> getAllConceptGroups() =>
      _conceptGroups.getAllGroups();

  /// Get the group label for a word.
  String? getConceptCategory(String word) =>
      _conceptGroups.getGroupLabel(word.toLowerCase());

  // --- SEGMENT TREE: Progress Tracking ---
  // WHY: A Segment Tree allows O(log N) range queries (e.g., "words learned 
  // between day 5 and day 12"). This is massively more efficient than O(N) linear 
  // array scanning, making dashboard analytics fast even over a full year (365 days).

  /// Record words learned today.
  void recordWordsLearned(int count) {
    final dayOfYear = DateTime.now().difference(
      DateTime(DateTime.now().year, 1, 1),
    ).inDays;
    _progressTree.update(dayOfYear, count);
  }

  /// Query words learned in last N days.
  int getWordsLearnedInDays(int days) {
    final today = DateTime.now().difference(
      DateTime(DateTime.now().year, 1, 1),
    ).inDays;
    final from = (today - days + 1).clamp(0, 364);
    return _progressTree.wordsLearnedInRange(from, today);
  }

  // --- Persistence (unchanged) ---
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
       final current = getStreak();
       await _prefs.setInt('user_streak', current + 1);
       await _prefs.setString('last_quiz_date', today);
    }
  }

  double getModuleProgress(String moduleId) => _prefs.getDouble('progress_$moduleId') ?? 0.0;

  Future<void> setModuleProgress(String moduleId, double progress) async {
    final current = getModuleProgress(moduleId);
    if (progress > current) {
      await _prefs.setDouble('progress_$moduleId', progress);
    }
  }
}
