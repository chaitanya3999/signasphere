import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/quiz_models.dart';

final quizAssetServiceProvider = Provider((ref) => QuizAssetService());

class QuizAssetService {
  List<SignWord> _cachedWords = [];
  bool _isInit = false;

  Future<void> initialize() async {
    if (_isInit) return;

    try {
      // Use the AssetManifest API which works on both Mobile and Web
      print("QuizAssetService: Loading AssetManifest...");
      final AssetManifest assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final List<String> allAssets = assetManifest.listAssets();
      print("QuizAssetService: Found ${allAssets.length} total assets.");
      
      final List<String> imagePaths = allAssets
          .where((String key) => key.startsWith('assets/quiz_data/'))
          .where((String key) => _isImage(key))
          .toList();

      print("QuizAssetService: Found ${imagePaths.length} quiz images.");

      final Map<String, List<String>> groupedImages = {};

      for (var path in imagePaths) {
        // assets/quiz_data/hello/img1.png
        final parts = path.split('/');
        if (parts.length >= 4) {
          final label = parts[2]; // "hello" - Folder Name is Label
          
          if (!groupedImages.containsKey(label)) {
            groupedImages[label] = [];
          }
          groupedImages[label]!.add(path);
        }
      }
      
      print("QuizAssetService: Grouped into ${groupedImages.keys.length} labels: ${groupedImages.keys.take(5)}...");

      _cachedWords = groupedImages.entries.map((entry) {
        return SignWord(
          label: entry.key, // No categorization, just the label
          imagePaths: entry.value,
        );
      }).toList();

      _isInit = true;
      print("QuizAssetService: Initialization complete. Cached ${_cachedWords.length} words.");
    } catch (e, stack) {
      print("Error loading quiz assets: $e");
      print(stack);
    }
  }

  List<SignWord> get allWords => _cachedWords;

  // Helper to get random words
  List<SignWord> getRandomWords(int count) {
    if (_cachedWords.isEmpty) return [];
    final List<SignWord> shuffled = List.from(_cachedWords)..shuffle();
    return shuffled.take(count).toList();
  }

  bool _isImage(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.png') || lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.webp');
  }
}
