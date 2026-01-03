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
      print('   ✅ Found from sender object: $fullName');
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

  print('🎬 buildConversationMedia called with ${allMessages.length} messages');
  print('   currentUserId: $currentUserId');
  print('   receiverName: $receiverName');

  for (final msg in allMessages) {
    final String? originalUrl = msg['originalUrl']?.toString();
    final String? imageUrl = msg['imageUrl']?.toString();
    final String? thumbnailUrl = msg['thumbnailUrl']?.toString();
    final String? fileUrl = msg['fileUrl'];
    final String fileType = (msg['fileType'] ?? '').toLowerCase();

    // Extract sender name and ID
    String? senderName = _extractSenderName(msg, currentUserId);
    final String? senderId = msg['senderId']?.toString() ??
        (msg['sender'] is Map ? msg['sender']['_id']?.toString() : null);

    // ✅ FALLBACK: If no sender name found and it's not from current user, use receiverName
    if (senderName == null &&
        senderId != null &&
        senderId != currentUserId &&
        receiverName != null) {
      senderName = receiverName;
      print('   📝 Using receiverName as fallback: $receiverName');
    }

    final bool isVideo = fileType.startsWith('video/') ||
        (fileUrl?.endsWith('.mp4') ?? false) ||
        (fileUrl?.endsWith('.mov') ?? false);
    final String? time = msg['time']?.toString();

    if (isVideo && fileUrl != null && fileUrl.isNotEmpty) {
      print('   📹 Adding video with senderName: $senderName');
      media.add(
        GroupMediaItem(
          previewUrl: msg['localThumbPath'] ?? thumbnailUrl ?? fileUrl,
          mediaUrl: fileUrl,
          isVideo: true,
          senderName: senderName,
          senderId: senderId,
          time: time,
        ),
      );
    } else if (originalUrl != null && originalUrl.isNotEmpty) {
      print(
          '   📸 Adding image with originalUrl: $originalUrl, senderName: $senderName');
      media.add(
        GroupMediaItem(
          previewUrl: originalUrl,
          mediaUrl: originalUrl,
          isVideo: false,
          senderName: senderName,
          senderId: senderId,
          time: time,
        ),
      );
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      print(
          '   📸 Adding image with imageUrl: $imageUrl, senderName: $senderName');
      media.add(
        GroupMediaItem(
          previewUrl: imageUrl,
          mediaUrl: imageUrl,
          isVideo: false,
          senderName: senderName,
          senderId: senderId,
          time: time,
        ),
      );
    }
  }

  print('✅ Built ${media.length} media items');
  return media;
}

class RenderItem {
  final bool isGroup;
  final List<Map<String, dynamic>> messages;
  RenderItem.single(Map<String, dynamic> msg)
      : isGroup = false,
        messages = [msg];
  RenderItem.group(this.messages) : isGroup = true;
}
List<RenderItem> buildRenderItems(List<dynamic> messages) {
  final List<RenderItem> result = [];
  int i = 0;

  while (i < messages.length) {
    final msg = messages[i];
    final groupId = msg['group_message_id'];

    if (groupId != null && groupId.toString().isNotEmpty) {
      final group = <Map<String, dynamic>>[];

      while (i < messages.length &&
          messages[i]['group_message_id'] == groupId) {
        group.add(messages[i]);
        i++;
      }

      result.add(RenderItem.group(group));
    } else {
      result.add(RenderItem.single(msg));
      i++;
    }
  }

  return result;
}
