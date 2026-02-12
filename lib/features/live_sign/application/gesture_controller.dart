import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signasphere/features/live_sign/data/gesture_repository.dart';
import 'package:signasphere/features/live_sign/domain/asl_engine.dart';
import 'package:signasphere/features/live_sign/domain/gesture_state.dart';
import 'package:signasphere/features/live_sign/domain/word_dictionary.dart';
import 'package:signasphere/features/live_sign/domain/hand_coordinate_transform.dart';
import 'package:signasphere/features/live_sign/domain/hand_geometry.dart';

final gestureControllerProvider = StateNotifierProvider<GestureController, GestureState>((ref) {
  final repo = ref.watch(gestureRepositoryProvider);
  return GestureController(repo);
});

class GestureController extends StateNotifier<GestureState> {
  final GestureRepository _repository;
  final WordDictionary _dictionary = WordDictionary();

  StreamSubscription? _subscription;

  // --- CONFIGURATION ---
  // Letter Stability
  static const int _bufferSize = 7;
  static const Duration _holdTime = Duration(milliseconds: 1000);     // Time to hold letter to type
  static const Duration _cooldownTime = Duration(milliseconds: 1200); // Wait after typing before next
  static const Duration _resetTime = Duration(milliseconds: 600);     // Reset candidate if hand lost

  // Control Gestures
  static const Duration _backspaceHoldTime = Duration(milliseconds: 1200);
  static const Duration _spaceHoldTime = Duration(milliseconds: 600); // Phase 5 Requirement
  static const Duration _wordCooldown = Duration(seconds: 2);

  // --- INTERNAL STATE ---
  // Letter Buffers
  final List<String> _letterBuffer = [];
  String? _candidateLetter;
  DateTime? _candidateStartTime;

  // Timers
  DateTime _lastConfirmedTime = DateTime(1970);
  DateTime _lastDetectionTime = DateTime.now();
  DateTime _lastWordDetectionTime = DateTime(1970);

  // Control Gesture Timers
  DateTime? _backspaceStartTime;
  DateTime? _spaceStartTime;

  GestureController(this._repository) : super(GestureState.initial());

  void initializeTracking(int viewId) {
    if (_subscription != null) return;
    state = state.copyWith(status: "Active", isTracking: true);

    try {
      _subscription = _repository.getLandmarkStream(viewId).listen(
        _processFrame,
        onError: (err) => state = state.copyWith(status: "Error", errorMessage: err.toString()),
      );
    } catch (e) {
      state = state.copyWith(status: "Error", errorMessage: e.toString());
    }
  }

  void _processFrame(List<List<double>> rawLandmarks) {
    final now = DateTime.now();

    // 0. Safety Check
    if (rawLandmarks.length < 21) {
      // Release detection: If no hand seen for threshold, reset candidate
      if (now.difference(_lastDetectionTime) > _resetTime) {
        _candidateLetter = null;
        _backspaceStartTime = null;
        _spaceStartTime = null;
        state = state.copyWith(currentGesture: "...");
      }
      return;
    }

    _lastDetectionTime = now;

    // 1. Normalize & Geometry (For local checks)
    // We do this locally to support our custom control gestures
    // without hacking the ASLEngine.
    final normalized = HandCoordinateTransform.normalize(rawLandmarks);
    final geo = HandGeometry(normalized);

    // --- PHASE 4: BACKSPACE GESTURE (Thumbs Up) ---
    if (_isBackspaceGesture(geo)) {
      if (_backspaceStartTime == null) {
        _backspaceStartTime = now;
        state = state.copyWith(currentGesture: "Deleting...");
      } else if (now.difference(_backspaceStartTime!) > _backspaceHoldTime) {
        _triggerBackspace();
        _backspaceStartTime = null; // Reset to prevent rapid delete
      }
      // If we are doing backspace, DO NOT process letters or space
      _candidateLetter = null;
      _spaceStartTime = null;
      return;
    } else {
      _backspaceStartTime = null;
    }

    // --- PHASE 5: SPACE GESTURE (Open Palm ✋) ---
    if (_isSpaceGesture(geo)) {
      if (_spaceStartTime == null) {
        _spaceStartTime = now;
        // Visual feedback? Maybe just keep current gesture or show "Space..."
      } else if (now.difference(_spaceStartTime!) > _spaceHoldTime) {
        _triggerSpace();
        _spaceStartTime = null; // Reset to prevent rapid spacing
      }
      // If holding open palm, do NOT process letters (prevents 'B' or '5' conflict)
      // Although 'B' is similar, the ASLEngine requires specific thumb tuck for 'B'.
      // Open palm usually implies "Wait/Space".
      _candidateLetter = null;
      return;
    } else {
      _spaceStartTime = null;
    }

    // --- PHASE 3: ASL LETTER ENGINE ---
    final result = ASLEngine.detectLetter(rawLandmarks);

    if (result == null) {
      _candidateLetter = null;
      state = state.copyWith(currentGesture: "...");
      return;
    }

    // Circular Buffer (Noise Reduction)
    _letterBuffer.add(result.letter);
    if (_letterBuffer.length > _bufferSize) {
      _letterBuffer.removeAt(0);
    }

    // Majority Vote
    final smoothedLetter = _getMajorityLetter();
    if (smoothedLetter == null) return; // Too noisy

    // Update UI Preview immediately
    state = state.copyWith(currentGesture: smoothedLetter);

    // Temporal Stability (Hold to Type)
    if (_candidateLetter == smoothedLetter) {
      final duration = now.difference(_candidateStartTime!);
      final timeSinceLastConfirm = now.difference(_lastConfirmedTime);

      // Check Hold Time & Cooldown
      if (duration >= _holdTime && timeSinceLastConfirm >= _cooldownTime) {
        _confirmLetter(smoothedLetter);
      }
    } else {
      // Candidate changed, reset timer
      _candidateLetter = smoothedLetter;
      _candidateStartTime = now;
    }
  }

