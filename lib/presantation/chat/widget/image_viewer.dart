import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Smart image viewer: uses cache, refreshes presigned URLs when needed,
/// and falls back to an error UI with retry.
class ImageViewer {
  /// Replace this with your server base or leave null if not needed.
  static const String serverBaseUrl = '';

  /// Public entry: opens the image smartly.
  static Future<void> show(BuildContext context, String imageUrl) async {
    if (imageUrl.isEmpty) {
      log("ImageViewer: imageUrl empty");
      _showErrorDialog(context, "Image URL is empty");
      return;
    }

    log("ImageViewer: requested to open -> $imageUrl");

    try {
      // ✅ STEP 0: LOCAL FILE SUPPORT (CRITICAL FIX)
      if (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://')) {
        final file = File(imageUrl);
        if (file.existsSync()) {
          log("ImageViewer: opening LOCAL image directly -> ${file.path}");
          _openDialogWithFile(context, file);
          return;
        } else {
          _showErrorDialog(context, "Local image file not found.");
          return;
        }
      }

      // ✅ STEP 1: Try to use cache manager (for NETWORK images)
      final cacheManager = DefaultCacheManager();
      final cached = await cacheManager.getFileFromCache(imageUrl);
      if (cached != null && await cached.file.exists()) {
        log("ImageViewer: found cached file -> ${cached.file.path}");
        _openDialogWithFile(context, cached.file);
        return;
      }

      // ✅ STEP 2: Handle expired presigned URLs
      if (_looksLikePresignedUrl(imageUrl) && _isPresignedUrlExpired(imageUrl)) {
        log("ImageViewer: presigned url expired -> requesting fresh URL");
        final fresh = await fetchFreshPresignedUrlFromServer(imageUrl);
        if (fresh != null && fresh.isNotEmpty) {
          final file = await cacheManager.getSingleFile(fresh);
          if (file.existsSync()) {
            _openDialogWithFile(context, file);
            return;
          }
        }
      }

      // ✅ STEP 3: Download normally
      log("ImageViewer: downloading -> $imageUrl");
      final downloaded = await cacheManager.getSingleFile(imageUrl);
      if (downloaded.existsSync()) {
        _openDialogWithFile(context, downloaded);
        return;
      }

      _showErrorDialog(context, "Image failed to load.");
    } catch (e, st) {
      log("ImageViewer: error -> $e\n$st");
      _showErrorDialog(context, "Error opening image: $e");
    }
  }

  // Opens the dialog and shows a File image inside InteractiveViewer
  static void _openDialogWithFile(BuildContext context, File file) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(10),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.8,
            maxScale: 4,
            child: Image.file(
              file,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) {
                log("ImageViewer: Image.file error: $error\n$stackTrace");
                return const Center(
                  child: Text(
                    "Failed to load image",
                    style: TextStyle(color: Colors.white),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  static void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Unable to open image'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  // ----- Helpers for presigned-s3 detection + expiry check -----

  static bool _looksLikePresignedUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.queryParameters.keys.any((k) => k.toLowerCase().startsWith('x-amz-'));
    } catch (_) {
      return false;
    }
  }

  /// Checks S3 presign parameters (X-Amz-Date + X-Amz-Expires) to decide expiry.
  static bool _isPresignedUrlExpired(String url) {
    try {
      final u = Uri.parse(url);
      final xDate = u.queryParameters['X-Amz-Date'] ?? u.queryParameters['x-amz-date'];
      final expires = int.tryParse(u.queryParameters['X-Amz-Expires'] ?? u.queryParameters['x-amz-expires'] ?? '') ?? 0;
      if (xDate == null || expires == 0) return false;

      // xDate format: YYYYMMDDTHHMMSSZ, e.g. 20251204T052751Z
      final year = int.parse(xDate.substring(0, 4));
      final month = int.parse(xDate.substring(4, 6));
      final day = int.parse(xDate.substring(6, 8));
      final hour = int.parse(xDate.substring(9, 11));
      final minute = int.parse(xDate.substring(11, 13));
      final second = int.parse(xDate.substring(13, 15));
      final signedAt = DateTime.utc(year, month, day, hour, minute, second);
      final expiryAt = signedAt.add(Duration(seconds: expires));
      final nowUtc = DateTime.now().toUtc();
      log("ImageViewer: presign signedAt=$signedAt expiryAt=$expiryAt now=$nowUtc");
      return nowUtc.isAfter(expiryAt);
    } catch (e) {
      log("ImageViewer: presign parse error: $e");
      return false;
    }
  }

  // ----- Server integration point -----
  // YOU MUST IMPLEMENT this to call your backend which returns a fresh presigned URL.
  // The input parameter is the existing URL or object key — adapt to your backend API.
  static Future<String?> fetchFreshPresignedUrlFromServer(String currentUrlOrKey) async {
    // Example:
    // final key = extractKeyFromUrl(currentUrlOrKey);
    // final resp = await MyApi.getPresignedUrl(key);
    // return resp?.url;
    //
    // For now, return null so caller will try fallback download (which may fail).
    log("ImageViewer: fetchFreshPresignedUrlFromServer not implemented; input: $currentUrlOrKey");
    return null;
  }
}
