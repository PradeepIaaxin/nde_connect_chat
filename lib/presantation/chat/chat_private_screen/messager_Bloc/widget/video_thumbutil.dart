// ignore: file_names
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../../../../utils/reusbale/common_import.dart';

class VideoThumbUtil {
  /// ⚡ Memory cache
  static final Map<String, File> _memoryCache = {};

  /// 🔒 In-flight lock (MOST IMPORTANT)
  static final Map<String, Future<File?>> _inFlight = {};

  static Future<File?> generateFromUrl(String videoUrl) {
    if (videoUrl.isEmpty) return Future.value(null);

    final key = videoUrl.hashCode.toString();

    /// 1️⃣ MEMORY CACHE
    final cached = _memoryCache[key];
    if (cached != null) {
      return Future.value(cached);
    }

    /// 2️⃣ IN-FLIGHT (WAIT FOR SAME FUTURE)
    if (_inFlight.containsKey(key)) {
      return _inFlight[key]!;
    }

    /// 3️⃣ CREATE SINGLE FUTURE
    final future = _generate(videoUrl, key);
    _inFlight[key] = future;

    return future;
  }

  static Future<File?> _generate(String videoUrl, String key) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final thumbPath = '${tempDir.path}/thumb_$key.jpg';
      final file = File(thumbPath);

      /// 4️⃣ DISK CACHE
      if (await file.exists()) {
        _memoryCache[key] = file;
        return file;
      }

      /// 5️⃣ GENERATE (ONLY ONCE)
      final path = await VideoThumbnail.thumbnailFile(
        video: videoUrl,
        thumbnailPath: thumbPath,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 200, // FAST
        quality: 90,    // FAST
      );

      if (path == null) return null;

      final generated = File(path);
      _memoryCache[key] = generated;
      return generated;
    } catch (e) {
      debugPrint("❌ Thumbnail error: $e");
      return null;
    } finally {
      /// 6️⃣ RELEASE LOCK
      _inFlight.remove(key);
    }
  }
}
