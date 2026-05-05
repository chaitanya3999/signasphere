// ═══════════════════════════════════════════════════════════════════
// TRIE (Prefix Tree) — Efficient Word Lookup & Suggestion Engine
// ═══════════════════════════════════════════════════════════════════
//
// Time Complexity:
//   - Insert: O(L) where L = word length
//   - Search: O(L)
//   - Prefix Suggestions: O(L + K) where K = results
//
// Space Complexity: O(N × L) where N = total words
//
// Used in: Learn Mode (word lookup), Conversation (suggestions),
//          Avatar (sign-sequence mapping)
// ═══════════════════════════════════════════════════════════════════

class TrieNode {
  final Map<String, TrieNode> children = {};
  bool isEndOfWord = false;
  String? signSequence; // Maps word → sign animation path
  String? category; // e.g., "FOOD", "EMOTION", "ACTION"
  int searchCount = 0; // Track popularity for analytics

  TrieNode();
}

class Trie {
  final TrieNode _root = TrieNode();
  int _totalWords = 0;
  int _totalSearches = 0;

  /// Insert a word with optional metadata.
  ///
  /// ```dart
  /// trie.insert('apple', category: 'FOOD', signSequence: 'assets/signs/words/APPLE.mp4');
  /// ```
  void insert(String word, {String? category, String? signSequence}) {
    TrieNode current = _root;
    final normalized = word.toLowerCase().trim();

    for (final char in normalized.split('')) {
      current.children.putIfAbsent(char, () => TrieNode());
      current = current.children[char]!;
    }

    if (!current.isEndOfWord) _totalWords++;
    current.isEndOfWord = true;
    current.category = category;
    current.signSequence = signSequence;

    _log('INSERT', 'Inserted "$normalized" [cat=$category]');
  }

  /// Exact word lookup. Returns true if word exists.
  bool search(String word) {
    _totalSearches++;
    final node = _findNode(word.toLowerCase().trim());
    final found = node != null && node.isEndOfWord;

    if (found) node!.searchCount++;
    _log('SEARCH', '"$word" → ${found ? "HIT ✓" : "MISS ✗"}');
    return found;
  }

  /// Get sign sequence path for a word (null if not mapped).
  String? getSignSequence(String word) {
    final node = _findNode(word.toLowerCase().trim());
    return (node != null && node.isEndOfWord) ? node.signSequence : null;
  }

  /// Get category of a word.
  String? getCategory(String word) {
    final node = _findNode(word.toLowerCase().trim());
    return (node != null && node.isEndOfWord) ? node.category : null;
  }

  /// Return all words that start with [prefix].
  ///
  /// ```dart
  /// trie.getSuggestions('hel'); // → ['hello', 'help']
  /// ```
  List<String> getSuggestions(String prefix, {int maxResults = 10}) {
    final normalized = prefix.toLowerCase().trim();
    final node = _findNode(normalized);
    if (node == null) {
      _log('SUGGEST', '"$prefix" → 0 results');
      return [];
    }

    final results = <String>[];
    _collectWords(node, normalized, results, maxResults);

    _log('SUGGEST', '"$prefix" → ${results.length} results: $results');
    return results;
  }

  /// Return all words in a given category.
  List<String> getWordsByCategory(String category) {
    final results = <String>[];
    _collectByCategory(_root, '', category.toUpperCase(), results);
    return results;
  }

  /// Total words stored in the Trie.
  int get totalWords => _totalWords;

  /// Total search operations performed.
  int get totalSearches => _totalSearches;

  // ─── Private Helpers ───

  TrieNode? _findNode(String word) {
    TrieNode current = _root;
    for (final char in word.split('')) {
      if (!current.children.containsKey(char)) return null;
      current = current.children[char]!;
    }
    return current;
  }

  void _collectWords(
    TrieNode node,
    String prefix,
    List<String> results,
    int max,
  ) {
    if (results.length >= max) return;
    if (node.isEndOfWord) results.add(prefix);

    for (final entry in node.children.entries) {
      _collectWords(entry.value, prefix + entry.key, results, max);
    }
  }

  void _collectByCategory(
    TrieNode node,
    String prefix,
    String category,
    List<String> results,
  ) {
    if (node.isEndOfWord && node.category == category) {
      results.add(prefix);
    }
    for (final entry in node.children.entries) {
      _collectByCategory(entry.value, prefix + entry.key, category, results);
    }
  }

  void _log(String op, String msg) {
    print('[DS:Trie][$op] $msg');
  }
}
