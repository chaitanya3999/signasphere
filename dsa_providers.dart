/// dsa_providers.dart
/// Located: lib/core/services/dsa/dsa_providers.dart
///
/// Riverpod providers that wire all three DSA structures
/// into your existing provider/consumer architecture.
///
/// Import this in any feature screen that needs sign data.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sign_trie.dart';
import 'sign_avl_tree.dart';
import 'frequency_heap.dart';

// ─── Sample Data (replace with your real asset/JSON loader) ───────

final _sampleSigns = [
  SignEntry(
    word: 'hello',
    gifAssetPath: 'assets/signs/hello.gif',
    category: 'greetings',
    description: 'Wave from forehead',
    avatarAnimKey: 'anim_hello',
    difficultyLevel: 1,
    tags: ['common', 'daily'],
  ),
  SignEntry(
    word: 'help',
    gifAssetPath: 'assets/signs/help.gif',
    category: 'emergency',
    description: 'Fist on palm, raise up',
    avatarAnimKey: 'anim_help',
    difficultyLevel: 1,
    tags: ['emergency', 'critical'],
  ),
  SignEntry(
    word: 'happy',
    gifAssetPath: 'assets/signs/happy.gif',
    category: 'emotions',
    description: 'Brush chest upward twice',
    avatarAnimKey: 'anim_happy',
    difficultyLevel: 1,
    tags: ['emotion', 'common'],
  ),
  SignEntry(
    word: 'hungry',
    gifAssetPath: 'assets/signs/hungry.gif',
    category: 'needs',
    description: 'C-hand down chest',
    avatarAnimKey: 'anim_hungry',
    difficultyLevel: 1,
    tags: ['daily', 'need'],
  ),
  SignEntry(
    word: 'water',
    gifAssetPath: 'assets/signs/water.gif',
    category: 'needs',
    description: 'W hand tap to lips',
    avatarAnimKey: 'anim_water',
    difficultyLevel: 1,
    tags: ['daily', 'need'],
  ),
  SignEntry(
    word: 'thank you',
    gifAssetPath: 'assets/signs/thankyou.gif',
    category: 'greetings',
    description: 'Flat hand from chin outward',
    avatarAnimKey: 'anim_thankyou',
    difficultyLevel: 1,
    tags: ['common', 'polite'],
  ),
  SignEntry(
    word: 'sad',
    gifAssetPath: 'assets/signs/sad.gif',
    category: 'emotions',
    description: 'Hands slide down face',
    avatarAnimKey: 'anim_sad',
    difficultyLevel: 1,
    tags: ['emotion'],
  ),
  SignEntry(
    word: 'pain',
    gifAssetPath: 'assets/signs/pain.gif',
    category: 'emergency',
    description: 'Index fingers point/touch',
    avatarAnimKey: 'anim_pain',
    difficultyLevel: 2,
    tags: ['emergency', 'hospital'],
  ),
  SignEntry(
    word: 'doctor',
    gifAssetPath: 'assets/signs/doctor.gif',
    category: 'emergency',
    description: 'D-hand taps wrist pulse',
    avatarAnimKey: 'anim_doctor',
    difficultyLevel: 2,
    tags: ['hospital', 'emergency'],
  ),
  SignEntry(
    word: 'apple',
    gifAssetPath: 'assets/signs/apple.gif',
    category: 'food',
    description: 'X-hand twist at cheek',
    avatarAnimKey: 'anim_apple',
    difficultyLevel: 1,
    tags: ['food', 'beginner'],
  ),
];

// ─── Providers ────────────────────────────────────────────────────

/// AVL Tree Provider — sorted sign dictionary for Learn Mode
/// The tree is built once and stays stable (use Provider not StateProvider)
final signDictionaryProvider = Provider<SignAVLTree>((ref) {
  final tree = SignAVLTree();
  for (final sign in _sampleSigns) {
    tree.insert(sign);
  }
  return tree;
});

/// Trie Provider — autocomplete for Avatar tab and Conversation mode
final signTrieProvider = Provider<SignTrie>((ref) {
  final trie = SignTrie();
  for (final sign in _sampleSigns) {
    trie.insert(
      SignData(
        word: sign.word,
        gifAssetPath: sign.gifAssetPath,
        category: sign.category,
        description: sign.description,
        avatarAnimKey: sign.avatarAnimKey,
      ),
    );
  }
  return trie;
});

