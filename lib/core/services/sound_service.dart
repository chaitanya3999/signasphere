import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final soundServiceProvider = Provider<SoundService>((ref) {
  return SoundService();
});

class SoundService {
  final AudioPlayer _tapPlayer = AudioPlayer();
  final AudioPlayer _warningPlayer = AudioPlayer();
  final AudioPlayer _alarmPlayer = AudioPlayer();

  /// Returns the correct Source for the platform.
  /// Web: serves from web/sounds/ via UrlSource (static files).
  /// Mobile: serves from assets/sounds/ via AssetSource (Flutter assets).
  Source _src(String filename) {
    if (kIsWeb) {
      return UrlSource('sounds/$filename');
    }
    return AssetSource('sounds/$filename');
  }

  SoundService() {
    _init();
  }

  Future<void> _init() async {
    try {
      await _tapPlayer.setSource(_src('tap.mp3'));
      await _warningPlayer.setSource(_src('warning.mp3'));
      await _alarmPlayer.setSource(_src('alarm.mp3'));
      await _alarmPlayer.setReleaseMode(ReleaseMode.loop);
    } catch (_) {}
  }

  Future<void> playTap() async {
    try {
      await _tapPlayer.stop();
      await _tapPlayer.play(_src('tap.mp3'));
    } catch (_) {}
  }

  Future<void> playWarning() async {
    try {
      await _warningPlayer.stop();
      await _warningPlayer.play(_src('warning.mp3'));
    } catch (_) {}
  }

  Future<void> playAlarm() async {
    try {
      if (_alarmPlayer.state != PlayerState.playing) {
        await _alarmPlayer.setReleaseMode(ReleaseMode.loop);
        await _alarmPlayer.play(_src('alarm.mp3'));
      }
    } catch (_) {}
  }

  Future<void> stopAlarm() async {
    try {
      await _alarmPlayer.stop();
    } catch (_) {}
  }

  void dispose() {
    _tapPlayer.dispose();
    _warningPlayer.dispose();
    _alarmPlayer.dispose();
  }
}
