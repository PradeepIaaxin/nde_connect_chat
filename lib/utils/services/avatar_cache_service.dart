import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

class AvatarCacheService {
  static Future<String?> cacheAvatar(String userId, String url) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File("${dir.path}/avatar_$userId.png");

      if (await file.exists()) return file.path; // already cached

      final res = await Dio().get(url,
          options: Options(responseType: ResponseType.bytes));

      final Uint8List bytes = Uint8List.fromList(res.data);
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      final resized = img.copyResize(decoded, width: 128, height: 128);
      await file.writeAsBytes(img.encodePng(resized));

      return file.path;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> getCachedAvatar(String userId) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/avatar_$userId.png");
    return await file.exists() ? file.path : null;
  }
}