/// Frequency Heap Notifier — tracks usage, updates Home quick-tiles
class FrequencyNotifier extends StateNotifier<List<FrequencyEntry>> {
  final FrequencyHeap _heap = FrequencyHeap();

  FrequencyNotifier() : super([]) {
    // Pre-load with some defaults
    _heap.push(
      FrequencyEntry(
        word: 'hello',
        frequency: 5,
        category: 'greetings',
        gifAssetPath: 'assets/signs/hello.gif',
        avatarAnimKey: 'anim_hello',
      ),
    );
    _heap.push(
      FrequencyEntry(
        word: 'water',
        frequency: 3,
        category: 'needs',
        gifAssetPath: 'assets/signs/water.gif',
        avatarAnimKey: 'anim_water',
      ),
    );
    _heap.push(
      FrequencyEntry(
        word: 'help',
        frequency: 2,
        category: 'emergency',
        gifAssetPath: 'assets/signs/help.gif',
        avatarAnimKey: 'anim_help',
      ),
    );
    state = _heap.getTopN(6);
  }

  /// Call this from ANY screen when a user selects a sign
  void onSignUsed(String word) {
    _heap.onSignUsed(word);
    state = _heap.getTopN(6); // Refresh the 6 quick-tiles on Home
  }

  /// For Home dashboard — top sign right now
  FrequencyEntry? get topSign => _heap.peek();
}

final frequencyProvider =
    StateNotifierProvider<FrequencyNotifier, List<FrequencyEntry>>(
      (ref) => FrequencyNotifier(),
    );

// ─── Derived Providers (convenience) ──────────────────────────────

/// Autocomplete suggestions — reactive to what user is typing
final autocompleteProvider = Provider.family<List<SignData>, String>((
  ref,
  prefix,
) {
  if (prefix.isEmpty) return [];
  final trie = ref.watch(signTrieProvider);
  return trie.autoComplete(prefix, limit: 8);
});

/// Signs by category — for Learn Mode category tabs
final signsByCategoryProvider = Provider.family<List<SignEntry>, String>((
  ref,
  category,
) {
  final tree = ref.watch(signDictionaryProvider);
  return tree.getByCategory(category);
});

/// Signs by difficulty — for gamified lesson progression
final signsByDifficultyProvider = Provider.family<List<SignEntry>, int>((
  ref,
  level,
) {
  final tree = ref.watch(signDictionaryProvider);
  return tree.getByDifficulty(level);
});

/// Learning progress — for the Learn Mode progress bar/badge
final progressProvider = Provider<Map<String, int>>((ref) {
  final tree = ref.watch(signDictionaryProvider);
  return tree.getProgressStats();
});

// ─── How to use in your Flutter screens ───────────────────────────
//
// AVATAR TAB (autocomplete as user types):
// ─────────────────────────────────────────
// class AvatarScreen extends ConsumerWidget {
//   Widget build(BuildContext context, WidgetRef ref) {
//     final suggestions = ref.watch(autocompleteProvider(typedText));
//     return Column(children: [
//       TextField(onChanged: (v) => setState(() => typedText = v)),
//       ...suggestions.map((s) => SignChip(sign: s)),
//     ]);
//   }
// }
//
// HOME SCREEN (quick-tiles):
// ─────────────────────────────────────────
// class HomeScreen extends ConsumerWidget {
//   Widget build(BuildContext context, WidgetRef ref) {
//     final topSigns = ref.watch(frequencyProvider);
//     return GridView.builder(
//       itemCount: topSigns.length,
//       itemBuilder: (_, i) => QuickTile(
//         sign: topSigns[i],
//         onTap: () => ref.read(frequencyProvider.notifier).onSignUsed(topSigns[i].word),
//       ),
//     );
//   }
// }
//
// LEARN MODE:
// ─────────────────────────────────────────
// final greetings = ref.watch(signsByCategoryProvider('greetings'));
// final beginners  = ref.watch(signsByDifficultyProvider(1));
// final progress   = ref.watch(progressProvider); // { total: 10, learned: 3, remaining: 7 }
