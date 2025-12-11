import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AudioMessageWidget extends StatefulWidget {
  final String audioUrl;
  final bool isSentByMe;

  const AudioMessageWidget({
    super.key,
    required this.audioUrl,
    required this.isSentByMe,
  });

  @override
  _AudioMessageWidgetState createState() => _AudioMessageWidgetState();
}

class _AudioMessageWidgetState extends State<AudioMessageWidget> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio() async {
    if (_isPlaying) {
      await _audioPlayer.stop();
      setState(() {
        _isPlaying = false;
      });
    } else {
      await _audioPlayer.setUrl(widget.audioUrl);
      await _audioPlayer.play();
      setState(() {
        _isPlaying = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _playAudio,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color:
              widget.isSentByMe ? Colors.blue.shade100 : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.black,
            ),
            const SizedBox(width: 8),
            Text(
              'Audio Message',
              style: const TextStyle(color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}
