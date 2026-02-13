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
      // Configure AudioContext for Android to reduce latency for UI sounds
      // and ensure alarms play correctly.
      final AudioContext audioContext = AudioContext(
        android: AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.assistanceSonification,
          audioFocus: AndroidAudioFocus.none,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.ambient,
          options: {
            AVAudioSessionOptions.mixWithOthers,
          },
        ),
      );

      // Apply global context (or per player if needed, but global is often sufficient for UI apps)
      await AudioPlayer.global.setAudioContext(audioContext);

      await _tapPlayer.setSource(_src('tap.mp3'));
      await _tapPlayer.setPlayerMode(PlayerMode.lowLatency); // Optimize for short sounds

      await _warningPlayer.setSource(_src('warning.mp3'));
      await _warningPlayer.setPlayerMode(PlayerMode.lowLatency);

      await _alarmPlayer.setSource(_src('alarm.mp3'));
      await _alarmPlayer.setReleaseMode(ReleaseMode.loop);
      
      // For alarm, we might want a different context if global doesn't suit, 
      // but usually assistanceSonification or alarm usage works well.
      // If we needed specific alarm routing:
      // await _alarmPlayer.setAudioContext(audioContext.copyWith(android: ...usageType: AndroidUsageType.alarm...));
    } catch (_) {}
  }

  Future<void> playTap() async {
    try {
      if (_tapPlayer.state == PlayerState.playing) {
        await _tapPlayer.stop();
      }
      await _tapPlayer.resume(); // resume works better with lowLatency mode for re-triggering
    } catch (_) {}
  }

  Future<void> playWarning() async {
    try {
       if (_warningPlayer.state == PlayerState.playing) {
        await _warningPlayer.stop();
      }
      await _warningPlayer.resume();
    } catch (_) {}
  }

  Future<void> playAlarm() async {
    try {
      if (_alarmPlayer.state != PlayerState.playing) {
        // Ensure alarm context for this specific player to override silence/DND if possible
        // Note: audioplayers 6.x implies global context mostly, but let's try to set it if needed
        // or just rely on the sound itself.
        // For distinct alarm behavior, we might re-apply context:
        await _alarmPlayer.setAudioContext(AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.alarm, // CRITICAL for alarms
            audioFocus: AndroidAudioFocus.gainTransient, 
          ),
          iOS: AudioContextIOS(
             category: AVAudioSessionCategory.playback,
             options: {}
          )
        ));
        
        await _alarmPlayer.setReleaseMode(ReleaseMode.loop);
        await _alarmPlayer.play(_src('alarm.mp3'));
      }
    } catch (_) {}
  }

  Future<void> stopAlarm() async {
    try {
      await _alarmPlayer.stop();
      
      // Revert context to normal UI sounds if we changed it globally or for this player
       final AudioContext uiContext = AudioContext(
        android: AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.assistanceSonification,
          audioFocus: AndroidAudioFocus.none,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.ambient,
           options: {AVAudioSessionOptions.mixWithOthers},
        ),
      );
      await AudioPlayer.global.setAudioContext(uiContext);
      
    } catch (_) {}
  }

  void dispose() {
    _tapPlayer.dispose();
    _warningPlayer.dispose();
    _alarmPlayer.dispose();
  }
}
