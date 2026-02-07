import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:nde_email/utils/audio/audio_utils.dart';
import 'package:nde_email/utils/const/consts.dart';

class AudioMessageWidget extends StatefulWidget {
  final String audioUrl;
  final String profileAvatarUrl;
  final bool isSender;
  final String? duration;
  final String? timestamp;
  final String? status;
  final bool showContainer;
  final String? mimeType;

  const AudioMessageWidget({
    super.key,
    required this.audioUrl,
    required this.profileAvatarUrl,
    required this.isSender,
    this.duration,
    this.timestamp,
    this.status,
    this.showContainer = true,
    this.mimeType,
  });

  @override
  _AudioMessageWidgetState createState() => _AudioMessageWidgetState();
}

class _AudioMessageWidgetState extends State<AudioMessageWidget> {
  AudioPlayer? _audioPlayer; // Make nullable for lazy init
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlayerInitialized = false;

  @override
  void initState() {
    super.initState();
    // Lazy init: Do NOT initialize _audioPlayer here.
    // Just parse the duration from the widget to show it immediately.
    _parseDuration();
  }

  void _parseDuration() {
    if (widget.duration != null) {
      final secs = int.tryParse(widget.duration!) ?? 0;
      if (secs > 0) {
        _duration = Duration(seconds: secs);
      }
    }
  }

  Future<void> _playAudio() async {
    // Initialize player if it hasn't been already
    if (_audioPlayer == null) {
      _audioPlayer = AudioPlayer();
      await _initPlayer();
    }
    _audioPlayer!.play();
  }

  Future<void> _initPlayer() async {
    if (_audioPlayer == null) return;

    try {
      if (widget.audioUrl.startsWith('http')) {
        await _audioPlayer!.setUrl(widget.audioUrl);
      } else {
        await _audioPlayer!.setFilePath(widget.audioUrl);
      }

      // Update duration from player if we didn't have it or if it differs
      final d = _audioPlayer!.duration;
      if (d != null && d != _duration) {
        if (mounted) {
          setState(() {
            _duration = d;
          });
        }
      }

      _audioPlayer!.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
            if (state.processingState == ProcessingState.completed) {
              _isPlaying = false;
              _position = Duration.zero;
              _audioPlayer?.stop();
              _audioPlayer?.seek(Duration.zero);
            }
          });
        }
      });

      _audioPlayer!.positionStream.listen((position) {
        if (mounted) {
          setState(() {
            _position = position;
          });
        }
      });

      // Also listen to duration changes in case they come in later
      _audioPlayer!.durationStream.listen((duration) {
        if (duration != null && mounted) {
          setState(() {
            _duration = duration;
          });
        }
      });

      if (mounted) {
        setState(() {
          _isPlayerInitialized = true;
        });
      }
    } catch (e) {
      debugPrint("Error initializing audio player: $e");
    }
  }

  @override
  void didUpdateWidget(AudioMessageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audioUrl != widget.audioUrl) {
      // Reset everything
      _audioPlayer?.dispose();
      _audioPlayer = null;
      setState(() {
        _isPlayerInitialized = false;
        _isPlaying = false;
        _position = Duration.zero;
        _duration = Duration.zero;
      });
      _parseDuration();
    }
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    if (d.inHours > 0) {
      return "${twoDigits(d.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  Widget _buildStatusIcon() {
    if (!widget.isSender) return const SizedBox.shrink();

    IconData icon = Icons.access_time;
    Color color = Colors.grey[600]!;

    switch (widget.status?.toLowerCase()) {
      case 'read':
      case 'seen':
        icon = Icons.done_all;
        color = Colors.blue;
        break;
      case 'delivered':
        icon = Icons.done_all;
        color = Colors.grey[600]!;
        break;
      case 'sent':
      case 'sending':
        icon = Icons.check;
        color = Colors.grey[600]!;
        // ✅ ADD SOUND PLAYBACK HERE

        break;
      default:
        icon = Icons.access_time;
        color = Colors.grey[600]!;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Icon(icon, size: 16, color: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final senderColor = Color.fromARGB(255, 226, 242, 249);
    final receiverColor = Colors.white;

    final Duration displayDuration = (_duration.inSeconds > 0)
        ? _duration
        : Duration(seconds: int.tryParse(widget.duration ?? "0") ?? 0);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: GestureDetector(
                onTap: () {
                  if (_isPlaying) {
                    _audioPlayer?.pause();
                  } else {
                    _playAudio();
                  }
                },
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: widget.isSender
                      ? chatColor.withValues(alpha:0.2)
                      : const Color.fromARGB(255, 213, 212, 212),
                  child: Icon(
                    widget.mimeType == "audio/aac"
                        ? Icons.mic_none
                        : Icons.music_note_outlined,
                    color: widget.isSender ? chatColor : Colors.grey[700],
                    size: 24,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: GestureDetector(
                onTap: () {
                  if (_isPlaying) {
                    _audioPlayer?.pause();
                  } else {
                    _playAudio();
                  }
                },
                child: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: widget.isSender ? chatColor : Colors.grey[700],
                  size: 28,
                ),
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 14),
                  activeTrackColor:
                      widget.isSender ? chatColor : Colors.grey[700],
                  inactiveTrackColor: widget.isSender
                      ? chatColor.withValues(alpha:0.2)
                      : Colors.grey[300],
                  thumbColor: widget.isSender ? chatColor : Colors.grey[700],
                ),
                child: Slider(
                  value: _position.inSeconds
                      .toDouble()
                      .clamp(0.0, displayDuration.inSeconds.toDouble()),
                  min: 0,
                  max: displayDuration.inSeconds.toDouble() > 0
                      ? displayDuration.inSeconds.toDouble()
                      : 1.0,
                  onChanged: (value) {
                    _audioPlayer?.seek(Duration(seconds: value.toInt()));
                  },
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8, right: 8, bottom: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(displayDuration),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
              Row(
                children: [
                  Text(
                    widget.timestamp ?? "",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (widget.isSender) _buildStatusIcon(),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    if (!widget.showContainer) return content;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: widget.isSender ? senderColor : receiverColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          )
        ],
      ),
      constraints: const BoxConstraints(maxWidth: 280),
      child: content,
    );
  }
}
