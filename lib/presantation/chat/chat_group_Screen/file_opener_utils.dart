import 'dart:io';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;
import 'package:nde_email/utils/snackbar/snackbar.dart';

class FileOpenerUtils {
  /// 🔓 UNIVERSAL FILE OPENER
  static Future<void> openFile(
      String urlOrPath,
      String? fileType,
      ) async {

    /// 1️⃣ Local file → open directly
    if (!urlOrPath.startsWith('http')) {
      final result = await OpenFilex.open(urlOrPath);

      if (result.type != ResultType.done) {
        Messenger.alertError("Could not open local file.");
      }
      return;
    }

    try {
      /// 2️⃣ Storage path
      const String packageName = "com.nowdigitaleasy.NDEconnect";

      final String baseDir =
          "/storage/emulated/0/Android/media/$packageName/NowDigitalEasy/Media";

      final Directory directory = Directory(baseDir);

      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      /// 3️⃣ File name extraction
      final String fileName =
      urlOrPath.split('/').last.split('?').first;

      String safeFileName = fileName.isEmpty
          ? 'document_${DateTime.now().millisecondsSinceEpoch}'
          : fileName;

      /// 4️⃣ Extension detection
      String extension = p.extension(safeFileName);

      if (extension.isEmpty) {
        extension = _detectExtension(fileType, safeFileName);

        if (extension.isNotEmpty) {
          safeFileName += extension;
        }
      }

      final String finalPath =
      p.join(baseDir, safeFileName);

      final File targetFile = File(finalPath);

      /// 5️⃣ Already downloaded
      if (await targetFile.exists()) {
        final result = await OpenFilex.open(finalPath);

        if (result.type != ResultType.done) {
          Messenger.alertError("Could not open file.");
        }
        return;
      }

      /// 6️⃣ Permission
      if (Platform.isAndroid) {
        await Permission.storage.request();
        await Permission.manageExternalStorage.request();
      }

      /// 7️⃣ Download
      Messenger.alertSuccess("Downloading document...");

      await Dio().download(urlOrPath, finalPath);

      Messenger.alertSuccess(
          "Saved to NowDigitalEasy/Media");

      /// 8️⃣ Open downloaded file
      final result = await OpenFilex.open(finalPath);

      if (result.type == ResultType.noAppToOpen) {
        Messenger.alertError(
          "Install Excel / Sheets / WPS Office to open this file",
        );
      } else if (result.type != ResultType.done) {
        Messenger.alertError(
            "Could not open downloaded file.");
      }
    } catch (e) {
      Messenger.alertError("Failed to open file.");
    }
  }

  /// 📄 Extension detector
  static String _detectExtension(
      String? fileType,
      String fileName,
      ) {
    if (fileType != null) {
      final lower = fileType.toLowerCase();

      if (lower.contains('pdf')) return '.pdf';
      if (lower.contains('word') || lower.contains('doc')) {
        return '.docx';
      }
      if (lower.contains('excel') || lower.contains('sheet')) {
        return '.xlsx';
      }
      if (lower.contains('presentation') ||
          lower.contains('powerpoint')) {
        return '.pptx';
      }
      if (lower.contains('image')) return '.jpg';
      if (lower.contains('video')) return '.mp4';
      if (lower.contains('text')) return '.txt';
      if (lower.contains('csv')) return '.csv';
      if (lower.contains('zip')) return '.zip';
      if (lower.contains('rar')) return '.rar';
      if (lower.contains('json')) return '.json';
      if (lower.contains('xml')) return '.xml';
    }

    /// Fallback filename detection
    final lowerName = fileName.toLowerCase();

    if (lowerName.contains('pdf')) return '.pdf';
    if (lowerName.contains('doc')) return '.docx';
    if (lowerName.contains('xls')) return '.xlsx';
    if (lowerName.contains('ppt')) return '.pptx';

    return '';
  }
}
