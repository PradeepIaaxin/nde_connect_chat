import 'dart:convert';
import 'package:nde_email/presantation/chat/chat_group_Screen/group_chat_text_utils.dart';

class GroupReplyData {
  /// 🔥 NEW: Extract and normalize reply data from incoming message
  static Map<String, dynamic>? extractReplyDataFromIncoming(
      Map<String, dynamic> replyRaw) {
    try {
      final String mediaUrl = replyRaw["originalUrl"]?.toString() ??
          replyRaw["imageUrl"]?.toString() ??
          replyRaw["fileUrl"]?.toString() ??
          "";
      final String fileName = replyRaw["fileName"]?.toString() ?? "";

      // Get extension
      String ext = "";
      if (mediaUrl.isNotEmpty) {
        final uri = Uri.tryParse(mediaUrl);
        ext = uri?.path.split('.').last.toLowerCase() ?? "";
      } else if (fileName.isNotEmpty) {
        ext = fileName.split('.').last.toLowerCase();
      }

      // Guess type by extension if not provided
      String mimeType = replyRaw["mimeType"]?.toString() ??
          replyRaw["fileType"]?.toString() ??
          "";
      String contentType = replyRaw["ContentType"]?.toString() ??
          replyRaw["contentType"]?.toString() ??
          "";

      if (mimeType.isEmpty || contentType.isEmpty) {
        if (["jpg", "jpeg", "png", "gif", "webp"].contains(ext)) {
          mimeType = "image/$ext";
          contentType = "image";
        } else if (["mp4", "mov", "mkv", "avi", "webm"].contains(ext)) {
          mimeType = "video/$ext";
          contentType = "video";
        } else if (["mp3", "wav", "aac", "m4a", "flac", "ogg", "opus"]
            .contains(ext)) {
          mimeType = "audio/$ext";
          contentType = "audio";
        } else if (["pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "txt"]
            .contains(ext)) {
          mimeType = "application/$ext";
          contentType = "document";
        } else if (mediaUrl.isNotEmpty) {
          mimeType = "application/octet-stream";
          contentType = "file";
        }
      }

      return {
        "userId": replyRaw["userId"] ?? replyRaw["senderId"],
        "id": replyRaw["id"] ?? replyRaw["message_id"] ?? replyRaw["messageId"],
        "mimeType": mimeType,
        "fileType": mimeType,
        "ContentType": contentType,
        "contentType": contentType,
        "replyContent": replyRaw["content"] ?? replyRaw["replyContent"] ?? "",
        "replyToUser": replyRaw["senderName"] ??
            replyRaw["userName"] ??
            replyRaw["replyToUser"] ??
            replyRaw["replyToUSer"] ??
            "",
        "fileName": replyRaw["fileName"] ?? "",
        "first_name": replyRaw["first_name"] ?? "",
        "last_name": replyRaw["last_name"] ?? "",
        "imageUrl": replyRaw["imageUrl"] ?? replyRaw["thumbnailUrl"] ?? "",
        "fileUrl": replyRaw["fileUrl"] ?? "",
        "originalUrl": replyRaw["originalUrl"] ?? "",
        "duration": replyRaw["duration"] ?? replyRaw["videoDuration"],
        "videoDuration": replyRaw["videoDuration"] ?? replyRaw["duration"],
        'profile_pic_path':
            replyRaw['profile_pic_path'] ?? replyRaw['profilePic'] ?? '',
        // 🔥 NEW: Persist grouped reply metadata
        'imageCount': replyRaw['imageCount'] ?? 0,
        'videoCount': replyRaw['videoCount'] ?? 0,
        'group_message_id': replyRaw['group_message_id'],
        'isGroupedReply': replyRaw['isGroupedReply'] ?? false,
        'groupMessageIds': replyRaw['groupMessageIds'] ?? [],
      };
    } catch (e) {
      return null;
    }
  }

  /// Ensure reply payloads are a stable, sanitized Map for UI & sending.
  static Map<String, dynamic> mergeReplyData(
      dynamic replyData, List<Map<String, dynamic>> allMessages) {
    if (replyData == null) return <String, dynamic>{};

    final Map<String, dynamic> merged = {};

    // Accept Map or JSON string
    if (replyData is String) {
      try {
        final decoded = jsonDecode(replyData);
        if (decoded is Map) {
          merged.addAll(Map<String, dynamic>.from(decoded));
        } else {
          merged['replyContent'] = replyData;
        }
      } catch (_) {
        merged['replyContent'] = replyData;
      }
    } else if (replyData is Map) {
      merged.addAll(Map<String, dynamic>.from(replyData));
    } else {
      return <String, dynamic>{};
    }

    // ID normalization
    merged['id'] = merged['id'] ??
        merged['message_id'] ??
        merged['messageId'] ??
        merged['_id'] ??
        '';

    // Content / reply text
    merged['replyContent'] =
        merged['replyContent'] ?? merged['content'] ?? merged['message'] ?? '';

    // Ensure fileType/mimeType parity
    if ((merged['fileType'] == null || merged['fileType'].toString().isEmpty) &&
        merged['mimeType'] != null) {
      merged['fileType'] = merged['mimeType'];
    }
    if ((merged['mimeType'] == null || merged['mimeType'].toString().isEmpty) &&
        merged['fileType'] != null) {
      merged['mimeType'] = merged['fileType'];
    }

    // Grouped metadata compatibility
    merged['group_message_id'] = merged['group_message_id'] ??
        merged['groupMessageId'] ??
        merged['groupId'];
    merged['groupMessageIds'] = merged['groupMessageIds'] ??
        (merged['groupMessageId'] != null ? [merged['groupMessageId']] : []);
    merged['is_grouped_message'] = merged['is_grouped_message'] ??
        merged['isGroupedMessage'] ??
        merged['isGroupedReply'] ??
        ((merged['imageCount'] ?? 0) as num) > 0 ||
            ((merged['videoCount'] ?? 0) as num) > 0;

    // Coerce counts to int
    merged['imageCount'] =
        int.tryParse(merged['imageCount']?.toString() ?? '') ??
            (merged['imageCount'] is int ? merged['imageCount'] : 0);
    merged['videoCount'] =
        int.tryParse(merged['videoCount']?.toString() ?? '') ??
            (merged['videoCount'] is int ? merged['videoCount'] : 0);

    // Ensure canonical URLs/filenames
    merged['originalUrl'] =
        merged['originalUrl'] ?? merged['fileUrl'] ?? merged['imageUrl'] ?? '';

    // 🔥 FALLBACK LOOKUP: If URL is still empty, try to find the original message in _allMessages
    if ((merged['originalUrl'] as String).isEmpty) {
      final replyId = merged['id'];
      if (replyId != null && replyId.toString().isNotEmpty) {
        final originalMsg = allMessages.firstWhere(
          (m) =>
              (m['message_id'] ?? m['messageId'] ?? m['id'] ?? m['_id'])
                  ?.toString() ==
              replyId.toString(),
          orElse: () => <String, dynamic>{},
        );
        if (originalMsg.isNotEmpty) {
          merged['originalUrl'] = originalMsg['originalUrl'] ??
              originalMsg['fileUrl'] ??
              originalMsg['imageUrl'] ??
              '';

          // Also populate other missing fields
          if (merged['fileName'] == null ||
              merged['fileName'].toString().isEmpty) {
            merged['fileName'] = originalMsg['fileName'];
          }
          if (merged['mimeType'] == null ||
              merged['mimeType'].toString().isEmpty) {
            merged['mimeType'] =
                originalMsg['mimeType'] ?? originalMsg['fileType'];
          }
          if (merged['ContentType'] == null ||
              merged['ContentType'].toString().isEmpty) {
            merged['ContentType'] =
                originalMsg['ContentType'] ?? originalMsg['contentType'];
          }
        }
      }
    }

    merged['imageUrl'] = merged['imageUrl'] ??
        merged['thumbnailUrl'] ??
        merged['originalUrl'] ??
        '';
    merged['fileUrl'] = merged['fileUrl'] ?? merged['originalUrl'] ?? '';

    // sanitize string fields to avoid UTF-16 errors in TextSpan/TextPainter
    final keys = merged.keys.toList();
    for (final k in keys) {
      final v = merged[k];
      if (v is String) merged[k] = sanitizeString(v);
    }

    return merged;
  }

  static Map<String, dynamic> buildReplyPreview({
    required Map<String, dynamic> message,
    required List<Map<String, dynamic>> allMessages,
    required String currentUserId,
    bool isSendMe = false,
  }) {
    // ✅ ALWAYS reply to the swiped message itself
    final Map<String, dynamic> replySource = Map<String, dynamic>.from(message);

    final String? originalUrl = replySource['originalUrl'] ??
        replySource['imageUrl'] ??
        replySource['fileUrl'];

    final String fileType =
        replySource['mimeType'] ?? replySource['fileType'] ?? '';

    final bool isVideo = fileType.toLowerCase().startsWith('video/');

    // Calculate counts if it's a grouped message
    int imageCount = 0;
    int videoCount = 0;
    final String? groupId = (replySource['group_message_id'] != null &&
            !replySource['group_message_id']
                .toString()
                .startsWith('generated_group_'))
        ? replySource['group_message_id'].toString()
        : null;

    if (groupId != null && groupId.isNotEmpty) {
      // Find all messages in this group
      final groupMessages = allMessages
          .where((m) =>
              m['group_message_id']?.toString() == groupId &&
              m['is_deleted'] != true)
          .toList();

      for (var m in groupMessages) {
        final String fType = (m['mimeType'] ??
                m['fileType'] ??
                m['mimetype'] ??
                m['ContentType'] ??
                '')
            .toString()
            .toLowerCase();
        final String mUrl =
            (m['originalUrl'] ?? m['imageUrl'] ?? m['fileUrl'] ?? '')
                .toString()
                .toLowerCase();

        if (fType.startsWith('video/') ||
            mUrl.endsWith('.mp4') ||
            mUrl.endsWith('.mov') ||
            mUrl.endsWith('.mkv')) {
          videoCount++;
        } else if (fType.startsWith('image/') ||
            mUrl.endsWith('.jpg') ||
            mUrl.endsWith('.png') ||
            mUrl.endsWith('.jpeg') ||
            mUrl.endsWith('.webp')) {
          imageCount++;
        }
      }
    }

    // Build content preview text based on media counts
    String contentPreview = (replySource['content'] ?? '').toString();
    if (imageCount > 0 || videoCount > 0) {
      if (imageCount > 0 && videoCount > 0) {
        contentPreview = 'Media × ${imageCount + videoCount}';
      } else if (imageCount > 0) {
        contentPreview = 'Photo × $imageCount';
      } else if (videoCount > 0) {
        contentPreview = 'Video × $videoCount';
      }
    }

    // SANITIZE reply preview content to avoid UTF-16 issues in rendering
    contentPreview = sanitizeString(contentPreview);

    return {
      'message_id': replySource['message_id'] ??
          replySource['messageId'] ??
          replySource['id'],

      'content': contentPreview,

      // ✅ media (LOCAL or NETWORK)
      'originalUrl': originalUrl ?? '',
      'imageUrl': replySource['imageUrl'] ?? originalUrl ?? '',
      'fileUrl': replySource['fileUrl'] ?? originalUrl ?? '',
      'fileName': replySource['fileName'] ?? '',
      'fileType': fileType,
      'isVideo': isVideo,
      'isDocument': !isVideo &&
          (replySource['fileUrl'] != null &&
              replySource['fileUrl'].isNotEmpty &&
              (replySource['imageUrl'] == null ||
                  replySource['imageUrl'].isEmpty)),

      // user
      'sender': replySource['sender'],
      'receiver': replySource['receiver'],
      'senderId': currentUserId,
      'isSendMe': isSendMe,
      'imageCount': imageCount,
      'videoCount': videoCount,
      'group_message_id': groupId,
    };
  }
}
