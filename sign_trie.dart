/// sign_trie.dart
/// Located: lib/core/services/dsa/sign_trie.dart
///
/// USE CASE:
///   - Avatar tab: Autocomplete words as user types (e.g., "He" → [Hello, Help, Hey])
///   - Learn Mode: Word search in the sign dictionary
///   - Conversation Mode: Quick word suggestions while composing messages
///
/// TIME COMPLEXITY:
///   insert()      → O(m)       m = word length
///   search()      → O(m)
///   autoComplete() → O(m + k)  k = number of results

class TrieNode {
  final Map<String, TrieNode> children = {};
  bool isEndOfWord = false;
  SignData? signData;
}

/// Metadata for each sign — mirrors your existing sign model
class SignData {
  final String word;
  final String gifAssetPath;  // e.g., "assets/signs/hello.gif"
  final String category;      // "greetings", "emotions", "needs", "food", "emergency"
  final String description;   // Short instruction text for Learn mode
  final String avatarAnimKey; // Key to trigger 3D avatar animation

  const SignData({
    required this.word,
    required this.gifAssetPath,
    required this.category,
    required this.description,
    required this.avatarAnimKey,
  });
}

class SignTrie {
  final TrieNode _root = TrieNode();

  // ─── Public API ───────────────────────────────────────────────

  /// Insert a sign into the Trie
  void insert(SignData sign) {
    TrieNode node = _root;
    for (final char in sign.word.toLowerCase().split('')) {
      node.children.putIfAbsent(char, TrieNode.new);
      node = node.children[char]!;
    }
    node.isEndOfWord = true;
    node.signData = sign;
  }

  /// Exact word lookup — used when Avatar tab receives full word input
  SignData? search(String word) {
    TrieNode? node = _navigateTo(word.toLowerCase());
    return (node != null && node.isEndOfWord) ? node.signData : null;
  }

  /// Check if any word starts with prefix
  bool startsWith(String prefix) {
    return _navigateTo(prefix.toLowerCase()) != null;
  }

  /// Autocomplete — returns suggestions as user types in Avatar/Learn/Conversation
  /// [prefix] — what the user has typed so far
  /// [limit]  — max suggestions (default 8 for the suggestion row UI)
  List<SignData> autoComplete(String prefix, {int limit = 8}) {
    final TrieNode? node = _navigateTo(prefix.toLowerCase());
    if (node == null) return [];

    final List<SignData> results = [];
    _dfs(node, results, limit);
    return results;
  }

  /// Delete a sign (e.g., admin removing a word from the dictionary)
  bool delete(String word) {
    return _deleteHelper(_root, word.toLowerCase(), 0);
  }

  /// Get all signs in the Trie (for exporting/syncing)
  List<SignData> getAllSigns() {
    final List<SignData> results = [];
    _dfs(_root, results, double.maxFinite.toInt());
    return results;
  }

  // ─── Private Helpers ──────────────────────────────────────────

  TrieNode? _navigateTo(String prefix) {
    TrieNode node = _root;
    for (final char in prefix.split('')) {
      if (!node.children.containsKey(char)) return null;
      node = node.children[char]!;
    }
    return node;
  }

  void _dfs(TrieNode node, List<SignData> results, int limit) {
    if (results.length >= limit) return;
    if (node.isEndOfWord && node.signData != null) {
      results.add(node.signData!);
    }
    for (final child in node.children.values) {
      if (results.length >= limit) return;
      _dfs(child, results, limit);
    }
  }

  bool _deleteHelper(TrieNode node, String word, int depth) {
    if (depth == word.length) {
      if (!node.isEndOfWord) return false;
      node.isEndOfWord = false;
      node.signData = null;
      return node.children.isEmpty;
    }
    final char = word[depth];
    if (!node.children.containsKey(char)) return false;

    final shouldDelete = _deleteHelper(node.children[char]!, word, depth + 1);
    if (shouldDelete) {
      node.children.remove(char);
      return !node.isEndOfWord && node.children.isEmpty;
    }
    return false;
  }
}

// ─── Example Usage (in your service/provider layer) ───────────────
//
// final trie = SignTrie();
//
// trie.insert(SignData(
//   word: 'hello',
//   gifAssetPath: 'assets/signs/hello.gif',
//   category: 'greetings',
//   description: 'Wave from forehead outward',
//   avatarAnimKey: 'anim_hello',
// ));
//
// // Avatar tab — user typed "hel"
// final suggestions = trie.autoComplete('hel'); // → [hello, help]
//
// // Full word submitted → trigger avatar animation
// final sign = trie.search('hello');
// if (sign != null) triggerAvatarAnimation(sign.avatarAnimKey);
