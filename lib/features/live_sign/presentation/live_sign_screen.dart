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

    final bool isWordFresh =
        gestureState.lastWordTime != null &&
            DateTime.now().difference(gestureState.lastWordTime!) <
                const Duration(milliseconds: 1500);

    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [

          /// CAMERA
          const Positioned.fill(
            child: NativeCameraView(),
          ),

          /// WORD FLASH
          IgnorePointer(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              color: isWordFresh
                  ? Colors.greenAccent.withOpacity(0.08)
                  : Colors.transparent,
            ),
          ),

          /// STATUS CHIP
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: _StatusChip(status: gestureState.status),
          ),

          /// BOTTOM PANEL (FIXED)
          Positioned(
            bottom: bottomInset + 70, // 🔥 PUSH ABOVE NAV BAR
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
                mainAxisSize: MainAxisSize.min,
                children: [

                  if (gestureState.sentence.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        gestureState.sentence,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  Text(
                    gestureState.currentGesture,
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// 🔥 CLEAR BUTTON ALWAYS VISIBLE NOW
                  if (gestureState.sentence.isNotEmpty)
                    ElevatedButton(
                      onPressed: () {
                        ref
                            .read(gestureControllerProvider.notifier)
                            .clearSentence();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white12,
                      ),
                      child: const Text("CLEAR SENTENCE"),
                    ),
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
