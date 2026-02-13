import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signasphere/features/live_sign/application/gesture_controller.dart';
import 'package:signasphere/features/live_sign/presentation/widgets/native_camera_view.dart';
import '../../user_tracking/controllers/usage_controller.dart';
import '../../user_tracking/models/usage_event.dart';

class LiveSignScreen extends ConsumerWidget {
  const LiveSignScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(usageControllerProvider).trackEvent(UsageEventType.usedLiveSign);
    final gestureState = ref.watch(gestureControllerProvider);

    // 🔥 Word Recognition Freshness Check (1.5s animation window)
    final bool isWordFresh =
        gestureState.lastWordTime != null &&
            DateTime.now().difference(gestureState.lastWordTime!) <
                const Duration(milliseconds: 1500);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // LAYER 1: Native Camera
          const Positioned.fill(
            child: NativeCameraView(),
          ),

          // LAYER 2: Word Flash Overlay (Subtle Green Screen Flash)
          IgnorePointer(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              color: isWordFresh
                  ? Colors.greenAccent.withOpacity(0.08)
                  : Colors.transparent,
            ),
          ),

          // LAYER 3: Status Indicator (Top Left)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: _StatusChip(status: gestureState.status),
          ),

          // LAYER 4: Bottom UI
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                  stops: [0.2, 1.0],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [

                  // ===============================
                  // 🔥 RECOGNIZED WORD POPUP
                  // ===============================
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 400),
                    opacity: isWordFresh ? 1.0 : 0.0,
                    child: Transform.translate(
                      offset: Offset(0, isWordFresh ? 0 : 20),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.greenAccent.withOpacity(0.5),
                              blurRadius: 15,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.black, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              gestureState.lastRecognizedWord ?? "",
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ===============================
                  // SENTENCE DISPLAY
                  // ===============================
                  if (gestureState.sentence.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isWordFresh
                              ? Colors.greenAccent.withOpacity(0.6)
                              : Colors.white24,
                          width: isWordFresh ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        gestureState.sentence,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          letterSpacing: 3.0,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),

                  // ===============================
                  // LIVE DETECTION LABEL
                  // ===============================
                  Text(
                    "Live Detection:",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ===============================
                  // CURRENT LETTER (LIVE)
                  // ===============================
                  Text(
                    gestureState.currentGesture,
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black45,
                          offset: Offset(0, 2),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),

                  // ===============================
                  // CLEAR BUTTON
                  // ===============================
                  if (gestureState.sentence.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: TextButton.icon(
                        onPressed: () {
                          ref
                              .read(gestureControllerProvider.notifier)
                              .clearSentence();
                        },
                        icon: const Icon(Icons.backspace,
                            size: 16, color: Colors.white54),
                        label: const Text(
                          "CLEAR SENTENCE",
                          style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              letterSpacing: 1.5),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          backgroundColor: Colors.white.withOpacity(0.05),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),

                  // ===============================
                  // ERROR MESSAGE
                  // ===============================
                  if (gestureState.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        gestureState.errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.redAccent, fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    if (status.contains("Active") || status.contains("Recognized")) {
      color = Colors.greenAccent;
    } else if (status.contains("Error")) {
      color = Colors.redAccent;
    } else {
      color = Colors.orangeAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.6), blurRadius: 6),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            status.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
