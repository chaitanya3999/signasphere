/// ═══════════════════════════════════════════════════════════════════
/// PRIORITY QUEUE (Max-Heap) — Usage-Ranked Quick Message System
/// ═══════════════════════════════════════════════════════════════════
///
/// Time Complexity:
///   - Insert:          O(log N)
///   - Extract Max:     O(log N)
///   - Peek:            O(1)
///   - getRankedList:   O(N log N)
///
/// Space Complexity: O(N)
///
/// Used in: Conversation Quick Actions — most-used phrases bubble to top
/// ═══════════════════════════════════════════════════════════════════

class PhraseEntry implements Comparable<PhraseEntry> {
  final String phrase;
  int usageCount;

  PhraseEntry({required this.phrase, this.usageCount = 0});

  @override
  int compareTo(PhraseEntry other) => usageCount.compareTo(other.usageCount);

  @override
  String toString() => 'PhraseEntry("$phrase", count=$usageCount)';

  Map<String, dynamic> toJson() => {'phrase': phrase, 'count': usageCount};

  factory PhraseEntry.fromJson(Map<String, dynamic> json) {
    return PhraseEntry(
      phrase: json['phrase'] as String,
      usageCount: json['count'] as int? ?? 0,
    );
  }
}

class PriorityQueue {
  final List<PhraseEntry> _heap = [];

  /// Insert a phrase entry maintaining heap order.
  void insert(PhraseEntry entry) {
    _heap.add(entry);
    _siftUp(_heap.length - 1);
    _log('INSERT', '${entry.phrase} (count=${entry.usageCount}), heap size=${_heap.length}');
  }

  /// Peek at the highest-priority (most-used) phrase.
  PhraseEntry? peek() => _heap.isNotEmpty ? _heap[0] : null;

  /// Extract the highest-priority element.
  PhraseEntry? extractMax() {
    if (_heap.isEmpty) return null;
    final max = _heap[0];
    final last = _heap.removeLast();
    if (_heap.isNotEmpty) {
      _heap[0] = last;
      _siftDown(0);
    }
    _log('EXTRACT', 'Removed "${max.phrase}" (count=${max.usageCount})');
    return max;
  }

  /// Increment usage count for a phrase and re-heapify.
  void incrementUsage(String phrase) {
    final index = _heap.indexWhere((e) => e.phrase == phrase);
    if (index == -1) {
      // New phrase — insert with count 1
      insert(PhraseEntry(phrase: phrase, usageCount: 1));
      _log('REORDER', 'New phrase "$phrase" added with count=1');
      return;
    }

    _heap[index].usageCount++;
    _siftUp(index); // Count increased → may need to move up
    _log('REORDER', '"$phrase" usage → ${_heap[index].usageCount}, reheapified');
  }

  /// Get all phrases ranked by usage (descending).
  List<PhraseEntry> getRankedList() {
    final sorted = List<PhraseEntry>.from(_heap);
    sorted.sort((a, b) => b.usageCount.compareTo(a.usageCount));
    return sorted;
  }

  /// Get ranked phrase strings only.
  List<String> getRankedPhrases() {
    return getRankedList().map((e) => e.phrase).toList();
  }

  /// Rebuild heap from a flat list of entries.
  void buildFrom(List<PhraseEntry> entries) {
    _heap.clear();
    _heap.addAll(entries);
    // Floyd's algorithm: O(N) heap construction
    for (int i = (_heap.length ~/ 2) - 1; i >= 0; i--) {
      _siftDown(i);
    }
    _log('BUILD', 'Rebuilt heap with ${_heap.length} entries');
  }

  /// Current size.
  int get size => _heap.length;
  bool get isEmpty => _heap.isEmpty;

  /// Export all entries (for persistence).
  List<PhraseEntry> get allEntries => List.unmodifiable(_heap);

  // ─── Heap Operations ───

  void _siftUp(int index) {
    while (index > 0) {
      final parent = (index - 1) ~/ 2;
      if (_heap[index].usageCount > _heap[parent].usageCount) {
        _swap(index, parent);
        index = parent;
      } else {
        break;
      }
    }
  }

  void _siftDown(int index) {
    final size = _heap.length;
    while (true) {
      int largest = index;
      final left = 2 * index + 1;
      final right = 2 * index + 2;

      if (left < size && _heap[left].usageCount > _heap[largest].usageCount) {
        largest = left;
      }
      if (right < size && _heap[right].usageCount > _heap[largest].usageCount) {
        largest = right;
      }
      if (largest == index) break;
      _swap(index, largest);
      index = largest;
    }
  }

  void _swap(int i, int j) {
    final temp = _heap[i];
    _heap[i] = _heap[j];
    _heap[j] = temp;
  }

  void _log(String op, String msg) {
    print('[DS:MaxHeap][$op] $msg');
  }
}
