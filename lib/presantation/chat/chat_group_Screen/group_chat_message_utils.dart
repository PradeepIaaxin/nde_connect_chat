class GroupChatMessageUtils {
  static String normalizeMessageIdForApi(String messageId) {
    if (messageId.isEmpty) return messageId;

    if (messageId.startsWith('forward_')) {
      final parts = messageId.split('_');
      if (parts.length >= 3) {
        return parts[1];
      }
    }
    return messageId;
  }

  static String anyId(Map<String, dynamic> m) {
    final candidates = [
      m['message_id'],
      m['messageId'],
      m['id'],
      m['_id'],
      m['reply_message_id'],
      m['replyMessageId'],
      if (m['reply'] is Map) (m['reply'] as Map)['reply_message_id'],
      if (m['reply'] is Map) (m['reply'] as Map)['message_id'],
      if (m['reply'] is Map) (m['reply'] as Map)['id'],
      if (m['repliedMessage'] is Map)
        (m['repliedMessage'] as Map)['reply_message_id'],
      if (m['repliedMessage'] is Map)
        (m['repliedMessage'] as Map)['message_id'],
      if (m['repliedMessage'] is Map) (m['repliedMessage'] as Map)['id'],
    ];

    for (final c in candidates) {
      if (c != null && c.toString().isNotEmpty) {
        return c.toString();
      }
    }
    return '';
  }

  static List<String> extractGroupMembers(List<dynamic> messages) {
    final Set<String> memberIds = {};

    for (var msg in messages) {
      if (msg is Map && msg['properties'] != null) {
        final props = msg['properties'];
        if (props is Iterable) {
          for (var prop in props) {
            if (prop is Map &&
                prop['user'] is Map &&
                (prop['user'] as Map)['_id'] != null) {
              memberIds.add((prop['user'] as Map)['_id'].toString());
            }
          }
        }
      }
    }

    return memberIds.toList();
  }

  static bool isSameDay(DateTime? date1, DateTime? date2) {
    if (date1 == null || date2 == null) return false;
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  static String generateMessageKey(Map<String, dynamic> msg) {
    return '${msg['message_id'] ?? msg['time']}_${msg['content']}_${msg['imageUrl'] ?? ''}_${msg['fileUrl'] ?? ''}${msg['userName'] ?? ''}';
  }

  static bool isGroupableMedia(Map<String, dynamic> msg) {
    if (msg['isDeleted'] == true || msg['is_deleted'] == true) return false;

    final String contentType =
        (msg['ContentType'] ?? msg['contentType'] ?? '').toString().toLowerCase();
    final String fileType =
        (msg['fileType'] ?? msg['mimeType'] ?? '').toString().toLowerCase();
    final String fileUrl =
        (msg['fileUrl'] ?? msg['originalUrl'] ?? '').toString().toLowerCase();

    if (contentType == 'audio' || fileType.startsWith('audio/')) return false;

    final bool isRealImage =
        (msg['imageUrl'] != null && msg['imageUrl'].toString().isNotEmpty) &&
            (fileType.startsWith('image/') ||
                contentType == 'image' ||
                ['.jpg', '.jpeg', '.png', '.gif', '.webp']
                    .any((ext) => fileUrl.endsWith(ext)));

    final bool isLocalImage = (msg['localImagePath'] != null &&
        msg['localImagePath'].toString().isNotEmpty);

    final bool isRealVideo = fileType.startsWith('video/') ||
        contentType == 'video' ||
        ['.mp4', '.mov', '.mkv', '.avi', '.webm']
            .any((ext) => fileUrl.endsWith(ext));

    return isRealImage || isLocalImage || isRealVideo;
  }
}
