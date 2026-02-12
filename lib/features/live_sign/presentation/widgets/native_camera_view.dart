import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signasphere/features/live_sign/application/gesture_controller.dart';

class NativeCameraView extends ConsumerWidget {
  const NativeCameraView({super.key});

  static const String viewType = 'signasphere/native_view';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only render on Android
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
        // Handshake: Tell the Riverpod controller the Native View ID
        ref.read(gestureControllerProvider.notifier).initializeTracking(id);
      },
    );
  }
}