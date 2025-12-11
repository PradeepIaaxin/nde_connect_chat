import 'dart:io';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../../utils/reusbale/common_import.dart';

class VideoThumbUtil {
  static Future<File?> generateFromUrl(String videoUrl) async {
    try {
      final tempDir = await getTemporaryDirectory();

      // ✅ UNIQUE FILE NAME BASED ON VIDEO URL HASH
      final fileName =
          'thumb_${videoUrl.hashCode}_${DateTime.now().millisecondsSinceEpoch}.png';
      final uniqueName = videoUrl.hashCode.toString();
      final thumbPath = '${tempDir.path}/thumb_$uniqueName.png';

      final generatedPath = await VideoThumbnail.thumbnailFile(
        video: videoUrl,
        thumbnailPath: thumbPath, // ✅ UNIQUE FILE
        imageFormat: ImageFormat.PNG,
        maxHeight: 300,
        quality: 75,
      );

      if (generatedPath == null) return null;
      return File(generatedPath);
    } catch (e) {
      debugPrint("❌ Reply thumbnail error: $e");
      return null;
    }
  }
}
