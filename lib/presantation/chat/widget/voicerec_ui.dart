import 'package:flutter/material.dart';

class VoiceRecordingWidget extends StatelessWidget {
  final bool isRecording;
  final bool isPaused;
  final Duration recordDuration;
  final VoidCallback? onStartRecording;
  final VoidCallback? onPauseRecording;
  final VoidCallback? onResumeRecording;
  final VoidCallback? onStopRecording;
  final VoidCallback? onPlayRecording;
  final VoidCallback? onSendRecording;
  final VoidCallback? onCancel;
  final String? recordedFilePath;
  final String Function(Duration duration) formatDuration;

  const VoiceRecordingWidget({
    super.key,
    required this.isRecording,
    required this.isPaused,
    required this.recordDuration,
    required this.formatDuration,
    this.onStartRecording,
    this.onPauseRecording,
    this.onResumeRecording,
    this.onStopRecording,
    this.onPlayRecording,
    this.onSendRecording,
    this.onCancel,
    this.recordedFilePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isRecording || isPaused)
            Row(
              children: [
                Icon(
                  Icons.mic,
                  color: isPaused ? Colors.orange : Colors.red,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  formatDuration(recordDuration),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 100,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isPaused ? Colors.orange[400] : Colors.red[400],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      isPaused ? "Paused" : "Recording...",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (!isRecording && !isPaused)
                    IconButton(
                      icon: const Icon(Icons.mic, color: Colors.greenAccent),
                      onPressed: onStartRecording,
                    )
                  else if (isRecording)
                    IconButton(
                      icon: const Icon(Icons.pause, color: Colors.orange),
                      onPressed: onPauseRecording,
                    )
                  else if (isPaused)
                    IconButton(
                      icon: const Icon(Icons.play_arrow,
                          color: Colors.greenAccent),
                      onPressed: onResumeRecording,
                    ),
                  if (isRecording || isPaused)
                    IconButton(
                      icon: const Icon(Icons.stop, color: Colors.red),
                      onPressed: onStopRecording,
                    ),
                ],
              ),
              Row(
                children: [
                  if (recordedFilePath != null)
                    IconButton(
                      icon: const Icon(Icons.play_circle_fill,
                          color: Colors.white),
                      onPressed: onPlayRecording,
                    ),
                  if (recordedFilePath != null)
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.blueAccent),
                      onPressed: onSendRecording,
                    ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: onCancel,
                  ),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }
}
