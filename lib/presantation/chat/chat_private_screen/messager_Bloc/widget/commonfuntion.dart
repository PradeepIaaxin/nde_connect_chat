import 'package:nde_email/presantation/widgets/chat_widgets/Common/grouped_media_viewer.dart';

/// Helper function to extract sender name from message
String? _extractSenderName(Map<String, dynamic> msg, String? currentUserId) {
  // Extract sender ID first - check multiple possible fields
  String? senderId = msg['senderId']?.toString();

  if (senderId == null && msg['sender'] is Map) {
    final sender = msg['sender'] as Map;
    senderId = sender['_id']?.toString() ??
        sender['id']?.toString() ??
        sender['userId']?.toString();
  }

  // If sender is just a string (the ID itself)
  if (senderId == null && msg['sender'] is String) {
    senderId = msg['sender'] as String;
  }

  // Also check these top-level fields
  senderId ??= msg['sender_id']?.toString() ??
      msg['userId']?.toString() ??
      msg['user_id']?.toString();

  // If this message is from current user, return "You"
  if (currentUserId != null &&
      senderId != null &&
      senderId.trim() == currentUserId.trim()) {
    return 'You';
  }

  // Try senderName first
  if (msg['senderName'] != null && msg['senderName'].toString().isNotEmpty) {
    final name = msg['senderName'].toString();
    print('   ✅ Found senderName: $name');
    return name;
  }

  // Try userName
  if (msg['userName'] != null && msg['userName'].toString().isNotEmpty) {
    final name = msg['userName'].toString();
    print('   ✅ Found userName: $name');
    return name;
  }

  // Try sender object
  if (msg['sender'] is Map) {
    final sender = msg['sender'] as Map;
    final firstName = sender['first_name']?.toString() ?? '';
    final lastName = sender['last_name']?.toString() ?? '';
    final name = sender['name']?.toString() ?? '';

    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      final fullName = '$firstName $lastName'.trim();
    //  print('   ✅ Found from sender object: $fullName');
      return fullName;
    }
    if (name.isNotEmpty) {
      print('   ✅ Found sender.name: $name');
      return name;
    }
  }

  print('   ❌ No sender name found');
  return null;
}

List<GroupMediaItem> buildConversationMedia(
    List<Map<String, dynamic>> allMessages, {
      String? currentUserId,
      String? receiverName,
    }) {
  final List<GroupMediaItem> media = [];

  for (final msg in allMessages) {
    final String? originalUrl = msg['originalUrl']?.toString();
    final String? imageUrl = msg['imageUrl']?.toString();
    final String? thumbnailUrl = msg['thumbnailUrl']?.toString();
    final String? fileUrl = msg['fileUrl']?.toString();
    final String fileType =
    (msg['fileType'] ?? msg['mimeType'] ?? '').toString().toLowerCase();

    final String? senderName = _extractSenderName(msg, currentUserId);
    final String? senderId = msg['senderId']?.toString() ??
        (msg['sender'] is Map ? msg['sender']['_id']?.toString() : null);

    final String? time = msg['time']?.toString();

    final bool isVideo = fileType.startsWith('video/') ||
        (fileUrl?.endsWith('.mp4') ?? false) ||
        (fileUrl?.endsWith('.mov') ?? false) ||
        (fileUrl?.endsWith('.mkv') ?? false) ||
        (fileUrl?.endsWith('.webm') ?? false);

    if (isVideo && fileUrl != null && fileUrl.isNotEmpty) {
      media.add(
        GroupMediaItem(
          previewUrl: msg['localThumbPath'] ??
              thumbnailUrl ??
              originalUrl ??
              fileUrl,
          mediaUrl: fileUrl,
          isVideo: true,
          senderName: senderName ?? receiverName,
          senderId: senderId,
          time: time,
        ),
      );
    } else {
      final String? img = originalUrl ?? imageUrl;

      if (img != null && img.isNotEmpty) {
        media.add(
          GroupMediaItem(
            previewUrl: img,
            mediaUrl: img,
            isVideo: false,
            senderName: senderName ?? receiverName,
            senderId: senderId,
            time: time,
          ),
        );
      }
    }
  }

  return media;
}
