import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../../core/services/tts_service.dart';

// ─── Data model for a single word's sign sequence ───
class WordSign {
  final String word;            // original word (display)
  final List<String> videoPaths; // asset paths for this word's sign
  final bool hasDirectSign;     // true = word-level sign, false = spelled

  const WordSign({
    required this.word,
    required this.videoPaths,
    required this.hasDirectSign,
  });
}

// ─── Playback phase enum ───
enum PlayPhase { idle, signing, speaking, paused, finished }

// ─── State ───
class VideoSignState {
  final VideoPlayerController? controller;
  final bool isPlaying;
  final bool isPaused;
  final String currentLabel;
  final int queueIndex;       // current video index within entire sequence
  final int totalInQueue;     // total videos across all words
  final List<String> words;   // original words for highlight bar
  final int currentWordIndex; // which word is active (-1 = none)
  final bool isSlowMode;      // speed toggle
  final PlayPhase phase;

  const VideoSignState({
    this.controller,
    this.isPlaying = false,
    this.isPaused = false,
    this.currentLabel = "Ready",
    this.queueIndex = 0,
    this.totalInQueue = 0,
    this.words = const [],
    this.currentWordIndex = -1,
    this.isSlowMode = true,
    this.phase = PlayPhase.idle,
  });

  VideoSignState copyWith({
    VideoPlayerController? controller,
    bool clearController = false,
    bool? isPlaying,
    bool? isPaused,
    String? currentLabel,
    int? queueIndex,
    int? totalInQueue,
    List<String>? words,
    int? currentWordIndex,
    bool? isSlowMode,
    PlayPhase? phase,
  }) {
    return VideoSignState(
      controller: clearController ? null : (controller ?? this.controller),
      isPlaying: isPlaying ?? this.isPlaying,
      isPaused: isPaused ?? this.isPaused,
      currentLabel: currentLabel ?? this.currentLabel,
      queueIndex: queueIndex ?? this.queueIndex,
      totalInQueue: totalInQueue ?? this.totalInQueue,
      words: words ?? this.words,
      currentWordIndex: currentWordIndex ?? this.currentWordIndex,
      isSlowMode: isSlowMode ?? this.isSlowMode,
      phase: phase ?? this.phase,
    );
  }
}

// ─── Provider ───
final videoSignControllerProvider =
    StateNotifierProvider<VideoSignController, VideoSignState>((ref) {
  return VideoSignController(ref);
});

// ─── Controller ───
class VideoSignController extends StateNotifier<VideoSignState> {
  final Ref _ref;

  VideoSignController(this._ref) : super(const VideoSignState());

  bool _stopRequested = false;
  bool _isPaused = false;
  String _lastText = '';

  // Supported whole-word signs
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

  TTSService get _tts => _ref.read(ttsServiceProvider);

  // ──────────────────────────────────────────
  // PUBLIC API
  // ──────────────────────────────────────────

  /// Play sentence word-by-word: sign → speak → next
  Future<void> playText(String text) async {
    if (state.isPlaying) return;

    _lastText = text;
    _stopRequested = false;
    _isPaused = false;

    // Set TTS speed based on mode
    await _tts.setSpeechRate(state.isSlowMode ? 0.3 : 0.5);

    // Build word-level sequence
    final wordSigns = _buildWordSequence(text);
    if (wordSigns.isEmpty) return;

    final originalWords = wordSigns.map((ws) => ws.word).toList();
    final totalVideos =
        wordSigns.fold<int>(0, (sum, ws) => sum + ws.videoPaths.length);

    state = state.copyWith(
      isPlaying: true,
      isPaused: false,
      words: originalWords,
      totalInQueue: totalVideos,
      queueIndex: 0,
      currentWordIndex: 0,
      currentLabel: "Starting...",
      phase: PlayPhase.signing,
    );

    int globalVideoIndex = 0;

    for (int w = 0; w < wordSigns.length; w++) {
      if (_stopRequested) break;

      // Wait while paused
      await _waitWhilePaused();
      if (_stopRequested) break;

      final wordSign = wordSigns[w];

      // ── Step 1: Highlight current word ──
      state = state.copyWith(
        currentWordIndex: w,
        currentLabel: wordSign.hasDirectSign
            ? "Signing: ${wordSign.word}"
            : "Spelling: ${wordSign.word}",
        phase: PlayPhase.signing,
      );

      // ── Step 2: Play all videos for this word ──
      if (wordSign.videoPaths.isNotEmpty) {
        for (final videoPath in wordSign.videoPaths) {
          if (_stopRequested) break;
          await _waitWhilePaused();
          if (_stopRequested) break;

          globalVideoIndex++;
          state = state.copyWith(queueIndex: globalVideoIndex);

          await _playVideoAsset(videoPath);
        }
      } else {
        // No sign available — show fallback
        state = state.copyWith(
          currentLabel: "No sign available for: ${wordSign.word}",
        );
        await Future.delayed(const Duration(milliseconds: 600));
      }

      if (_stopRequested) break;
      await _waitWhilePaused();
      if (_stopRequested) break;

      // ── Step 3: Speak the word via TTS ──
      state = state.copyWith(phase: PlayPhase.speaking);
      try {
        await _tts.speakAndWait(wordSign.word);
      } catch (_) {
        // TTS failed — continue anyway
      }

      // ── Step 4: Small inter-word delay ──
      final delay = state.isSlowMode ? 600 : 300;
      await Future.delayed(Duration(milliseconds: delay));
    }

    // ── Cleanup ──
    await _disposeCurrentController();

    state = state.copyWith(
      clearController: true,
      isPlaying: false,
      isPaused: false,
      currentLabel: _stopRequested ? "Stopped" : "Finished ✓",
      phase: PlayPhase.finished,
      currentWordIndex: -1,
    );
  }

