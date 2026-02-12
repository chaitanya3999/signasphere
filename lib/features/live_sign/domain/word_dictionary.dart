class WordDictionary {
  // Level 2 Vocabulary List
  static const Set<String> _vocabulary = {
    "HELLO",
    "THANK YOU",
    "HELP",
    "STOP",
    "WATER",
    "FOOD",
    "YES",
    "NO",
    "PLEASE",
    "GOOD",
    "BAD",
    "LOVE", // Added for fun
  };

  /// Checks if the end of the [sentence] matches any known word.
  /// Returns the matched word if found, otherwise null.
  String? findMatch(String sentence) {
    if (sentence.isEmpty) return null;

    // Normalize input
    final cleanSentence = sentence.toUpperCase().trim();

    // Check strict suffix matches
    // e.g. "AHHELLO" -> matches "HELLO"
    // e.g. "THE WATER" -> matches "WATER"

    for (final word in _vocabulary) {
      if (cleanSentence.endsWith(word)) {
        return word;
      }
    }

    return null;
  }
}