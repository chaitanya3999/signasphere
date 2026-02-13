import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signasphere/features/live_sign/application/gesture_controller.dart';

class NativeCameraView extends ConsumerWidget {
  const NativeCameraView({super.key});

  // 🔥 MUST MATCH MainActivity.kt
  static const String viewType = 'sign_language_view';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return const Center(
        child: Text("This feature is only available on Android devices."),
      );
    }

    return AndroidView(
      viewType: viewType,
      layoutDirection: TextDirection.ltr,
      creationParams: const <String, dynamic>{},
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: (int id) {
        ref.read(gestureControllerProvider.notifier).initializeTracking(id);
      },
    );
  }
}