  /// Pause playback (animation + TTS)
  void pausePlayback() {
    _isPaused = true;
    state.controller?.pause();
    _tts.stop();
    state = state.copyWith(isPaused: true, phase: PlayPhase.paused);
  }

  /// Resume playback
  void resumePlayback() {
    _isPaused = false;
    state.controller?.play();
    state = state.copyWith(isPaused: false, phase: PlayPhase.signing);
  }

  /// Stop playback completely
  void stopPlayback() {
    _stopRequested = true;
    _isPaused = false;
    state.controller?.pause();
    _tts.stop();
  }

  /// Replay the last sentence
  Future<void> replay() async {
    stopPlayback();
    // Small delay to let stop settle
    await Future.delayed(const Duration(milliseconds: 200));
    await _disposeCurrentController();
    state = const VideoSignState();
    if (_lastText.isNotEmpty) {
      await playText(_lastText);
    }
  }

  /// Toggle speed mode
  void toggleSpeed() {
    final newMode = !state.isSlowMode;
    state = state.copyWith(isSlowMode: newMode);
    _tts.setSpeechRate(newMode ? 0.3 : 0.5);
  }

  // ──────────────────────────────────────────
  // PRIVATE HELPERS
  // ──────────────────────────────────────────

  Future<void> _waitWhilePaused() async {
    while (_isPaused && !_stopRequested) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> _playVideoAsset(String path) async {
    await _disposeCurrentController();

    final controller = VideoPlayerController.asset(path);

    try {
      await controller.initialize();

      if (!mounted) return;
      state = state.copyWith(controller: controller);

      await controller.play();

      // Wait for video to finish (duration + small buffer)
      await Future.delayed(
        controller.value.duration + const Duration(milliseconds: 150),
      );
    } catch (e) {
      // Video failed — continue gracefully
    }
  }

  Future<void> _disposeCurrentController() async {
    final old = state.controller;
    if (old != null) {
      // IMPORTANT: Remove from state FIRST so VideoPlayer widget
      // stops referencing it, THEN dispose.
      state = state.copyWith(clearController: true);
      await Future.delayed(const Duration(milliseconds: 50));
      try {
        await old.dispose();
      } catch (_) {}
    }
  }

  /// Build per-word sign sequence from input text.
  List<WordSign> _buildWordSequence(String text) {
    final List<WordSign> result = [];

    String cleaned = text.toUpperCase();
    cleaned = cleaned.replaceAll(RegExp(r'[^A-Z ]'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (cleaned.isEmpty) return result;

    final words = cleaned.split(' ');

    for (int i = 0; i < words.length; i++) {
      final currentWord = words[i];

      // Try combining with next word for multi-word signs
      if (i < words.length - 1) {
        final combined = currentWord + words[i + 1];
        if (_supportedWords.contains(combined)) {
          result.add(WordSign(
            word: "${words[i]} ${words[i + 1]}",
            videoPaths: ["assets/signs/words/$combined.mp4"],
            hasDirectSign: true,
          ));
          i++; // skip next word
          continue;
        }
      }

      // Single word match
      if (_supportedWords.contains(currentWord)) {
        result.add(WordSign(
          word: currentWord,
          videoPaths: ["assets/signs/words/$currentWord.mp4"],
          hasDirectSign: true,
        ));
      } else {
        // Spell letter by letter
        final letterPaths = currentWord
            .split('')
            .map((c) => "assets/signs/letters/$c.mp4")
            .toList();
        result.add(WordSign(
          word: currentWord,
          videoPaths: letterPaths,
          hasDirectSign: false,
        ));
      }
    }

    return result;
  }

  @override
  void dispose() {
    _stopRequested = true;
    state.controller?.dispose();
    super.dispose();
  }
}
