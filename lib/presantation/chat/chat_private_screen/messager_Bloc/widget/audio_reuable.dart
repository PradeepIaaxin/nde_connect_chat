// audio_recorder_helper.dart

import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';

class AudioRecorderHelper with ChangeNotifier {
  bool isRecording = false;
  bool isPaused = false;
  int recordDuration = 0;
  String? recordedFilePath;

  Timer? _timer;

  // Start recording
  Future<void> startRecording() async {
    // await _recorder.startRecorder(toFile: 'voice.aac');
    isRecording = true;
    isPaused = false;
    recordDuration = 0;
    // _startTimer();
    notifyListeners();
  }

  // Pause recording
  Future<void> pauseRecording() async {
    // await _recorder.pauseRecorder();
    isPaused = true;
    _timer?.cancel();
    notifyListeners();
  }

  // Resume recording
  Future<void> resumeRecording() async {
    // await _recorder.resumeRecorder();
    isPaused = false;
    // _startTimer();
    notifyListeners();
  }

  // Stop recording
  Future<void> stopRecording() async {
    // recordedFilePath = await _recorder.stopRecorder();
    _timer?.cancel();
    isRecording = false;
    isPaused = false;
    notifyListeners();
  }

  // Play recording
  Future<void> playRecording() async {
    if (recordedFilePath != null) {
      // await _player.startPlayer(fromURI: recordedFilePath);
      log("Playing: $recordedFilePath");
    }
  }

  // Send recording
  void sendRecording() {
    if (recordedFilePath != null) {
      log("Send: $recordedFilePath");
    }
  }

  // Cancel reply (if used in chat context)
  void cancelReply() {
    recordedFilePath = null;
    notifyListeners();
  }
}
