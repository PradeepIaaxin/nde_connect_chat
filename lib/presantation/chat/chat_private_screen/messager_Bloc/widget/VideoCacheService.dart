// lib/utils/video_cache_service.dart
import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/foundation.dart';

class VideoCacheService {
  VideoCacheService._private();
  static final VideoCacheService instance = VideoCacheService._private();

  final Map<String, Future<File?>> _thumbTasks = {};
  final Map<String, Future<String?>> _durationTasks = {};

  String _hash(String input) {
    final bytes = utf8.encode(input);
    return sha1.convert(bytes).toString();
  }

  Future<Directory> _cacheDir() async {
    final tmp = await getTemporaryDirectory();
    final dir = Directory(p.join(tmp.path, 'video_cache_thumbs'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Returns the local thumbnail File (or null if failed)
  Future<File?> getThumbnailFuture(String videoUrl, {int maxHeight = 300, int quality = 75}) {
    final key = _hash(videoUrl);
    if (_thumbTasks.containsKey(key)) return _thumbTasks[key]!;
    final task = _generateThumbnail(videoUrl, key, maxHeight: maxHeight, quality: quality);
    _thumbTasks[key] = task;
    // when finished, keep result cached and remove from map only if failed? we leave it,
    // so further calls will return same Future (which completed).
    return task;
  }

  Future<File?> _generateThumbnail(String videoUrl, String key, {int maxHeight = 300, int quality = 75}) async {
    try {
      final dir = await _cacheDir();
      final targetPath = p.join(dir.path, 'thumb_$key.png');

      // If already exists, return immediately
      final file = File(targetPath);
      if (await file.exists()) return file;

      // Generate thumbnail (video_thumbnail handles network/local)
      final generatedPath = await VideoThumbnail.thumbnailFile(
        video: videoUrl,
        thumbnailPath: targetPath,
        imageFormat: ImageFormat.PNG,
        maxHeight: maxHeight,
        quality: quality,
      );

      if (generatedPath == null) return null;
      return File(generatedPath);
    } catch (e, st) {
      debugPrint('VideoCacheService thumbnail error: $e\n$st');
      return null;
    }
  }

  /// Returns a formatted duration string like "02:34" or null on failure
  Future<String?> getDurationFuture(String videoUrl, {bool isNetwork = true}) {
    final key = _hash(videoUrl);
    if (_durationTasks.containsKey(key)) return _durationTasks[key]!;
    final task = _generateDuration(videoUrl, isNetwork: isNetwork);
    _durationTasks[key] = task;
    return task;
  }

  Future<String?> _generateDuration(String videoUrl, {bool isNetwork = true}) async {
    VideoPlayerController? controller;
    try {
      // note: for local files you might use VideoPlayerController.file
      if (isNetwork) {
        controller = VideoPlayerController.network(videoUrl);
      } else {
        controller = VideoPlayerController.file(File(videoUrl));
      }
      await controller.initialize();
      final d = controller.value.duration;
      final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
      return '$minutes:$seconds';
    } catch (e, st) {
      debugPrint('VideoCacheService duration error: $e\n$st');
      return null;
    } finally {
      try {
        await controller?.dispose();
      } catch (_) {}
    }
  }

  /// Fire-and-forget ensure both thumbnail and duration are cached (useful after fetch)
  Future<void> ensureCached(String videoUrl, {bool isNetwork = true}) async {
    // Start both tasks but don't await them here (optionally await if you want)
    getThumbnailFuture(videoUrl);
    getDurationFuture(videoUrl, isNetwork: isNetwork);
  }
  void precacheForList(List<String> videoUrls) {
    for (final url in videoUrls) {
      getThumbnailFuture(url);
      getDurationFuture(url, isNetwork: url.startsWith('http'));
    }
  }
  /// Optional helper to clear cache (for debugging)
  Future<void> clearCache() async {
    try {
      final dir = await _cacheDir();
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
      _thumbTasks.clear();
      _durationTasks.clear();
    } catch (e) {
      debugPrint('VideoCacheService clearCache error: $e');
    }
  }
}
