import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:nde_email/utils/snackbar/snackbar.dart';

class AudioMessageWidget extends StatefulWidget {
  final String audioUrl;
  final String profileAvatarUrl;
  final bool isSender;

  const AudioMessageWidget({
    super.key,
    required this.audioUrl,
    required this.profileAvatarUrl,
    required this.isSender,
  });

  @override
  _AudioMessageWidgetState createState() => _AudioMessageWidgetState();
}

class _AudioMessageWidgetState extends State<AudioMessageWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;
  bool isLoading = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();

    _audioPlayer.playerStateStream.listen((playerState) {
      if (mounted) {
        setState(() {
          isPlaying = playerState.playing;
        });

        if (playerState.processingState == ProcessingState.completed) {
          setState(() {
            isPlaying = false;
            _position = Duration.zero;
          });
          _audioPlayer.seek(Duration.zero);
        }
      }
    });

    _audioPlayer.durationStream.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration ?? Duration.zero;
        });
      }
    });

    _audioPlayer.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });
  }

  Future<void> _togglePlayPause() async {
    if (isPlaying) {
      await _audioPlayer.pause();
    } else {
      setState(() => isLoading = true);
      try {
        if (_audioPlayer.processingState == ProcessingState.idle) {
          await _audioPlayer.setUrl(widget.audioUrl);
        }
        await _audioPlayer.play();
      } catch (e) {
        log("Error playing audio: $e");
        Messenger.alert(msg: "Error playing audio");
      } finally {
        if (mounted) setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          widget.isSender ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!widget.isSender)
          CircleAvatar(
            backgroundImage: NetworkImage(widget.profileAvatarUrl),
            radius: 20,
          ),
        const SizedBox(width: 6),

        /// **Audio Bubble**
        Container(
          padding: const EdgeInsets.all(10),
          constraints: const BoxConstraints(maxWidth: 250),
          decoration: BoxDecoration(
            color: widget.isSender ? Colors.green[100] : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft:
                  widget.isSender ? const Radius.circular(16) : Radius.zero,
              bottomRight:
                  widget.isSender ? Radius.zero : const Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 2,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              //  Play Button
              IconButton(
                iconSize: 30,
                icon: isLoading
                    ? const CircularProgressIndicator()
                    : Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.green,
                      ),
                onPressed: isLoading ? null : _togglePlayPause,
              ),
              const SizedBox(width: 4),

              //  Audio Progress + Time
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                      ),
                      child: Slider(
                        value: _position.inSeconds.toDouble(),
                        min: 0,
                        max: _duration.inSeconds.toDouble(),
                        activeColor: Colors.green,
                        inactiveColor: Colors.grey[300],
                        onChanged: (value) {
                          _audioPlayer.seek(Duration(seconds: value.toInt()));
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_position),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          _formatDuration(_duration),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        if (widget.isSender) const SizedBox(width: 6),

        if (widget.isSender)
          CircleAvatar(
            backgroundImage: NetworkImage(widget.profileAvatarUrl),
            radius: 20,
          ),
      ],
    );
  }
}
