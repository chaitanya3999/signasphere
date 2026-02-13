import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/theme_controller.dart';

// Key for storing quick phrases
const String _kQuickPhrasesKey = 'quick_phrases_v1';

final quickPhrasesRepositoryProvider = Provider<QuickPhrasesRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return QuickPhrasesRepository(prefs);
});

class QuickPhrasesRepository {
  final SharedPreferences _prefs;

  QuickPhrasesRepository(this._prefs);

  List<String> getPhrases() {
    final list = _prefs.getStringList(_kQuickPhrasesKey);
    if (list != null && list.isNotEmpty) {
      return list;
    }
    // Return defaults if empty
    return [
      "I need help",
      "I am hungry",
      "I am thirsty",
      "I want toilet",
      "I feel pain",
      "I am scared",
      "Where is mom?",
      "Thank you",
    ];
  }

  Future<void> savePhrases(List<String> phrases) async {
    await _prefs.setStringList(_kQuickPhrasesKey, phrases);
  }

  Future<void> addPhrase(String phrase) async {
    final current = getPhrases();
    if (!current.contains(phrase)) {
      current.add(phrase);
      await savePhrases(current);
    }
  }

  Future<void> removePhrase(String phrase) async {
    final current = getPhrases();
    current.remove(phrase);
    await savePhrases(current);
  }
}
