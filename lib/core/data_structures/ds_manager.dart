/// Central Data Structure Manager — Initializes and provides all DS instances.
/// This is the single entry point for all data structures in the app.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'trie.dart';
import 'priority_queue.dart';
import 'huffman_coding.dart';
import 'disjoint_set.dart';
import 'segment_tree.dart';

export 'trie.dart';
export 'priority_queue.dart';
export 'huffman_coding.dart';
export 'disjoint_set.dart';
export 'segment_tree.dart';

// ─── Riverpod Providers ───

final trieProvider = Provider<Trie>((ref) {
  final trie = Trie();
  _seedTrie(trie);
  return trie;
});

final phraseHeapProvider = Provider<PriorityQueue>((ref) {
  final pq = PriorityQueue();
  _seedPhraseHeap(pq);
  return pq;
});

final huffmanProvider = Provider<HuffmanCoding>((ref) => HuffmanCoding());

final conceptGroupProvider = Provider<DisjointSet>((ref) {
  final ds = DisjointSet();
  _seedConceptGroups(ds);
  return ds;
});

final progressTreeProvider = Provider<SegmentTree>((ref) {
  return SegmentTree(365); // Track up to 365 days
});

// ─── Seed Data ───

void _seedTrie(Trie trie) {
  // FOOD
  for (final w in ['apple', 'banana', 'water', 'milk', 'bread', 'eat', 'drink', 'hungry', 'thirsty']) {
    trie.insert(w, category: 'FOOD');
  }
  // EMOTION
  for (final w in ['happy', 'sad', 'scared', 'angry', 'tired', 'love', 'pain']) {
    trie.insert(w, category: 'EMOTION');
  }
  // GREETING
  for (final w in ['hello', 'goodbye', 'thankyou', 'please', 'sorry', 'yes', 'no']) {
    trie.insert(w, category: 'GREETING');
  }
  // ACTION
  for (final w in ['help', 'stop', 'go', 'sit', 'stand', 'open', 'close', 'wait']) {
    trie.insert(w, category: 'ACTION');
  }
  // FAMILY
  for (final w in ['mom', 'dad', 'baby', 'friend', 'teacher', 'doctor']) {
    trie.insert(w, category: 'FAMILY');
  }
  // SIGN SEQUENCES (map words to video assets)
  final signWords = ['HELLO', 'THANKYOU', 'GOODMORNING', 'GOODBYE', 'PLEASE', 'YES', 'NO'];
  for (final w in signWords) {
    trie.insert(w.toLowerCase(), signSequence: 'assets/signs/words/$w.mp4');
  }
  print('[DS:Manager] Trie seeded with ${trie.totalWords} words');
}

void _seedPhraseHeap(PriorityQueue pq) {
  final defaults = [
    PhraseEntry(phrase: 'I need help', usageCount: 5),
    PhraseEntry(phrase: 'I am hungry', usageCount: 8),
    PhraseEntry(phrase: 'I am thirsty', usageCount: 4),
    PhraseEntry(phrase: 'I want toilet', usageCount: 6),
    PhraseEntry(phrase: 'I feel pain', usageCount: 3),
    PhraseEntry(phrase: 'I am scared', usageCount: 2),
    PhraseEntry(phrase: 'Where is mom?', usageCount: 7),
    PhraseEntry(phrase: 'Thank you', usageCount: 1),
  ];
  pq.buildFrom(defaults);
  print('[DS:Manager] PhraseHeap seeded with ${pq.size} phrases');
}

void _seedConceptGroups(DisjointSet ds) {
  // FOOD group
  ds.makeSet('apple', groupName: 'FOOD');
  for (final w in ['banana', 'water', 'milk', 'bread']) {
    ds.makeSet(w);
    ds.union('apple', w);
  }
  // EMOTION group
  ds.makeSet('happy', groupName: 'EMOTION');
  for (final w in ['sad', 'scared', 'angry', 'tired']) {
    ds.makeSet(w);
    ds.union('happy', w);
  }
  // ACTION group
  ds.makeSet('eat', groupName: 'ACTION');
  for (final w in ['drink', 'help', 'stop', 'go', 'sit']) {
    ds.makeSet(w);
    ds.union('eat', w);
  }
  // GREETING group
  ds.makeSet('hello', groupName: 'GREETING');
  for (final w in ['goodbye', 'thankyou', 'please', 'sorry']) {
    ds.makeSet(w);
    ds.union('hello', w);
  }
  // FAMILY group
  ds.makeSet('mom', groupName: 'FAMILY');
  for (final w in ['dad', 'baby', 'friend', 'teacher']) {
    ds.makeSet(w);
    ds.union('mom', w);
  }
  print('[DS:Manager] ConceptGroups seeded: ${ds.getAllGroups().keys.toList()}');
}
