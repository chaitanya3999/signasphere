import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final gestureRepositoryProvider = Provider<GestureRepository>((ref) {
  return GestureRepository();
});

class GestureRepository {
  /// Stream of 21 landmarks, each having [x, y, z] coordinates.
  Stream<List<List<double>>> getLandmarkStream(int viewId) {
    final channel = EventChannel('signasphere/gesture_channel_$viewId');

    return channel.receiveBroadcastStream().map((event) {
      // Parse Native List<Object> to Dart List<List<double>>
      // Native sends: [[0.5, 0.5, 0.0], [0.4, ...], ...]
      if (event is List) {
        return event.map<List<double>>((point) {
          if (point is List) {
            return point.map<double>((coord) => (coord as num).toDouble()).toList();
          }
          return [0.0, 0.0, 0.0];
        }).toList();
      }
      return [];
    });
  }
}