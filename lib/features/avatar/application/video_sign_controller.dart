import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

class VideoSignState {
  final VideoPlayerController? controller;
  final bool isPlaying;
  final String currentLabel;
  final int queueIndex;
  final int totalInQueue;

  const VideoSignState({
    this.controller,
    this.isPlaying = false,
    this.currentLabel = "Ready",
    this.queueIndex = 0,
    this.totalInQueue = 0,
  });

  VideoSignState copyWith({
    VideoPlayerController? controller,
    bool? isPlaying,
    String? currentLabel,
    int? queueIndex,
    int? totalInQueue,
  }) {
    return VideoSignState(
      controller: controller,
      isPlaying: isPlaying ?? this.isPlaying,
      currentLabel: currentLabel ?? this.currentLabel,
      queueIndex: queueIndex ?? this.queueIndex,
      totalInQueue: totalInQueue ?? this.totalInQueue,
    );
  }
}

final videoSignControllerProvider =
StateNotifierProvider<VideoSignController, VideoSignState>((ref) {
  return VideoSignController();
});

class VideoSignController extends StateNotifier<VideoSignState> {
  VideoSignController() : super(const VideoSignState());

  bool _stopRequested = false;

  final Set<String> _supportedWords = {
    "HELLO",
    "THANKYOU",
    "GOODMORNING",
    "GOODAFTERNOON",
    "GOODBYE",
    "NICETOMEETYOU",
    "HOWAREYOU",
    "PLEASE",
    "EXCUSEME",
    "YES",
    "NO",
  };

  Future<void> playText(String text) async {
    if (state.isPlaying) return;

    final sequence = _buildSequence(text);
    if (sequence.isEmpty) return;

    _stopRequested = false;

    state = state.copyWith(
      isPlaying: true,
      totalInQueue: sequence.length,
      queueIndex: 0,
      currentLabel: "Starting...",
    );

    for (int i = 0; i < sequence.length; i++) {
      if (_stopRequested) break;

      final path = sequence[i];
      final label = path.split('/').last.split('.').first;

      final oldController = state.controller;
      if (oldController != null) {
        await oldController.dispose();
      }

      final controller = VideoPlayerController.asset(path);

      try {
        await controller.initialize();

        state = state.copyWith(
          controller: controller,
          currentLabel: "Signing: $label",
          queueIndex: i + 1,
        );

        await controller.play();

        await Future.delayed(
          controller.value.duration + const Duration(milliseconds: 200),
        );
      } catch (e) {
        print("Video error: $e");
      }
    }

    final finalController = state.controller;
    if (finalController != null) {
      await finalController.dispose();
    }

    state = const VideoSignState(
      isPlaying: false,
      currentLabel: "Finished",
      queueIndex: 0,
      totalInQueue: 0,
      controller: null,
    );
  }

  void stopPlayback() {
    _stopRequested = true;
    state.controller?.pause();
  }

  // 🔥 FIXED BUILD SEQUENCE
  List<String> _buildSequence(String text) {
    final List<String> sequence = [];

    // 1️⃣ Normalize
    String cleaned = text.toUpperCase();

    // Remove everything except letters and spaces
    cleaned = cleaned.replaceAll(RegExp(r'[^A-Z ]'), '');

    // Replace multiple spaces with single space
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (cleaned.isEmpty) return sequence;

    final words = cleaned.split(' ');

    for (int i = 0; i < words.length; i++) {
      final currentWord = words[i];

      // Try combine with next word
      if (i < words.length - 1) {
        final combined = currentWord + words[i + 1];

        if (_supportedWords.contains(combined)) {
          sequence.add("assets/signs/words/$combined.mp4");
          i++;
          continue;
        }
      }

      // Single word match
      if (_supportedWords.contains(currentWord)) {
        sequence.add("assets/signs/words/$currentWord.mp4");
      } else {
        // Spell letter by letter
        for (var char in currentWord.split('')) {
          sequence.add("assets/signs/letters/$char.mp4");
        }
      }
    }

    return sequence;
  }

  @override
  void dispose() {
    state.controller?.dispose();
    super.dispose();
  }
}
