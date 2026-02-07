import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:nde_email/utils/snackbar/snackbar.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:photo_view/photo_view.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:nde_email/data/base_url.dart';
import 'package:nde_email/data/respiratory.dart';
import 'package:http/http.dart' as http;
import 'package:nde_email/utils/reusbale/mime.type.dart';

class AttachmentWidget extends StatefulWidget {
  final dynamic attachment;
  final String mailboxId;
  final String messageId;

  const AttachmentWidget({
    super.key,
    required this.attachment,
    required this.mailboxId,
    required this.messageId,
  });

  @override
  State<AttachmentWidget> createState() => _AttachmentWidgetState();
}

class _AttachmentWidgetState extends State<AttachmentWidget> {
  static const String _androidPackageName = "com.nowdigitaleasy.NDEconnect";
  static const String _androidMailMediaDir =
      "/storage/emulated/0/Android/media/$_androidPackageName/NowDigitalEasy/Mail/Media";

  bool _looksLikeJsonBytes(Uint8List bytes) {
    for (final b in bytes) {
      if (b == 0x20 || b == 0x0A || b == 0x0D || b == 0x09) continue;
      return b == 0x7B || b == 0x5B;
    }
    return false;
  }

  Uint8List? _tryBytesFromJson(dynamic decoded, {int depth = 0}) {
    if (depth > 5) return null;

    if (decoded is String) {
      return _tryDecodeBase64StringToBytes(decoded);
    }

    if (decoded is List) {
      try {
        return Uint8List.fromList(decoded.cast<int>());
      } catch (_) {
        for (final item in decoded) {
          final found = _tryBytesFromJson(item, depth: depth + 1);
          if (found != null) return found;
        }
        return null;
      }
    }

    if (decoded is Map) {
      final map = decoded.cast<String, dynamic>();

      for (final key in const ['content', 'data', 'file', 'buffer', 'bytes']) {
        if (!map.containsKey(key)) continue;
        final found = _tryBytesFromJson(map[key], depth: depth + 1);
        if (found != null) return found;
      }

      for (final entry in map.entries) {
        final found = _tryBytesFromJson(entry.value, depth: depth + 1);
        if (found != null) return found;
      }
    }

    return null;
  }

  bool _looksLikeBase64(String s) {
    final trimmed = s.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.startsWith('data:')) return true;

