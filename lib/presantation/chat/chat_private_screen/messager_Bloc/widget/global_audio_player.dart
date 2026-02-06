import 'package:just_audio/just_audio.dart';

class GlobalAudioPlayer {
  static final GlobalAudioPlayer _instance =
      GlobalAudioPlayer._internal();

  factory GlobalAudioPlayer() => _instance;

  GlobalAudioPlayer._internal();

  final AudioPlayer player = AudioPlayer();

  String? currentUrl;
}
