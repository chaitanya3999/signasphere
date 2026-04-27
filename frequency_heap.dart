/// frequency_heap.dart
/// Located: lib/core/services/dsa/frequency_heap.dart
///
/// USE CASE:
///   - Home Dashboard: The "quick tiles" show the user's top N most-used signs
///   - Conversation Mode: Suggests frequently-used phrases at the top
///   - Personalization: Every user builds their own frequency profile
///   - Hospital/Emergency mode (your roadmap): Critical signs bubble to top
///
/// TIME COMPLEXITY:
///   push()               → O(log n)
///   peek()               → O(1)
///   pop()                → O(log n)
///   incrementFrequency() → O(log n)
///   getTopN()            → O(k log n)

class FrequencyEntry {
  String word;
  int frequency;
  final String category;
  final String gifAssetPath;
  final String avatarAnimKey;

  FrequencyEntry({
    required this.word,
    required this.frequency,
    required this.category,
    required this.gifAssetPath,
    required this.avatarAnimKey,
  });

  /// For displaying in the Home quick-tiles UI
  @override
  String toString() => '$word ($frequency uses)';
}

class FrequencyHeap {
  final List<FrequencyEntry> _heap = [];
  final Map<String, int> _indexMap = {}; // word → heap index for O(log n) updates

  // ─── Public API ───────────────────────────────────────────────

  /// Add a sign with its known usage count
  /// Called on app startup when loading saved frequency data
  void push(FrequencyEntry entry) {
    _heap.add(entry);
    final idx = _heap.length - 1;
    _indexMap[entry.word] = idx;
    _bubbleUp(idx);
  }

  /// Returns the most-used sign without removing it
  /// Used to highlight the #1 sign on the dashboard
  FrequencyEntry? peek() => _heap.isNotEmpty ? _heap[0] : null;

  /// Remove and return the most-used sign
  FrequencyEntry? pop() {
    if (_heap.isEmpty) return null;
    if (_heap.length == 1) {
      final top = _heap.removeLast();
      _indexMap.remove(top.word);
      return top;
    }
    final top = _heap[0];
    final last = _heap.removeLast();
    _heap[0] = last;
    _indexMap[last.word] = 0;
    _indexMap.remove(top.word);
    _sinkDown(0);
    return top;
  }

  /// Called every time the user taps a sign in the app
  /// This is the key method — wire it to every sign interaction
  void onSignUsed(String word) {
    final idx = _indexMap[word];
    if (idx == null) {
      // First time using this sign — add it
      push(FrequencyEntry(
        word: word,
        frequency: 1,
        category: 'unknown',
        gifAssetPath: '',
        avatarAnimKey: '',
      ));
      return;
    }
    _heap[idx].frequency++;
    _bubbleUp(idx); // Might need to move up after frequency increase
  }

  /// Get top N signs for the Home quick-tiles
  /// Does NOT mutate the heap (uses a clone)
  List<FrequencyEntry> getTopN(int n) {
    // Clone to avoid mutating original
    final cloneHeap = FrequencyHeap();
    for (final entry in _heap) {
      cloneHeap.push(FrequencyEntry(
        word: entry.word,
        frequency: entry.frequency,
        category: entry.category,
        gifAssetPath: entry.gifAssetPath,
        avatarAnimKey: entry.avatarAnimKey,
      ));
    }
    final result = <FrequencyEntry>[];
    for (int i = 0; i < n && cloneHeap._heap.isNotEmpty; i++) {
      final top = cloneHeap.pop();
      if (top != null) result.add(top);
    }
    return result;
  }

  /// Get top signs filtered by category
  /// Used for the Hospital/Emergency special mode in your roadmap
  List<FrequencyEntry> getTopByCategory(String category, {int limit = 6}) {
    final filtered = _heap
        .where((e) => e.category == category)
        .toList()
      ..sort((a, b) => b.frequency.compareTo(a.frequency));
    return filtered.take(limit).toList();
  }

  bool contains(String word) => _indexMap.containsKey(word);
  int get size => _heap.length;

  /// Serialize for persistence (SharedPreferences / local DB)
  List<Map<String, dynamic>> toJson() => _heap.map((e) => {
    'word': e.word,
    'frequency': e.frequency,
    'category': e.category,
    'gifAssetPath': e.gifAssetPath,
    'avatarAnimKey': e.avatarAnimKey,
  }).toList();

  /// Restore from saved JSON on app startup
  factory FrequencyHeap.fromJson(List<Map<String, dynamic>> data) {
    final heap = FrequencyHeap();
    for (final item in data) {
      heap.push(FrequencyEntry(
        word: item['word'],
        frequency: item['frequency'],
        category: item['category'],
        gifAssetPath: item['gifAssetPath'],
        avatarAnimKey: item['avatarAnimKey'],
      ));
    }
    return heap;
  }

  // ─── Private Helpers ──────────────────────────────────────────

  void _bubbleUp(int idx) {
    while (idx > 0) {
      final parentIdx = (idx - 1) ~/ 2;
      if (_heap[parentIdx].frequency >= _heap[idx].frequency) break;
      _swap(parentIdx, idx);
      idx = parentIdx;
    }
  }

  void _sinkDown(int idx) {
    final n = _heap.length;
    while (true) {
      int largest = idx;
      final left  = 2 * idx + 1;
      final right = 2 * idx + 2;

      if (left  < n && _heap[left].frequency  > _heap[largest].frequency) largest = left;
      if (right < n && _heap[right].frequency > _heap[largest].frequency) largest = right;

      if (largest == idx) break;
      _swap(idx, largest);
      idx = largest;
    }
  }

  void _swap(int i, int j) {
    _indexMap[_heap[i].word] = j;
    _indexMap[_heap[j].word] = i;
    final temp = _heap[i];
    _heap[i] = _heap[j];
    _heap[j] = temp;
  }
}

// ─── Example Usage (wire into Riverpod provider) ──────────────────
//
// // In your Riverpod provider:
// final frequencyHeapProvider = StateNotifierProvider<FrequencyNotifier, List<FrequencyEntry>>(
//   (ref) => FrequencyNotifier(),
// );
//
// class FrequencyNotifier extends StateNotifier<List<FrequencyEntry>> {
//   final FrequencyHeap _heap = FrequencyHeap();
//
//   FrequencyNotifier() : super([]);
//
//   void onSignTapped(String word) {
//     _heap.onSignUsed(word);
//     state = _heap.getTopN(6); // Update home quick-tiles (6 tiles)
//   }
// }
