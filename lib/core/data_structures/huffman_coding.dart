import 'dart:collection';
import 'dart:convert';

/// ═══════════════════════════════════════════════════════════════════
/// HUFFMAN CODING — Lossless Text Compression for Chat Storage
/// ═══════════════════════════════════════════════════════════════════
///
/// Time Complexity:
///   - Build Tree:  O(N log N) where N = unique characters
///   - Encode:      O(M) where M = message length
///   - Decode:      O(M)
///
/// Space Complexity: O(N) for the tree + O(M) for encoded output
///
/// Used in: ConversationRepository — compress before SharedPreferences,
///          decompress on read. Reduces storage footprint.
/// ═══════════════════════════════════════════════════════════════════

class HuffmanNode implements Comparable<HuffmanNode> {
  final String? char;
  final int frequency;
  final HuffmanNode? left;
  final HuffmanNode? right;

  HuffmanNode({this.char, required this.frequency, this.left, this.right});

  bool get isLeaf => left == null && right == null;

  @override
  int compareTo(HuffmanNode other) => frequency.compareTo(other.frequency);
}

class HuffmanResult {
  final String encodedBits;    // Binary string representation
  final Map<String, String> codeTable; // char → binary code
  final int originalLength;
  final int compressedLength;  // in bits

  HuffmanResult({
    required this.encodedBits,
    required this.codeTable,
    required this.originalLength,
    required this.compressedLength,
  });

  double get compressionRatio =>
      originalLength > 0 ? (1 - (compressedLength / (originalLength * 8))) * 100 : 0;

  /// Serialize for storage.
  Map<String, dynamic> toJson() => {
        'bits': encodedBits,
        'table': codeTable,
        'origLen': originalLength,
      };

  factory HuffmanResult.fromJson(Map<String, dynamic> json) {
    return HuffmanResult(
      encodedBits: json['bits'] as String,
      codeTable: Map<String, String>.from(json['table'] as Map),
      originalLength: json['origLen'] as int,
      compressedLength: (json['bits'] as String).length,
    );
  }
}

class HuffmanCoding {
  /// Encode a string using Huffman coding.
  ///
  /// Returns null for empty strings.
  HuffmanResult? encode(String text) {
    if (text.isEmpty) return null;

    // 1. Build frequency map
    final freq = <String, int>{};
    for (final char in text.split('')) {
      freq[char] = (freq[char] ?? 0) + 1;
    }

    // 2. Build Huffman Tree using a priority queue (min-heap via SplayTreeSet)
    final pq = SplayTreeSet<HuffmanNode>((a, b) {
      final cmp = a.frequency.compareTo(b.frequency);
      if (cmp != 0) return cmp;
      // Tie-break by char to ensure deterministic ordering
      return (a.char ?? '').compareTo(b.char ?? '');
    });

    for (final entry in freq.entries) {
      pq.add(HuffmanNode(char: entry.key, frequency: entry.value));
    }

    // Handle single-character edge case
    if (pq.length == 1) {
      final only = pq.first;
      pq.add(HuffmanNode(char: null, frequency: 0));
      pq.add(HuffmanNode(
        frequency: only.frequency,
        left: only,
        right: pq.first,
      ));
      pq.remove(only);
    }

    while (pq.length > 1) {
      final left = pq.first;
      pq.remove(left);
      final right = pq.first;
      pq.remove(right);

      pq.add(HuffmanNode(
        frequency: left.frequency + right.frequency,
        left: left,
        right: right,
      ));
    }

    final root = pq.first;

    // 3. Build code table
    final codeTable = <String, String>{};
    _buildCodes(root, '', codeTable);

    // 4. Encode
    final buffer = StringBuffer();
    for (final char in text.split('')) {
      buffer.write(codeTable[char]);
    }
    final encoded = buffer.toString();

    final result = HuffmanResult(
      encodedBits: encoded,
      codeTable: codeTable,
      originalLength: text.length,
      compressedLength: encoded.length,
    );

    _log('ENCODE',
        'Original=${text.length} chars (${text.length * 8} bits), '
        'Compressed=${encoded.length} bits, '
        'Ratio=${result.compressionRatio.toStringAsFixed(1)}%');

    return result;
  }

  /// Decode a HuffmanResult back to the original string.
  String decode(HuffmanResult result) {
    // Invert the code table: binary code → char
    final reverseTable = <String, String>{};
    for (final entry in result.codeTable.entries) {
      reverseTable[entry.value] = entry.key;
    }

    final buffer = StringBuffer();
    String currentCode = '';

    for (final bit in result.encodedBits.split('')) {
      currentCode += bit;
      if (reverseTable.containsKey(currentCode)) {
        buffer.write(reverseTable[currentCode]);
        currentCode = '';
      }
    }

    final decoded = buffer.toString();
    _log('DECODE', 'Restored ${decoded.length} chars from ${result.encodedBits.length} bits');
    return decoded;
  }

  /// Convenience: Compress a string to a storable JSON string.
  String? compressToJson(String text) {
    final result = encode(text);
    if (result == null) return null;
    return jsonEncode(result.toJson());
  }

  /// Convenience: Decompress a JSON string back to original text.
  String? decompressFromJson(String jsonStr) {
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      final result = HuffmanResult.fromJson(map);
      return decode(result);
    } catch (e) {
      _log('ERROR', 'Decompression failed: $e');
      return null;
    }
  }

  // ─── Private Helpers ───

  void _buildCodes(HuffmanNode? node, String prefix, Map<String, String> table) {
    if (node == null) return;
    if (node.isLeaf && node.char != null) {
      table[node.char!] = prefix.isEmpty ? '0' : prefix;
      return;
    }
    _buildCodes(node.left, '${prefix}0', table);
    _buildCodes(node.right, '${prefix}1', table);
  }

  void _log(String op, String msg) {
    print('[DS:Huffman][$op] $msg');
  }
}
