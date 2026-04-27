/// sign_avl_tree.dart
/// Located: lib/core/services/dsa/sign_avl_tree.dart
///
/// USE CASE:
///   - Learn Mode: Full sign dictionary stored in sorted order with O(log n) ops
///   - A-Z lesson browsing (the gamified lessons go in alphabetical order)
///   - Category filtering: "Show me all Emotion signs" in sorted order
///   - Admin: Adding/removing signs from the dictionary stays fast always
///
/// TIME COMPLEXITY (self-balancing guarantee — always):
///   insert()    → O(log n)
///   delete()    → O(log n)
///   search()    → O(log n)
///   inOrder()   → O(n)      ← for sorted dictionary display

class AVLNode {
  String word;
  SignEntry data;
  AVLNode? left;
  AVLNode? right;
  int height;

  AVLNode(this.word, this.data) : height = 1;
}

/// Rich sign entry for Learn Mode
class SignEntry {
  final String word;
  final String gifAssetPath;
  final String category;
  final String description;        // "Wave from forehead outward"
  final String avatarAnimKey;
  final int difficultyLevel;       // 1=Beginner, 2=Intermediate, 3=Advanced (for Learn Mode)
  final List<String> tags;         // ["common", "greeting", "daily"]
  bool isLearned;                  // Tracks gamification progress

  SignEntry({
    required this.word,
    required this.gifAssetPath,
    required this.category,
    required this.description,
    required this.avatarAnimKey,
    this.difficultyLevel = 1,
    this.tags = const [],
    this.isLearned = false,
  });
}

class SignAVLTree {
  AVLNode? _root;
  int _size = 0;

  int get size => _size;

  // ─── Public API ───────────────────────────────────────────────

  /// Insert a sign into the dictionary
  void insert(SignEntry entry) {
    _root = _insert(_root, entry.word.toLowerCase(), entry);
    _size++;
  }

  /// Exact search — O(log n)
  SignEntry? search(String word) {
    final node = _search(_root, word.toLowerCase());
    return node?.data;
  }

  /// Delete a sign
  bool delete(String word) {
    final before = _size;
    _root = _delete(_root, word.toLowerCase());
    return _size < before;
  }

  /// In-order traversal → alphabetically sorted list
  /// Powers the A-Z dictionary view in Learn Mode
  List<SignEntry> getSortedDictionary() {
    final result = <SignEntry>[];
    _inOrder(_root, result);
    return result;
  }

