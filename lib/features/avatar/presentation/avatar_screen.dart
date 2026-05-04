import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../application/video_sign_controller.dart';
import '../../user_tracking/controllers/usage_controller.dart';
import '../../user_tracking/models/usage_event.dart';

class AvatarScreen extends ConsumerStatefulWidget {
  const AvatarScreen({super.key});

  @override
  ConsumerState<AvatarScreen> createState() => _AvatarScreenState();
}

class _AvatarScreenState extends ConsumerState<AvatarScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _tracked = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Track once, safely outside of widget tree construction
    if (!_tracked) {
      _tracked = true;
      Future.microtask(() {
        ref.read(usageControllerProvider).trackEvent(UsageEventType.usedAvatar);
      });
    }

    final state = ref.watch(videoSignControllerProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("Sign Translator"),
        centerTitle: true,
        actions: [
          // Speed toggle chip
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              avatar: Icon(
                state.isSlowMode ? Icons.slow_motion_video : Icons.speed,
                size: 18,
                color: colorScheme.onPrimaryContainer,
              ),
              label: Text(
                state.isSlowMode ? "Slow" : "Normal",
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              backgroundColor: colorScheme.primaryContainer,
              onPressed: () {
                ref.read(videoSignControllerProvider.notifier).toggleSpeed();
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: bottomInset + 100),
          child: Column(
            children: [
              // ── Word Highlight Bar ──
              if (state.words.isNotEmpty) _buildWordHighlightBar(state, colorScheme),

              // ── Video Player ──
              _buildVideoPlayer(state, colorScheme),

              // ── Phase Label ──
              if (state.isPlaying || state.phase == PlayPhase.finished)
                _buildPhaseIndicator(state, colorScheme),

              // ── Progress Bar ──
              if (state.isPlaying) _buildProgressBar(state, colorScheme),

              // ── Controls ──
              _buildControls(state, colorScheme),

              // ── Text Input ──
              _buildTextInput(state, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  // Word Highlight Bar
  // ──────────────────────────────────────────
  Widget _buildWordHighlightBar(VideoSignState state, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: List.generate(state.words.length, (i) {
          final isActive = i == state.currentWordIndex;
          final isPast = state.currentWordIndex > i;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isActive
                  ? colorScheme.primary
                  : isPast
                      ? colorScheme.primary.withValues(alpha: 0.15)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Text(
              state.words[i],
              style: TextStyle(
                fontSize: 16,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive
                    ? colorScheme.onPrimary
                    : isPast
                        ? colorScheme.primary
                        : colorScheme.onSurface.withValues(alpha: 0.6),
                letterSpacing: isActive ? 0.5 : 0,
              ),
            ),
          );
        }),
      ),
    );
  }

  // ──────────────────────────────────────────
  // Video Player
  // ──────────────────────────────────────────
  Widget _buildVideoPlayer(VideoSignState state, ColorScheme colorScheme) {
    return Container(
      height: 280,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: state.phase == PlayPhase.speaking
              ? colorScheme.tertiary.withValues(alpha: 0.6)
              : state.phase == PlayPhase.signing
                  ? colorScheme.primary.withValues(alpha: 0.4)
                  : Colors.transparent,
          width: 2,
        ),
        boxShadow: state.isPlaying
            ? [
                BoxShadow(
                  color: (state.phase == PlayPhase.speaking
                          ? colorScheme.tertiary
                          : colorScheme.primary)
                      .withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Center(
          child: state.controller != null &&
                  state.controller!.value.isInitialized
              ? AspectRatio(
                  aspectRatio: state.controller!.value.aspectRatio,
                  child: VideoPlayer(state.controller!),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      state.phase == PlayPhase.speaking
                          ? Icons.volume_up_rounded
                          : Icons.sign_language,
                      size: 64,
                      color: state.phase == PlayPhase.speaking
                          ? colorScheme.tertiary
                          : Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.phase == PlayPhase.speaking
                          ? "Speaking..."
                          : state.phase == PlayPhase.finished
                              ? "Done! Tap replay to watch again"
                              : "Type a sentence and press Play",
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  // Phase Indicator (Signing / Speaking badge)
  // ──────────────────────────────────────────
  Widget _buildPhaseIndicator(VideoSignState state, ColorScheme colorScheme) {
    final isSpeaking = state.phase == PlayPhase.speaking;
    final isPaused = state.phase == PlayPhase.paused;
    final isFinished = state.phase == PlayPhase.finished;

    final Color bgColor;
    final Color fgColor;
    final IconData icon;
    final String label;

    if (isFinished) {
      bgColor = Colors.green.withValues(alpha: 0.15);
      fgColor = Colors.green;
      icon = Icons.check_circle_rounded;
      label = "Finished";
    } else if (isPaused) {
      bgColor = Colors.orange.withValues(alpha: 0.15);
      fgColor = Colors.orange;
      icon = Icons.pause_circle_rounded;
      label = "Paused";
    } else if (isSpeaking) {
      bgColor = colorScheme.tertiary.withValues(alpha: 0.15);
      fgColor = colorScheme.tertiary;
      icon = Icons.volume_up_rounded;
      label = state.currentLabel;
    } else {
      bgColor = colorScheme.primary.withValues(alpha: 0.15);
      fgColor = colorScheme.primary;
      icon = Icons.sign_language;
      label = state.currentLabel;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: fgColor),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: fgColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  // Progress Bar
  // ──────────────────────────────────────────
  Widget _buildProgressBar(VideoSignState state, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: state.totalInQueue == 0
              ? 0
              : state.queueIndex / state.totalInQueue,
          backgroundColor: colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation(
            state.phase == PlayPhase.speaking
                ? colorScheme.tertiary
                : colorScheme.primary,
          ),
          minHeight: 6,
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  // Play / Pause / Stop / Replay Controls
  // ──────────────────────────────────────────
  Widget _buildControls(VideoSignState state, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ▶ Play / ⏸ Pause toggle
          if (!state.isPlaying && state.phase != PlayPhase.finished)
            _controlButton(
              icon: Icons.play_arrow_rounded,
              label: "Play",
              color: colorScheme.primary,
              onColor: colorScheme.onPrimary,
              onPressed: _handlePlay,
              large: true,
            ),

          if (state.isPlaying && !state.isPaused)
            _controlButton(
              icon: Icons.pause_rounded,
              label: "Pause",
              color: Colors.orange,
              onColor: Colors.white,
              onPressed: () {
                ref.read(videoSignControllerProvider.notifier).pausePlayback();
              },
              large: true,
            ),

          if (state.isPlaying && state.isPaused)
            _controlButton(
              icon: Icons.play_arrow_rounded,
              label: "Resume",
              color: Colors.green,
              onColor: Colors.white,
              onPressed: () {
                ref.read(videoSignControllerProvider.notifier).resumePlayback();
              },
              large: true,
            ),

          const SizedBox(width: 12),

          // ⏹ Stop
          if (state.isPlaying)
            _controlButton(
              icon: Icons.stop_rounded,
              label: "Stop",
              color: Colors.red,
              onColor: Colors.white,
              onPressed: () {
                ref.read(videoSignControllerProvider.notifier).stopPlayback();
              },
            ),

          // 🔁 Replay
          if (!state.isPlaying && state.phase == PlayPhase.finished)
            _controlButton(
              icon: Icons.replay_rounded,
              label: "Replay",
              color: colorScheme.primary,
              onColor: colorScheme.onPrimary,
              onPressed: () {
                ref.read(videoSignControllerProvider.notifier).replay();
              },
              large: true,
            ),
        ],
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color onColor,
    required VoidCallback onPressed,
    bool large = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: onColor,
            shape: const CircleBorder(),
            padding: EdgeInsets.all(large ? 18 : 14),
            elevation: 4,
          ),
          child: Icon(icon, size: large ? 32 : 24),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────
  // Text Input
  // ──────────────────────────────────────────
  Widget _buildTextInput(VideoSignState state, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: TextField(
        controller: _textController,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _handlePlay(),
        enabled: !state.isPlaying,
        textCapitalization: TextCapitalization.characters,
        decoration: InputDecoration(
          hintText: "Type a sentence (e.g. HELLO HOW ARE YOU)",
          prefixIcon: const Icon(Icons.text_fields_rounded),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  // Handle Play
  // ──────────────────────────────────────────
  void _handlePlay() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    FocusScope.of(context).unfocus();
    ref.read(videoSignControllerProvider.notifier).playText(text);
  }
}
