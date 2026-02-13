import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/stt_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../user_tracking/controllers/usage_controller.dart';
import '../../user_tracking/models/usage_event.dart';
import 'package:video_player/video_player.dart';
import '../application/video_sign_controller.dart';

class AvatarScreen extends ConsumerStatefulWidget {
  const AvatarScreen({super.key});

  @override
  ConsumerState<AvatarScreen> createState() => _AvatarScreenState();
}

class _AvatarScreenState extends ConsumerState<AvatarScreen> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.read(usageControllerProvider).trackEvent(UsageEventType.usedAvatar);
    final state = ref.watch(videoSignControllerProvider);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("Sign Translator"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [

            /// VIDEO AREA
            Expanded(
              flex: 3,
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                    )
                  ],
                ),
                child: Center(
                  child: state.controller != null &&
                      state.controller!.value.isInitialized
                      ? AspectRatio(
                    aspectRatio:
                    state.controller!.value.aspectRatio,
                    child: VideoPlayer(state.controller!),
                  )
                      : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sign_language,
                          size: 80, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        "Ready to Translate",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            /// PROGRESS BAR
            if (state.isPlaying) ...[
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 32),
                child: LinearProgressIndicator(
                  value: state.totalInQueue == 0
                      ? 0
                      : state.queueIndex /
                      state.totalInQueue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.currentLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],

            /// INPUT AREA
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [
                    TextField(
                      controller: _textController,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _handlePlay(),
                      decoration: InputDecoration(
                        hintText: "Type text (e.g. HELLO CAT)",
                        border: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceEvenly,
                      children: [

                        /// PLAY
                        ElevatedButton(
                          onPressed: state.isPlaying
                              ? null
                              : _handlePlay,
                          child: const Text("PLAY"),
                        ),

                        /// STOP
                        if (state.isPlaying)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red),
                            onPressed: () {
                              ref
                                  .read(
                                  videoSignControllerProvider
                                      .notifier)
                                  .stopPlayback();
                            },
                            child: const Text("STOP"),
                          ),

                        /// REPLAY
                        if (!state.isPlaying &&
                            state.currentLabel ==
                                "Finished")
                          ElevatedButton(
                            onPressed: _handlePlay,
                            child: const Text("REPLAY"),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handlePlay() {
    final text = _textController.text.trim();

    if (text.isEmpty) return;

    FocusScope.of(context).unfocus();

    ref
        .read(videoSignControllerProvider.notifier)
        .playText(text);
  }
}
