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

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.read(usageControllerProvider).trackEvent(UsageEventType.usedAvatar);

    final state = ref.watch(videoSignControllerProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true, // 🔥 IMPORTANT
      appBar: AppBar(
        title: const Text("Sign Translator"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: bottomInset + 100),
          child: Column(
            children: [

              /// VIDEO
              Container(
                height: 300,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
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
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sign_language,
                          size: 80,
                          color: Colors.grey),
                      SizedBox(height: 12),
                      Text("Ready to Translate",
                          style:
                          TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),

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
                Text(state.currentLabel),
              ],

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [

                    TextField(
                      controller: _textController,
                      textInputAction:
                      TextInputAction.done,
                      onSubmitted: (_) => _handlePlay(),
                      decoration: InputDecoration(
                        hintText:
                        "Type text (e.g. HELLO CAT)",
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
                        ElevatedButton(
                          onPressed: state.isPlaying
                              ? null
                              : _handlePlay,
                          child: const Text("PLAY"),
                        ),
                        if (state.isPlaying)
                          ElevatedButton(
                            style: ElevatedButton
                                .styleFrom(
                                backgroundColor:
                                Colors.red),
                            onPressed: () {
                              ref
                                  .read(
                                  videoSignControllerProvider
                                      .notifier)
                                  .stopPlayback();
                            },
                            child:
                            const Text("STOP"),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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
