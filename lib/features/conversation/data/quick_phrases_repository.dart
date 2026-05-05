import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/data_structures/ds_manager.dart';

const String _kQuickPhrasesKey = 'quick_phrases_v1';
const String _kPhraseUsageKey = 'phrase_usage_heap';

final quickPhrasesRepositoryProvider = Provider<QuickPhrasesRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final heap = ref.watch(phraseHeapProvider);
  return QuickPhrasesRepository(prefs, heap);
});

// PRIORITY QUEUE: Ranked Quick Phrases
// Max-Heap (Priority Queue) to rank phrases by usage count.

class QuickPhrasesRepository {
  final SharedPreferences _prefs;
  final PriorityQueue _heap;

  QuickPhrasesRepository(this._prefs, this._heap) {
    _loadUsageData();
  }

  /// Get phrases ranked by usage (Priority Queue ordering).
  List<String> getPhrases() {
    final ranked = _heap.getRankedPhrases();
    if (ranked.isNotEmpty) return ranked;

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

  /// Record that a phrase was used — heap reorders automatically.
  Future<void> recordUsage(String phrase) async {
    _heap.incrementUsage(phrase);
    await _persistUsageData();
  }

  Future<void> savePhrases(List<String> phrases) async {
    await _prefs.setStringList(_kQuickPhrasesKey, phrases);
  }

  Future<void> addPhrase(String phrase) async {
    _heap.incrementUsage(phrase);
    final current = getPhrases();
    if (!current.contains(phrase)) {
      await savePhrases([...current, phrase]);
    }
    await _persistUsageData();
  }

  Future<void> removePhrase(String phrase) async {
    final current = getPhrases();
    current.remove(phrase);
    await savePhrases(current);
  }

  // ─── Persistence ───

  void _loadUsageData() {
    final json = _prefs.getString(_kPhraseUsageKey);
    if (json != null) {
      try {
        final list = jsonDecode(json) as List;
        final entries = list.map((e) => PhraseEntry.fromJson(e)).toList();
        _heap.buildFrom(entries);
        print(
          '[DS:QuickPhrases] Loaded ${entries.length} usage entries from storage',
        );
      } catch (_) {}
    }
  }

  Future<void> _persistUsageData() async {
    final entries = _heap.allEntries.map((e) => e.toJson()).toList();
    await _prefs.setString(_kPhraseUsageKey, jsonEncode(entries));
  }
}
