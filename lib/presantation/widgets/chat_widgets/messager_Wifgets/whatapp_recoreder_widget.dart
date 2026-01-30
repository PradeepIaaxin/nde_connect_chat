import 'dart:async';
import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart'
    as ja; // Alias to avoid conflicts if any
import 'package:nde_email/utils/const/consts.dart';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class WhatsAppRecorderWidget extends StatefulWidget {
  final VoidCallback onStop;
  final Function(String path, int duration) onSend;

  const WhatsAppRecorderWidget({
    super.key,
    required this.onStop,
    required this.onSend,
  });

  @override
  State<WhatsAppRecorderWidget> createState() => _WhatsAppRecorderWidgetState();
}

class _WhatsAppRecorderWidgetState extends State<WhatsAppRecorderWidget> {
  late RecorderController recorderController;
  bool isRecording = false;
  bool isPaused = false;
  Timer? _timer;
  int _recordDuration = 0;
  static const int _minRecordDuration = 1; // seconds

  @override
  void initState() {
    super.initState();
    _initialiseController();
  }

  void _initialiseController() {
    recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.aac_adts // Streamable format
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 44100;

    _initialisePlayer(); // Init player

    // Auto-start recording when this widget is shown
    _startRecording();
  }

  Future<void> _startRecording() async {
    final hasPermission = await Permission.microphone.request().isGranted;
    if (!hasPermission) {
      widget.onStop();
      return;
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      final path =
          '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.aac'; // Changed to .aac

      recordedPath = path; // Store path for playback

      await recorderController.record(path: path);

      setState(() {
        isRecording = true;
        isPaused = false;
      });
      _startTimer();
    } catch (e) {
      debugPrint("Error starting record: $e");
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordDuration++;
      });
    });
  }

  // Player logic
  ja.AudioPlayer? audioPlayer;
  bool isPlaying = false;
  bool isPlayerReady = false;
  String? recordedPath;

  void _initialisePlayer() {
    audioPlayer = ja.AudioPlayer();

    // Listen to player state
    audioPlayer!.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          isPlaying = state.playing;
          if (state.processingState == ja.ProcessingState.completed) {
            isPlaying = false;
            audioPlayer!.seek(Duration.zero);
            audioPlayer!.pause();
          }
        });
      }
    });
  }

  void _pauseRecording() async {
    debugPrint("🔴 _pauseRecording called");
    try {
      await recorderController.pause();
      debugPrint("🔴 recorderController.pause() completed");
      _timer?.cancel();

      // Wait for file flush
      await Future.delayed(const Duration(milliseconds: 300));

      setState(() {
        isPaused = true;
        isPlayerReady = false;
      });

      if (recordedPath != null) {
        final file = File(recordedPath!);

        if (await file.exists()) {
          final len = await file.length();
          debugPrint("🔴 File length: $len bytes");

          if (len > 0) {
            final dir = await getApplicationDocumentsDirectory();
            final tempPath =
                '${dir.path}/temp_playback_${DateTime.now().millisecondsSinceEpoch}.aac';

            await file.copy(tempPath);
            debugPrint("🔴 copied to tempPath: $tempPath");

            await audioPlayer!.setFilePath(tempPath);
            debugPrint("🔴 audioPlayer.setFilePath completed");

            if (mounted) setState(() => isPlayerReady = true);
          } else {
            debugPrint("🔴 File empty, cannot play");
          }
        }
      }

      // Fallback if not ready (e.g. file issue), but allow UI to show pause state
      if (mounted && !isPlayerReady) setState(() => isPlayerReady = true);
    } catch (e, stack) {
      debugPrint("🔴 Error pausing/preparing playback: $e");
      debugPrint(stack.toString());
      if (mounted) {
        setState(() {
          isPaused = true;
          isPlayerReady = true; // Allow interaction even if errored
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error preparing audio: $e")));
      }
    }
  }

  void _resumeRecording() async {
    debugPrint("🟢 _resumeRecording called");
    try {
      if (isPlaying) {
        await audioPlayer!.pause();
      }
      await recorderController.record();
      debugPrint("🟢 recorderController.record() (resume) called");

      _startTimer();
      setState(() {
        isPaused = false;
        isPlaying = false;
        isPlayerReady = false;
      });
    } catch (e) {
      debugPrint("🟢 Error resuming: $e");
    }
  }

  void _playPlayback() async {
    debugPrint("▶️ _playPlayback called");
    try {
      // If we don't have a player ready, try to set it up now
      if (!isPlayerReady ||
          audioPlayer?.duration == null ||
          audioPlayer!.duration == Duration.zero) {
        debugPrint("▶️ Player not ready, preparing now...");

        if (recordedPath != null) {
          final file = File(recordedPath!);
          if (await file.exists()) {
            final len = await file.length();
            if (len == 0) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Audio file is empty")));
              }
              return;
            }

            final dir = await getApplicationDocumentsDirectory();
            final tempPath =
                '${dir.path}/temp_playback_${DateTime.now().millisecondsSinceEpoch}.aac';

            await file.copy(tempPath);

            await audioPlayer!.setFilePath(tempPath);
            setState(() => isPlayerReady = true);
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Recording file not found")));
            }
            return;
          }
        } else {
          return;
        }
      }

      await audioPlayer!.play();
      debugPrint("▶️ audioPlayer.play() called");
      setState(() {
        isPlaying = true;
      });
    } catch (e) {
      debugPrint("▶️ Error playing: $e");
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Playback error: $e")));
      }
    }
  }

  void _pausePlayback() async {
    await audioPlayer!.pause();
    setState(() {
      isPlaying = false;
    });
  }

  // void _stopAndSend() async {
  //   _timer?.cancel();
  //   // Stop player before sending to release file lock if any
  //   await audioPlayer?.stop();
  //
  //   final path = await recorderController.stop();
  //   // widget.onStop(); // Close the widget
  //   if (path != null) {
  //     widget.onSend(path, _recordDuration);
  //   }
  // }
  void _showTooShortMessage() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          "Recording too short",
          style: TextStyle(color: Colors.white),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black87,
      ),
    );
  }

  void _stopAndSend() async {
    _timer?.cancel();

    // Stop playback if running
    await audioPlayer?.stop();

    final path = await recorderController.stop();

    // ❌ DISCARD if duration < 1 second
    if (_recordDuration < _minRecordDuration || path == null) {
      debugPrint("⛔ Recording too short, discarded");
      _showTooShortMessage();
      // delete temp file
      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // reset state
      setState(() {
        _recordDuration = 0;
        isRecording = false;
        isPaused = false;
        isPlayerReady = false;
      });

      // close recorder UI (like WhatsApp)
      widget.onStop();
      return;
    }

    // ✅ VALID recording → send
    widget.onSend(path, _recordDuration);
  }

  void _cancelRecording() async {
    _timer?.cancel();
    await recorderController.stop();
    widget.onStop();
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$minutes:$secs";
  }

  @override
  void dispose() {
    _timer?.cancel();
    recorderController.dispose();
    audioPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2C34), // Dark background
        borderRadius: BorderRadius.circular(25),
      ),
      child: isPaused ? _buildPausedUI() : _buildRecordingUI(),
    );
  }

  Widget _buildRecordingUI() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            // Trash / Delete
            IconButton(
              onPressed: _cancelRecording,
              icon: const Icon(Icons.delete_outline,
                  color: Colors.white70, size: 28),
            ),

            // Timer
            Text(
              _formatDuration(_recordDuration),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500),
            ),

            const SizedBox(width: 8),

            // Waveform
            Expanded(
              child: AudioWaveforms(
                enableGesture: false,
                size: const Size(double.infinity, 40),
                recorderController: recorderController,
                waveStyle: const WaveStyle(
                  waveColor: Colors.white,
                  extendWaveform: true,
                  showMiddleLine: false,
                  spacing: 5.0,
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Pause (Red Icon)
            GestureDetector(
              onTap: _pauseRecording,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withOpacity(0.1),
                ),
                child: const Icon(
                  Icons.pause,
                  color: Colors.red,
                  size: 24,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Send Button (Green)
            GestureDetector(
              onTap: _stopAndSend,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: chatColor),
                child: const Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ],
    );
  }

  Widget _buildPausedUI() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // --- Top Row: Player ---
        Container(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
          child: Row(
            children: [
              // Play/Pause Button
              GestureDetector(
                onTap: isPlaying ? _pausePlayback : _playPlayback,
                child: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow_rounded,
                  color: Colors.grey.shade400,
                  size: 38,
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: AudioWaveforms(
                  enableGesture: false,
                  size: const Size(double.infinity, 30),
                  recorderController: recorderController,
                  waveStyle: const WaveStyle(
                    waveColor: Colors.grey, // Grey for paused state
                    extendWaveform: true,
                    showMiddleLine: false,
                    spacing: 4.0,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Duration
              Text(
                _formatDuration(_recordDuration),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        // --- Bottom Row: Actions ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _deleteRecording,
                icon: const Icon(Icons.delete_outline,
                    color: Colors.white70, size: 28),
              ),

              // Mic (Resume)
              GestureDetector(
                onTap: _resumeRecording,
                child: const Icon(
                  Icons.mic,
                  color: Colors.red,
                  size: 28,
                ),
              ),

              GestureDetector(
                onTap: _stopAndSend,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: chatColor), // WhatsApp Teal
                  child: const Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _deleteRecording() {
    _cancelRecording();
  }
}
