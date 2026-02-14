import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:nde_email/data/respiratory.dart';
import 'package:nde_email/utils/permission/storage_permission.dart';
import 'package:nde_email/utils/snackbar/snackbar.dart';
import 'package:path/path.dart' as p;
import 'package:media_scanner/media_scanner.dart';
import 'package:path_provider/path_provider.dart';

class FileDownloader {
  static final Dio dio = Dio();

  static Future<void> downloadFile({
    required String fileId,
    required String fileName,
    required String mimeType,
    required String filePath,
  }) async {
    log('Downloading file: $fileId → $filePath');

    bool permissionGranted = await checkStoragePermission();
    if (!permissionGranted) return;

    try {
      final safeName =
      fileName.replaceAll(RegExp(r'[^\w\s.-]'), '_');

      final dir = Directory('/storage/emulated/0/Download');
      if (!(await dir.exists())) {
        await dir.create(recursive: true);
      }

      final filePath2 = p.join(dir.path, safeName);

      final response = await dio.download(
        filePath,
        filePath2,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      final file = File(filePath2);
      log("LOCAL FILE SIZE = ${await file.length()}");

      await MediaScanner.loadMedia(path: filePath2);

      if (mimeType.contains('image')) {
        await GallerySaver.saveImage(filePath2);
      }

      Messenger.alertSuccess("Downloaded successfully");
    } on DioException catch (e) {
      log("DIO ERROR TYPE = ${e.type}");
      log("DIO ERROR = ${e.message}");
    } catch (e) {
      log("Unexpected error = $e");
    }
  }


  static Future<void> downloadImageToGallery(
      String url, String fileName) async {
    bool permissionGranted = await checkStoragePermission();
    if (!permissionGranted) {
      log("Storage permission not granted.");
      return;
    }

    try {
      final tempPath = '/storage/emulated/0/Download/$fileName';
      // Save directly to the Pictures directory so it's visible in Photos
      Directory? picturesDir = await getExternalStorageDirectory();
      if (picturesDir == null) {
        throw Exception('Could not access storage directory');
      }

      String imageFileName = url.split('/').last;
      String savePath = p.join(picturesDir.path, imageFileName);

      log('Downloading image from: $url');
      await dio.download(url, savePath);

      await GallerySaver.saveImage(tempPath, albumName: 'NDE Images');
      log('Image saved to: $savePath');

      // // Scan so Photos app sees it
      // await MediaScanner.loadMedia(path: savePath);

      log('✅ Image saved & visible in Photos: $savePath');

      Messenger.alertSuccess(
        'Image has been successfully downloaded and saved to your gallery.',
      );
    } catch (e) {
      log('Image download failed: $e');
    }
  }
}
