import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nde_email/utils/snackbar/snackbar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'AudioMessageWidget.dart';
import 'ImageMessageWidget.dart';
import 'VideoMessageWidget.dart';

Widget buildMessageContent(
    dynamic message, BuildContext context, String currentUserId) {
  try {
    // Use both ContentType and contentType for backward compatibility
    final contentType = (message?.ContentType ?? message?.contentType ?? 'text')
        .toLowerCase()
        .trim();
    final content = message?.content ?? '';
    final fileUrl = message?.originalUrl ?? '';
    final fileName = message?.fileName ?? '';
    final messageTime = message?.time;
    final thumbnailUrl = message?.thumbnailUrl ?? '';
    final mimeType = message?.mimeType ?? '';

    log("Building message content - Type: $contentType, MIME: $mimeType, Content: $content");

    // Handle text messages
    if (contentType == 'text' || (content.isNotEmpty && fileUrl.isEmpty)) {
      return _buildTextMessage(content);
    }

    // Handle file attachments
    if (fileUrl.isNotEmpty) {
      // Determine type from both contentType and mimeType
      final type = _determineContentType(contentType, mimeType, fileName);

      switch (type) {
        case 'image':
          return _buildImageMessage(fileUrl, messageTime, thumbnailUrl);
        case 'video':
          return _buildVideoMessage(fileUrl, messageTime, thumbnailUrl);
        case 'audio':
          return _buildAudioMessage(fileUrl, message?.sender, currentUserId);
        case 'document':
          return _buildDocumentMessage(fileUrl, fileName, context);
        default:
          return _buildFileMessage(fileUrl, fileName, type, context);
      }
    }

    return _buildErrorWidget("Empty message content");
  } catch (e, stackTrace) {
    log("Error building message content: $e\n$stackTrace");
    return _buildErrorWidget("Error displaying content");
  }
}

String _determineContentType(
    String contentType, String mimeType, String fileName) {
  // First check the explicit content type
  if (contentType.contains('image')) return 'image';
  if (contentType.contains('video')) return 'video';
  if (contentType.contains('audio')) return 'audio';
  if (contentType.contains('doc') || contentType.contains('pdf')) {
    return 'document';
  }

  if (mimeType.contains('image')) return 'image';
  if (mimeType.contains('video')) return 'video';
  if (mimeType.contains('audio')) return 'audio';
  if (mimeType.contains('pdf') ||
      mimeType.contains('doc') ||
      mimeType.contains('sheet')) {
    return 'document';
  }

  final ext = fileName.split('.').last.toLowerCase();
  if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) return 'image';
  if (['mp4', 'mov', 'avi', 'mkv'].contains(ext)) return 'video';
  if (['mp3', 'wav', 'aac', 'ogg'].contains(ext)) return 'audio';
  if (['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt']
      .contains(ext)) {
    return 'document';
  }

  return 'file';
}

Widget _buildTextMessage(String content) {
  return SelectableText(
    content,
    style: const TextStyle(fontSize: 16),
  );
}

Widget _buildImageMessage(
    String fileUrl, DateTime? messageTime, String thumbnailUrl) {
  if (fileUrl.isEmpty || !_isValidUrl(fileUrl)) {
    return _buildErrorWidget("Invalid image URL");
  }
  return ImageMessageWidget(
    fileUrl: fileUrl,
    lastSendTime: _formatDateTime(messageTime),
    //thumbnailUrl: thumbnailUrl,
  );
}

Widget _buildVideoMessage(
    String fileUrl, DateTime? messageTime, String thumbnailUrl) {
  if (fileUrl.isEmpty || !_isValidUrl(fileUrl)) {
    return _buildErrorWidget("Invalid video URL");
  }
  return VideoMessageWidget(
    videoUrl: fileUrl,
    thumbnailUrl: thumbnailUrl,
    lastSendTime: _formatDateTime(messageTime),
  );
}

Widget _buildAudioMessage(
    String fileUrl, dynamic sender, String currentUserId) {
  if (fileUrl.isEmpty || !_isValidUrl(fileUrl)) {
    return _buildErrorWidget("Invalid audio URL");
  }
  return AudioMessageWidget(
    audioUrl: fileUrl,
    profileAvatarUrl: sender?.profilePicPath ?? '',
    isSender: sender?.id == currentUserId,
  );
}

Widget _buildDocumentMessage(
    String fileUrl, String fileName, BuildContext context) {
  return _buildFileMessage(fileUrl, fileName, 'document', context);
}

Widget _buildFileMessage(
    String fileUrl, String fileName, String type, BuildContext context) {
  if (fileUrl.isEmpty || !_isValidUrl(fileUrl)) {
    return _buildErrorWidget("Invalid file URL");
  }

  final icon = _getFileIcon(type, fileName);
  final displayName =
      fileName.isNotEmpty ? fileName : '${type.capitalize()} file';

  return InkWell(
    onTap: () => _launchUrl(fileUrl, context),
    borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 40, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap to open',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.open_in_new, color: Colors.blue),
        ],
      ),
    ),
  );
}

IconData _getFileIcon(String type, String fileName) {
  switch (type) {
    case 'pdf':
      return Icons.picture_as_pdf;
    case 'document':
      final ext = fileName.split('.').last.toLowerCase();
      if (ext == 'pdf') return Icons.picture_as_pdf;
      if (['doc', 'docx'].contains(ext)) return Icons.description;
      if (['xls', 'xlsx'].contains(ext)) return Icons.table_chart;
      if (['ppt', 'pptx'].contains(ext)) return Icons.slideshow;
      return Icons.insert_drive_file;
    default:
      return Icons.insert_drive_file;
  }
}

Widget _buildErrorWidget(String message) {
  return Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.red[50],
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      message,
      style: const TextStyle(color: Colors.red, fontSize: 14),
    ),
  );
}

Future<void> _launchUrl(String url, BuildContext context) async {
  try {
    if (!await launchUrl(Uri.parse(url),
        mode: LaunchMode.externalApplication)) {
      Messenger.alert(msg: "Could not open the fileo");
    }
  } catch (e) {
    log("Error launching URL: $e");
    Messenger.alert(msg: "Error: ${e.toString()}");
  }
}

bool _isValidUrl(String url) {
  try {
    return Uri.parse(url).isAbsolute;
  } catch (_) {
    return false;
  }
}

String _formatDateTime(DateTime? dateTime) {
  if (dateTime == null) return '';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

  final timeFormat = DateFormat('h:mm a');

  if (messageDate == today) {
    return 'Today, ${timeFormat.format(dateTime)}';
  } else if (messageDate == yesterday) {
    return 'Yesterday, ${timeFormat.format(dateTime)}';
  } else {
    return DateFormat('MMM d, y • h:mm a').format(dateTime);
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
