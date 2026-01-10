import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal() {
    // Optional: observe player lifecycle
    _audioPlayer.onPlayerComplete.listen((_) {
      _isPlaying = false;
      _log('Playback completed');
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      _log('Player state → $state');
    });
  }

  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _initialized = false;
  bool _isPlaying = false;

  // ------------------------------------------------------------
  // Initialization (ONE TIME ONLY)
  // ------------------------------------------------------------
  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    _log('Initializing audio player');

    // IMPORTANT: never use ReleaseMode.release in chat apps
    await _audioPlayer.setReleaseMode(ReleaseMode.stop);

    _initialized = true;
  }

  // ------------------------------------------------------------
  // Safe stop (callable from UI dispose)
  // ------------------------------------------------------------
  Future<void> stopSafely() async {
    if (!_initialized) return;

    try {
      if (_isPlaying) {
        _log('Stopping playback');
        await _audioPlayer.stop();
        _isPlaying = false;
      }
    } catch (e) {
      _log('stopSafely ignored: $e');
    }
  }

  // ------------------------------------------------------------
  // Internal play helper
  // ------------------------------------------------------------
  Future<void> _play(String assetPath) async {
    try {
      await _ensureInitialized();
      await stopSafely();

      _log('Playing asset → $assetPath');

      _isPlaying = true;

      await _audioPlayer.play(
        AssetSource(assetPath),
        mode: PlayerMode.lowLatency, 
      );
    } catch (e, stack) {
      _isPlaying = false;
      _log('Error playing $assetPath');
      _log(e.toString());
      _log(stack.toString());
    }
  }

  // ------------------------------------------------------------
  // Public APIs
  // ------------------------------------------------------------
  Future<void> playMessageSentSound() => _play('audio/message_sent.mp3');

  Future<void> playMessageDeliveredSound() => _play('audio/message_sent.mp3');

  Future<void> playMessageReadSound() => _play('audio/message_sent.mp3');

  // ------------------------------------------------------------
  // OPTIONAL: App-exit only disposal (never call from UI)
  // ------------------------------------------------------------
  Future<void> disposeSafely() async {
    try {
      _log('Disposing audio player (app exit)');
      await _audioPlayer.dispose();
      _initialized = false;
      _isPlaying = false;
    } catch (e) {
      _log('disposeSafely ignored: $e');
    }
  }

  // ------------------------------------------------------------
  // Logger
  // ------------------------------------------------------------
  void _log(String msg) {
    // ignore: avoid_print
    print('[AudioPlayerService] $msg');
  }
}
