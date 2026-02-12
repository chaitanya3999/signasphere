import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/theme_controller.dart';
import '../data/quiz_asset_service.dart';

final learnControllerProvider = StateNotifierProvider<LearnController, LearnState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final assetService = ref.watch(quizAssetServiceProvider);
  return LearnController(prefs, assetService);
});

class LearnState {
  final int xp;
  final int streak;
  final int level;
  final int totalQuizzesPlayed;
  final double accuracy; // 0.0 to 1.0
  final int knownWordsCount;
  final bool isLoading;

  LearnState({
    required this.xp,
    required this.streak,
    required this.level,
    required this.totalQuizzesPlayed,
    required this.accuracy,
    required this.knownWordsCount,
    this.isLoading = false,
  });

  LearnState copyWith({
    int? xp,
    int? streak,
    int? level,
    int? totalQuizzesPlayed,
    double? accuracy,
    int? knownWordsCount,
    bool? isLoading,
  }) {
    return LearnState(
      xp: xp ?? this.xp,
      streak: streak ?? this.streak,
      level: level ?? this.level,
      totalQuizzesPlayed: totalQuizzesPlayed ?? this.totalQuizzesPlayed,
      accuracy: accuracy ?? this.accuracy,
      knownWordsCount: knownWordsCount ?? this.knownWordsCount,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class LearnController extends StateNotifier<LearnState> {
  final SharedPreferences _prefs;
  final QuizAssetService _assetService;

  LearnController(this._prefs, this._assetService)
      : super(LearnState(
            xp: 0,
            streak: 0,
            level: 1,
            totalQuizzesPlayed: 0,
            accuracy: 0.0,
            knownWordsCount: 0)) {
    _init();
  }

  Future<void> _init() async {
    print("LearnController: Initializing...");
    state = state.copyWith(isLoading: true);

    // Load Assets
    print("LearnController: Calling AssetService.initialize...");
    await _assetService.initialize();
    print("LearnController: AssetService returned.");

    // Load Persistence
    final xp = _prefs.getInt('user_xp') ?? 0;
    final streak = _prefs.getInt('user_streak') ?? 0;
    final level = (xp / 100).floor() + 1;
    final totalQuizzes = _prefs.getInt('total_quizzes') ?? 0;
    final accuracy = _prefs.getDouble('global_accuracy') ?? 0.0;
    final knownWords = _prefs.getStringList('known_words')?.length ?? 0;

    state = state.copyWith(
      xp: xp,
      streak: streak,
      level: level,
      totalQuizzesPlayed: totalQuizzes,
      accuracy: accuracy,
      knownWordsCount: knownWords,
      isLoading: false,
    );

    _checkStreak();
  }

  Future<void> _checkStreak() async {
    final lastDateStr = _prefs.getString('last_activity_date');
    if (lastDateStr == null) return;

    final lastDate = DateTime.parse(lastDateStr);
    final now = DateTime.now();
    final difference = now.difference(lastDate).inDays;

    if (difference > 1) {
      // Streak broken
      await _prefs.setInt('user_streak', 0);
      state = state.copyWith(streak: 0);
    }
  }

  Future<void> recordQuizSession({
    required int xpEarned, 
    required int correctCount, 
    required int totalQuestions
  }) async {
    final currentXp = state.xp + xpEarned;
    
    // Update Streak
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}";
    final lastDateStr = _prefs.getString('last_activity_date');
    
    int newStreak = state.streak;
    if (lastDateStr != todayStr) {
      // If last date was yesterday, increment. If null (first time), start at 1.
      // If streak was broken (checked in init), it reset to 0, so increment to 1.
      if (lastDateStr == null) {
         newStreak = 1;
      } else {
         final lastDate = DateTime.parse(lastDateStr);
         if (now.difference(lastDate).inDays == 1) {
           newStreak++;
         } else if (now.difference(lastDate).inDays > 1) {
           newStreak = 1; // Reset if > 1 day gap logic didn't catch it or just to be safe
         } else {
           // Same day, no change
         }
      }
      await _prefs.setString('last_activity_date', todayStr);
      await _prefs.setInt('user_streak', newStreak);
    }

    // Update Accuracy (Moving Average)
    final totalQsAnswered = _prefs.getInt('total_questions_answered') ?? 0;
    final totalCorrect = _prefs.getInt('total_correct_answers') ?? 0;
    
    final newTotalQs = totalQsAnswered + totalQuestions;
    final newTotalCorrect = totalCorrect + correctCount;
    final newAccuracy = newTotalQs > 0 ? (newTotalCorrect / newTotalQs) : 0.0;

    await _prefs.setInt('total_questions_answered', newTotalQs);
    await _prefs.setInt('total_correct_answers', newTotalCorrect);
    await _prefs.setDouble('global_accuracy', newAccuracy);
    
    final newTotalQuizzes = state.totalQuizzesPlayed + 1;
    await _prefs.setInt('total_quizzes', newTotalQuizzes);
    await _prefs.setInt('user_xp', currentXp);

    state = state.copyWith(
      xp: currentXp,
      streak: newStreak,
      level: (currentXp / 100).floor() + 1,
      totalQuizzesPlayed: newTotalQuizzes,
      accuracy: newAccuracy,
    );
  }

  Future<void> markWordAsKnown(String label) async {
    final List<String> known = _prefs.getStringList('known_words') ?? [];
    if (!known.contains(label)) {
      known.add(label);
      await _prefs.setStringList('known_words', known);
      state = state.copyWith(knownWordsCount: known.length);
      
      // Bonus XP for learning a new word
      final currentXp = state.xp + 5;
      await _prefs.setInt('user_xp', currentXp);
      state = state.copyWith(xp: currentXp, level: (currentXp / 100).floor() + 1);
    }
  }
}