  /// Filter by category — still returns sorted results
  /// Powers category tabs in Learn Mode (Greetings | Emotions | Needs | Food)
  List<SignEntry> getByCategory(String category) {
    return getSortedDictionary()
        .where((s) => s.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  /// Filter by difficulty — for gamified lesson progression
  List<SignEntry> getByDifficulty(int level) {
    return getSortedDictionary()
        .where((s) => s.difficultyLevel == level)
        .toList();
  }

  /// Range query — get all signs starting with letters in [start, end]
  /// Powers alphabetical section headers in the Learn Mode list
  List<SignEntry> getRange(String startChar, String endChar) {
    final result = <SignEntry>[];
    _rangeQuery(_root, startChar.toLowerCase(), endChar.toLowerCase(), result);
    return result;
  }

  /// Mark a sign as learned (gamification progress)
  void markAsLearned(String word) {
    final node = _search(_root, word.toLowerCase());
    if (node != null) node.data.isLearned = true;
  }

  /// Get learning progress stats
  Map<String, int> getProgressStats() {
    final all = getSortedDictionary();
    final learned = all.where((s) => s.isLearned).length;
    return {
      'total': all.length,
      'learned': learned,
      'remaining': all.length - learned,
    };
  }

  // ─── Private: Core AVL Operations ─────────────────────────────

  AVLNode _insert(AVLNode? node, String word, SignEntry data) {
    if (node == null) return AVLNode(word, data);

    if (word.compareTo(node.word) < 0) {
      node.left = _insert(node.left, word, data);
    } else if (word.compareTo(node.word) > 0) {
      node.right = _insert(node.right, word, data);
    } else {
      node.data = data; // Update existing
      _size--;          // Don't double-count
      return node;
    }

    _updateHeight(node);
    return _balance(node);
  }

  AVLNode? _delete(AVLNode? node, String word) {
    if (node == null) return null;

    if (word.compareTo(node.word) < 0) {
      node.left = _delete(node.left, word);
    } else if (word.compareTo(node.word) > 0) {
      node.right = _delete(node.right, word);
    } else {
      _size--;
      if (node.left == null || node.right == null) {
        return node.left ?? node.right;
      }
      // Replace with in-order successor
      final successor = _getMin(node.right!);
      node.word = successor.word;
      node.data = successor.data;
      node.right = _delete(node.right, successor.word);
      _size++; // Compensate for the recursive delete above
    }

    _updateHeight(node);
    return _balance(node);
  }

  AVLNode? _search(AVLNode? node, String word) {
    if (node == null) return null;
    final cmp = word.compareTo(node.word);
    if (cmp == 0) return node;
    if (cmp < 0)  return _search(node.left,  word);
    return              _search(node.right, word);
  }

  // ─── Private: Balancing ───────────────────────────────────────

  AVLNode _balance(AVLNode node) {
    final bf = _balanceFactor(node);

    // Left Heavy
    if (bf > 1) {
      if (_balanceFactor(node.left!) < 0) {
        node.left = _rotateLeft(node.left!); // Left-Right
      }
      return _rotateRight(node);             // Left-Left
    }

    // Right Heavy
    if (bf < -1) {
      if (_balanceFactor(node.right!) > 0) {
        node.right = _rotateRight(node.right!); // Right-Left
      }
      return _rotateLeft(node);                 // Right-Right
    }

    return node;
  }

  AVLNode _rotateRight(AVLNode y) {
    final x  = y.left!;
    final t2 = x.right;
    x.right = y;
    y.left  = t2;
    _updateHeight(y);
    _updateHeight(x);
    return x;
  }

  AVLNode _rotateLeft(AVLNode x) {
    final y  = x.right!;
    final t2 = y.left;
    y.left  = x;
    x.right = t2;
    _updateHeight(x);
    _updateHeight(y);
    return y;
  }

  // ─── Private: Traversals & Utilities ─────────────────────────

  void _inOrder(AVLNode? node, List<SignEntry> result) {
    if (node == null) return;
    _inOrder(node.left,  result);
    result.add(node.data);
    _inOrder(node.right, result);
  }

  void _rangeQuery(AVLNode? node, String start, String end, List<SignEntry> result) {
    if (node == null) return;
    if (node.word.compareTo(start) > 0) _rangeQuery(node.left,  start, end, result);
    if (node.word.compareTo(start) >= 0 && node.word.compareTo(end) <= 0) result.add(node.data);
    if (node.word.compareTo(end)   < 0) _rangeQuery(node.right, start, end, result);
  }

  int _height(AVLNode? node) => node?.height ?? 0;
  int _balanceFactor(AVLNode node) => _height(node.left) - _height(node.right);
  void _updateHeight(AVLNode node) =>
      node.height = 1 + [_height(node.left), _height(node.right)].reduce((a, b) => a > b ? a : b);

  AVLNode _getMin(AVLNode node) {
    while (node.left != null) node = node.left!;
    return node;
  }
}

// ─── Example Usage (wire into Learn Mode provider) ────────────────
//
// final dictionaryProvider = Provider<SignAVLTree>((ref) {
//   final tree = SignAVLTree();
//   // Load from your assets/signs_data.json
//   for (final sign in signDataList) {
//     tree.insert(SignEntry(
//       word: sign['word'],
//       gifAssetPath: sign['gifAssetPath'],
//       category: sign['category'],
//       description: sign['description'],
//       avatarAnimKey: sign['avatarAnimKey'],
//       difficultyLevel: sign['level'],
//     ));
//   }
//   return tree;
// });
//
// // In Learn Mode screen:
// final beginnerSigns = ref.watch(dictionaryProvider).getByDifficulty(1);
// final greetings     = ref.watch(dictionaryProvider).getByCategory('greetings');
// final progress      = ref.watch(dictionaryProvider).getProgressStats();