  // --- CONTROL GESTURE LOGIC ---

  /// Backspace: Fist with Thumb Up (Thumbs Up 👍)
  bool _isBackspaceGesture(HandGeometry geo) {
    final indexCurl = geo.computeCurl(5, 6, 8);
    final midCurl = geo.computeCurl(9, 10, 12);
    final ringCurl = geo.computeCurl(13, 14, 16);
    final pinkyCurl = geo.computeCurl(17, 18, 20);
    final thumbCurl = geo.computeThumbCurl();

    // Strict Thumbs Up: Fingers curled > 0.8, Thumb extended < 0.2
    return indexCurl > 0.8 && midCurl > 0.8 &&
        ringCurl > 0.8 && pinkyCurl > 0.8 &&
        thumbCurl < 0.2;
  }

  /// Space: Open Palm ✋ (All fingers extended)
  bool _isSpaceGesture(HandGeometry geo) {
    // 1. Check Sentence State
    // Don't trigger if empty or already has space at end
    if (state.sentence.isEmpty || state.sentence.endsWith(" ")) {
      return false;
    }

    // 2. Geometric Check
    final indexCurl = geo.computeCurl(5, 6, 8);
    final midCurl = geo.computeCurl(9, 10, 12);
    final ringCurl = geo.computeCurl(13, 14, 16);
    final pinkyCurl = geo.computeCurl(17, 18, 20);
    final thumbCurl = geo.computeThumbCurl();

    // Threshold 0.2 implies very straight fingers
    bool allExtended = indexCurl < 0.2 && midCurl < 0.2 &&
        ringCurl < 0.2 && pinkyCurl < 0.2 &&
        thumbCurl < 0.2;

    return allExtended;
  }

  void _triggerBackspace() {
    if (state.sentence.isNotEmpty) {
      final newSentence = state.sentence.substring(0, state.sentence.length - 1);
      state = state.copyWith(
        sentence: newSentence,
        lastRecognizedWord: null, // Clear word cache
        status: "Backspace",
      );

      // Clear buffers to prevent immediate re-typing
      _letterBuffer.clear();
      _candidateLetter = null;
      _lastConfirmedTime = DateTime.now(); // Act as if we just typed
    }
  }

  void _triggerSpace() {
    // We already checked isEmpty/endsWith space in _isSpaceGesture
    final newSentence = "${state.sentence} ";

    state = state.copyWith(
      sentence: newSentence,
      status: "Space Inserted",
    );

    // Reset everything
    _letterBuffer.clear();
    _candidateLetter = null;
    _lastConfirmedTime = DateTime.now(); // Trigger cooldown
  }

  // --- LETTER LOGIC ---

  String? _getMajorityLetter() {
    if (_letterBuffer.isEmpty) return null;
    final counts = <String, int>{};
    for (var l in _letterBuffer) {
      counts[l] = (counts[l] ?? 0) + 1;
    }

    var best = "";
    var maxCount = 0;
    counts.forEach((k, v) {
      if (v > maxCount) {
        maxCount = v;
        best = k;
      }
    });

    // 60% majority of buffer size 7 is >= 5
    if (maxCount >= 5) {
      return best;
    }
    return null;
  }

  void _confirmLetter(String letter) {
    // 1. Append Letter
    final newSentence = state.sentence + letter;

    // 2. Check for Word Match (Phase 4)
    final match = _dictionary.findMatch(newSentence);

    if (match != null && _canTriggerWord(match)) {
      _triggerWord(match, newSentence);
    } else {
      state = state.copyWith(
        sentence: newSentence,
        lastUpdated: DateTime.now(),
        status: "Typed: $letter",
      );
    }

    _lastConfirmedTime = DateTime.now();
    _candidateLetter = null; // Reset to force re-hold
    _letterBuffer.clear(); // Clear buffer to ensure fresh start
  }

  bool _canTriggerWord(String word) {
    final now = DateTime.now();
    if (state.lastRecognizedWord == word) {
      if (now.difference(_lastWordDetectionTime) < _wordCooldown) {
        return false;
      }
    }
    return true;
  }

  void _triggerWord(String word, String currentSentence) {
    // Auto-insert space after word
    final sentenceWithSpace = "$currentSentence ";

    state = state.copyWith(
      sentence: sentenceWithSpace,
      lastRecognizedWord: word,
      lastWordTime: DateTime.now(),
      status: "Recognized: $word",
    );

    _lastWordDetectionTime = DateTime.now();
    _letterBuffer.clear();
    _candidateLetter = null;
  }

  void clearSentence() {
    state = state.copyWith(
      sentence: "",
      lastRecognizedWord: null,
    );
  }

  void stopTracking() {
    _subscription?.cancel();
    _subscription = null;
    state = state.copyWith(status: "Paused", isTracking: false);
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}