    final cleaned = trimmed.replaceAll(RegExp(r'\s+'), '');
    if (cleaned.length < 32) return false;
    if (cleaned.length % 4 != 0) return false;
    return RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(cleaned);
  }

  Uint8List? _tryDecodeBase64StringToBytes(String s) {
    var value = s.trim();
    if (value.isEmpty) return null;

    final commaIndex = value.indexOf('base64,');
    if (value.startsWith('data:') && commaIndex != -1) {
      value = value.substring(commaIndex + 'base64,'.length);
    }

    value = value.replaceAll(RegExp(r'\s+'), '');
    if (value.isEmpty) return null;

    try {
      return base64Decode(value);
    } catch (_) {
      return null;
    }
  }

  bool _startsWithBytes(Uint8List data, List<int> prefix) {
    if (data.length < prefix.length) return false;
    for (var i = 0; i < prefix.length; i++) {
      if (data[i] != prefix[i]) return false;
    }
    return true;
  }

  bool _looksLikePdf(Uint8List data) => _startsWithBytes(data, [0x25, 0x50, 0x44, 0x46]);
  bool _looksLikeJpeg(Uint8List data) => _startsWithBytes(data, [0xFF, 0xD8, 0xFF]);
  bool _looksLikePng(Uint8List data) =>
      _startsWithBytes(data, [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
  bool _looksLikeGif(Uint8List data) => _startsWithBytes(data, [0x47, 0x49, 0x46, 0x38]);
  bool _looksLikeWebp(Uint8List data) {
    if (data.length < 12) return false;
    return _startsWithBytes(data, [0x52, 0x49, 0x46, 0x46]) &&
        data[8] == 0x57 &&
        data[9] == 0x45 &&
        data[10] == 0x42 &&
        data[11] == 0x50;
  }

  bool _matchesExpectedSignature({
    required Uint8List data,
    required String fileName,
    required String contentType,
  }) {
    final ext = p.extension(fileName).toLowerCase();
    final ct = contentType.toLowerCase();

    if (ext == '.pdf' || ct.contains('application/pdf')) return _looksLikePdf(data);
    if (ext == '.jpg' || ext == '.jpeg' || ct.contains('image/jpeg')) return _looksLikeJpeg(data);
    if (ext == '.png' || ct.contains('image/png')) return _looksLikePng(data);
    if (ext == '.gif' || ct.contains('image/gif')) return _looksLikeGif(data);
    if (ext == '.webp' || ct.contains('image/webp')) return _looksLikeWebp(data);

    return true;
  }

  Uint8List _extractAttachmentBytes({
    required http.Response response,
    required String expectedFileName,
    required String fallbackContentType,
  }) {
    final headerContentType = (response.headers['content-type'] ?? '').toString();
    final expectedType = headerContentType.isNotEmpty ? headerContentType : fallbackContentType;
    final raw = Uint8List.fromList(response.bodyBytes);

    if (headerContentType.contains('application/json') || _looksLikeJsonBytes(raw)) {
      try {
        final decoded = jsonDecode(utf8.decode(raw));
        final extracted = _tryBytesFromJson(decoded);
        if (extracted != null &&
            extracted.isNotEmpty &&
            _matchesExpectedSignature(
              data: extracted,
              fileName: expectedFileName,
              contentType: expectedType,
            )) {
          return extracted;
        }
      } catch (_) {}
    }

    final asText = utf8.decode(raw, allowMalformed: true).trim();
    if (_looksLikeBase64(asText)) {
      final extracted = _tryDecodeBase64StringToBytes(asText);
      if (extracted != null &&
          extracted.isNotEmpty &&
          _matchesExpectedSignature(
            data: extracted,
            fileName: expectedFileName,
            contentType: expectedType,
          )) {
        return extracted;
      }
    }

    return raw;
  }

  Future<bool> _ensureStoragePermission() async {
    if (!Platform.isAndroid) return true;

    final storageStatus = await Permission.storage.request();
    if (storageStatus.isGranted) return true;

    final manageStatus = await Permission.manageExternalStorage.request();
    return manageStatus.isGranted;
  }

  Future<Directory> _ensureDownloadDirectory() async {
    if (Platform.isAndroid) {
      final directory = Directory(_androidMailMediaDir);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      return directory;
    }

    final directory = await getApplicationDocumentsDirectory();
    return directory;
  }

  String _sanitizeFileName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '';

    return trimmed
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'[\u0000-\u001F]'), '_');
  }

  String _extensionFromContentType(String contentType) {
    final ct = contentType.toLowerCase().trim();
    if (ct.isEmpty) return '';

    if (ct.contains('application/octet-stream')) return '';
    if (ct.contains('application/json')) return '';

    if (ct.contains('image/jpeg') || ct.contains('image/jpg')) return '.jpg';
    if (ct.contains('image/png')) return '.png';
    if (ct.contains('image/gif')) return '.gif';
    if (ct.contains('image/webp')) return '.webp';
    if (ct.contains('image/bmp')) return '.bmp';
    if (ct.contains('application/pdf')) return '.pdf';
    if (ct.contains('text/plain')) return '.txt';
    if (ct.contains('application/zip')) return '.zip';
    if (ct.contains('video/mp4')) return '.mp4';
    if (ct.contains('audio/mpeg')) return '.mp3';

    final parts = ct.split(';').first.split('/');
    if (parts.length == 2 && parts[1].isNotEmpty) {
      final ext = parts[1].trim();
      if (ext == 'jpeg') return '.jpg';
      return '.$ext';
    }
    return '';
  }

  bool _isImageType({
    required String fileName,
    required String contentType,
  }) {
    final ext = p.extension(fileName).replaceFirst('.', '').toLowerCase();
    if (["jpg", "jpeg", "png", "gif", "bmp", "webp"].contains(ext)) {
      return true;
    }

    return contentType.toLowerCase().trim().startsWith('image/');
  }

  String _buildSavedFileName() {
    final dynamic attachment = widget.attachment;

    final String rawName = (attachment?.filename ?? '').toString();
    final String contentType = (attachment?.contentType ?? '').toString();
    final String attachmentId = (attachment?.id ?? '').toString();

    final String sanitized = _sanitizeFileName(rawName);

    String baseName;
    if (sanitized.isNotEmpty) {
      baseName = sanitized;
    } else if (attachmentId.isNotEmpty) {
      baseName = 'attachment_$attachmentId';
    } else {
      baseName = 'attachment_${DateTime.now().millisecondsSinceEpoch}';
    }

    String ext = p.extension(baseName);
    if (ext.isEmpty) {
      final inferredExt = _extensionFromContentType(contentType);
      if (inferredExt.isNotEmpty) {
        baseName = '$baseName$inferredExt';
      }
    }

    if (attachmentId.isNotEmpty && !baseName.startsWith('${attachmentId}_')) {
      baseName = '${attachmentId}_$baseName';
    }

    return baseName;
  }

  String _buildDisplayFileName() {
    final dynamic attachment = widget.attachment;
    final String rawName = (attachment?.filename ?? '').toString().trim();
    if (rawName.isNotEmpty) return rawName;

    final String attachmentId = (attachment?.id ?? '').toString().trim();
    if (attachmentId.isNotEmpty) return 'attachment_$attachmentId';

    return 'attachment';
  }

  Future<void> _openOrDownloadAttachment({required bool forceRedownload}) async {
    try {
      final accessToken = await UserPreferences.getAccessToken();
      final workspaceId = await UserPreferences.getDefaultWorkspace();

      if (accessToken == null || workspaceId == null) {
        throw Exception("Access token or workspace ID not found");
      }

      final hasPermission = await _ensureStoragePermission();
      if (!hasPermission) {
        Messenger.alertError('Storage permission denied');
        return;
      }

      final directory = await _ensureDownloadDirectory();
      final savedFileName = _buildSavedFileName();
      final filePath = p.join(directory.path, savedFileName);
      var actualFilePath = filePath;
      var file = File(actualFilePath);

      final dynamic attachment = widget.attachment;
      final String contentType = (attachment?.contentType ?? '').toString();
      var isImage = _isImageType(fileName: savedFileName, contentType: contentType);

      final exists = await file.exists();
      final length = exists ? await file.length() : 0;

      if (exists && length > 0 && !forceRedownload) {
        if (isImage) {
          _showImagePreview(file);
        } else {
          await OpenFile.open(actualFilePath);
        }
        return;
      }

      if (exists && length > 0 && forceRedownload) {
        bool? redownload = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("File Already Exists"),
            content: Text(
                "Do you want to re-download or open '${_buildDisplayFileName()}'?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Open"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Re-Download"),
              ),
            ],
          ),
        );

        if (redownload == false) {
          if (isImage) {
            _showImagePreview(file);
          } else {
            await OpenFile.open(actualFilePath);
          }
          return;
        }
      }

      final downloadUrl =
          "${ApiService.baseUrl}/user/attachment/${widget.attachment.id}/mailboxes/${widget.mailboxId}/messages/${widget.messageId}";

      final response = await http.get(
        Uri.parse(downloadUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'X-WorkSpace': workspaceId,
          'Accept': 'application/octet-stream',
        },
      );

      if (response.statusCode == 200) {
        final responseContentType = (response.headers['content-type'] ?? '').toString();
        final bytes = _extractAttachmentBytes(
          response: response,
          expectedFileName: savedFileName,
          fallbackContentType: contentType,
        );

        final effectiveType =
            responseContentType.isNotEmpty ? responseContentType : contentType;
        if (!_matchesExpectedSignature(
          data: bytes,
          fileName: savedFileName,
          contentType: effectiveType,
        )) {
          Messenger.alertError('Invalid file data received');
          return;
        }

        await file.writeAsBytes(bytes, flush: true);

        if (p.extension(actualFilePath).isEmpty) {
          final inferredExt = _extensionFromContentType(responseContentType);
          if (inferredExt.isNotEmpty) {
            final renamedPath = '$actualFilePath$inferredExt';
            try {
              file = await file.rename(renamedPath);
              actualFilePath = renamedPath;
            } catch (_) {}
          }
        }

        isImage = _isImageType(
          fileName: p.basename(actualFilePath),
          contentType: responseContentType.isNotEmpty ? responseContentType : contentType,
        );

        try {
          await MediaScanner.loadMedia(path: actualFilePath);
        } catch (_) {}

        Messenger.alertSuccess('Saved to: $actualFilePath');

        if (isImage) {
          _showImagePreview(file);
        } else {
          await OpenFile.open(actualFilePath);
        }
      } else {
        Messenger.alert(msg: 'Failed to download: ${response.statusCode}');
      }
    } catch (e) {
      Messenger.alert(msg: 'Error : ${e.toString()}');
    }

    //   if (response.statusCode == 200) {
    //     await file.writeAsBytes(response.bodyBytes);
    //     Messenger.alertSuccess('Downloaded to: $filePath');

    //     if (isImage) {
    //       _showImagePreview(file);
    //     } else {
    //       await OpenFile.open(filePath);
    //     }
    //   } else {
    //     Messenger.alert(msg: 'Failed to download: ${response.statusCode}');
    //   }
    // } catch (e) {
    //   Messenger.alert(msg: 'Error : ${e.toString()}');
    // }
  }

  void _showImagePreview(File file) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.75,
          child: PhotoView(
            imageProvider: FileImage(file),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fileName = _buildDisplayFileName();
    final fileExtension =
        fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';

    return Container(
      width: 180,
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Row(
        children: [
          buildIcon(type: '', mimeType: fileExtension, size: 40),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => _openOrDownloadAttachment(forceRedownload: false),
              child: Text(
                fileName,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _openOrDownloadAttachment(forceRedownload: true),
            child: const Icon(Icons.download, color: Colors.blue),
          ),
        ],
      ),
    );
  }
}
