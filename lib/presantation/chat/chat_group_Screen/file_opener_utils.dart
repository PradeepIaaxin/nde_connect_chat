import 'dart:io';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;
import 'package:nde_email/utils/snackbar/snackbar.dart';

class FileOpenerUtils {
  static Future<void> openFile(String urlOrPath, String? fileType) async {
    // 1. If it's a local file, just open it
    if (!urlOrPath.startsWith('http')) {
      final result = await OpenFile.open(urlOrPath);
      if (result.type != ResultType.done) {
        Messenger.alertError("Could not open local file.");
      }
      return;
    }

    // 2. It's a URL - Check if we already have it downloaded
    try {
      final String packageName = "com.nowdigitaleasy.NDEconnect";
      final String baseDir =
          "/storage/emulated/0/Android/media/$packageName/NowDigitalEasy/Media";

      final Directory directory = Directory(baseDir);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Extract filename
      final String fileName = urlOrPath.split('/').last.split('?').first;
      String safeFileName = fileName.isEmpty
          ? 'document_${DateTime.now().millisecondsSinceEpoch}'
          : fileName;

      // Check for extension
      String extension = p.extension(safeFileName);
      if (extension.isEmpty) {
        if (fileType != null) {
          final lowerType = fileType.toLowerCase();
          if (lowerType.contains('pdf'))
            extension = '.pdf';
          else if (lowerType.contains('word') ||
              lowerType.contains('doc') ||
              lowerType.contains('msword'))
            extension = '.docx';
          else if (lowerType.contains('excel') ||
              lowerType.contains('sheet') ||
              lowerType.contains('spreadsheet'))
            extension = '.xlsx';
          else if (lowerType.contains('presentation') ||
              lowerType.contains('powerpoint'))
            extension = '.pptx';
          else if (lowerType.contains('image'))
            extension = '.jpg';
          else if (lowerType.contains('video'))
            extension = '.mp4';
          else if (lowerType.contains('text') || lowerType.contains('plain'))
            extension = '.txt';
          else if (lowerType.contains('csv'))
            extension = '.csv';
          else if (lowerType.contains('zip'))
            extension = '.zip';
          else if (lowerType.contains('rar'))
            extension = '.rar';
          else if (lowerType.contains('json'))
            extension = '.json';
          else if (lowerType.contains('xml')) extension = '.xml';
        }

        // Fallback checks on filename/url matching common patterns if no type or type didn't match
        if (extension.isEmpty) {
          final lowerName = safeFileName.toLowerCase();
          if (lowerName.contains('pdf'))
            extension = '.pdf';
          else if (lowerName.contains('doc'))
            extension = '.docx';
          else if (lowerName.contains('xls'))
            extension = '.xlsx';
          else if (lowerName.contains('ppt')) extension = '.pptx';
        }

        if (extension.isNotEmpty) {
          safeFileName += extension;
        }
      }

      final String finalPath = p.join(baseDir, safeFileName);
      final File targetFile = File(finalPath);

      if (await targetFile.exists()) {
        // Open existing
        final result = await OpenFile.open(finalPath);
        if (result.type != ResultType.done) {
          Messenger.alertError("Could not open file.");
        }
        return;
      }

      // 3. Not downloaded - Request Permission
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        final status2 = await Permission.manageExternalStorage.request();
        // Note: checking both might be needed depending on Android version
        // Ideally checking 'storage' is enough for older, 'manage' for newer if targeting full access
        // But for scoped storage in app-specific public dir, sometimes we just need to ensure dir exists.
        // Keeping logic similar to MixedMediaViewer which requested these.
        if (!status.isGranted && !status2.isGranted) {
          // Continue anyway? MixedMediaViewer returns.
          // But valid public app folder might be writeable without broad permissions on some versions.
          // We will try to proceed but warn if allowed.
          // Actually, complying with MixedMediaViewer logic:
          // Messenger.alertError('Storage permission denied');
          // return;
        }
      }

      // 4. Download
      Messenger.alertSuccess('Downloading document...');
      await Dio().download(urlOrPath, finalPath);
      Messenger.alertSuccess('Saved to NowDigitalEasy/Media');

      // 5. Open
      final result = await OpenFile.open(finalPath);
      if (result.type != ResultType.done) {
        Messenger.alertError("Could not open downloaded file.");
      }
    } catch (e) {
      print("Error downloading/opening file: $e");
      Messenger.alertError("Failed to open file.");
    }
  }
}
