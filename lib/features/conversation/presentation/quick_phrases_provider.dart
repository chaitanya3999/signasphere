import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/quick_phrases_repository.dart';

final quickPhrasesProvider = StateNotifierProvider<QuickPhrasesController, List<String>>((ref) {
  final repository = ref.watch(quickPhrasesRepositoryProvider);
  return QuickPhrasesController(repository);
});

class QuickPhrasesController extends StateNotifier<List<String>> {
  final QuickPhrasesRepository _repository;

  QuickPhrasesController(this._repository) : super([]) {
    _loadPhrases();
  }

  void _loadPhrases() {
    state = _repository.getPhrases();
  }

  Future<void> addPhrase(String phrase) async {
    if (phrase.trim().isEmpty) return;
    if (state.contains(phrase)) return;
    if (state.length >= 12) return; // Max 12 limit
    if (phrase.length > 30) return; // Max 30 chars

    final newState = [...state, phrase];
    state = newState;
    await _repository.savePhrases(newState);
  }

  Future<void> removePhrase(String phrase) async {
    final newState = state.where((p) => p != phrase).toList();
    state = newState;
    await _repository.savePhrases(newState);
  }

  Future<void> resetToDefaults() async {
    final defaults = [
      "I need help",
      "I am hungry",
      "I am thirsty",
      "I want toilet",
      "I feel pain",
      "I am scared",
      "Where is mom?",
      "Thank you",
    ];
    state = defaults;
    await _repository.savePhrases(defaults);
  }
}
