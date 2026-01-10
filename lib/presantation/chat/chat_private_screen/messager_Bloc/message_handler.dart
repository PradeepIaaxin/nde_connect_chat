import 'package:intl/intl.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_model.dart';

class MessageHandler {
  final String currentUserId;
  final String convoId;

  MessageHandler({
    required this.currentUserId,
    required this.convoId,
  });

  /// 🔹 MAIN NORMALIZER (CRDT + SOCKET SAFE)
  Map<String, dynamic> normalizeMessage(dynamic rawMsg) {
    final Map<String, dynamic> message = rawMsg is Datum
        ? rawMsg.toJson()
        : rawMsg is Map
            ? Map<String, dynamic>.from(rawMsg)
            : {};

    if (message.isEmpty) return {};

    /// 🔹 IDS (CANONICAL)
    final messageId =
        message['message_id'] ?? message['messageId'] ?? message['_id'];

    /// 🔹 FORWARDED (STRICT — WEB LOGIC)
    /// ❌ Never trust `isForwarded` boolean
    final bool isForwarded = message['isForwarded'] == true ||
        message['original_message_id'] != null ||
        message['parent_message_id'] != null ||
        message['originalMessageId'] != null ||
        message['parentMessageId'] != null ||
        message['forwardedFrom'] != null ||
        message['forwardFingerprint'] != null;

    /// 🔹 BASIC CONTENT
    final content = message['content']?.toString().trim() ?? '';

    /// 🔹 MEDIA
    final originalUrl = message['originalUrl'];
    final imageUrl = originalUrl ?? message['thumbnailUrl'];
    final fileUrl = originalUrl ?? message['fileUrl'];
    final fileName = message['fileName'];
    final fileType = message['mimeType'] ?? message['fileType'];

    /// 🔹 REPLY
    /// 🔹 REPLY
    final bool isReplyMessage = message['isReplyMessage'] == true;
    Map<String, dynamic>? normalizedReply;
    String replyContent = '';
    String replyToUser = '';

    if (isReplyMessage) {
      final reply = message['reply'] ??
          message['repliedMessage'] ??
          message['replyMessage'] ??
          {};

      if (reply is Map && reply.isNotEmpty) {
        replyContent = reply['replyContent'] ??
            reply['content'] ??
            reply['fileName'] ??
            '';

        replyToUser =
            '${reply['first_name'] ?? ''} ${reply['last_name'] ?? ''}'.trim();

        final replyId = reply['reply_message_id'] ??
            reply['message_id'] ??
            reply['id'] ??
            reply['messageId'];

        normalizedReply = {
          'reply_message_id': replyId?.toString(),
          'message_id': replyId?.toString(),
          'id': replyId?.toString(),
          'replyContent': replyContent,
          'replyToUser': replyToUser,
          'replyUrl': reply['replyUrl'],
          'fileName': reply['fileName'],
          'ContentType': reply['ContentType'] ?? 'text',
          'group_message_id': reply['group_message_id'],
          'is_grouped_message': reply['is_grouped_message'] ?? false,
        };
      }
    }

    /// 🔹 REACTIONS
    final reactions = (message['reactions'] is List)
        ? (message['reactions'] as List).whereType<Map>().map((reaction) {
            final user = reaction['user'] ?? {};
            return {
              'emoji': reaction['emoji'] ?? '',
              'reacted_at': reaction['reacted_at'],
              'user': {
                '_id': user['_id'] ?? '',
                'first_name': user['first_name'] ?? '',
                'last_name': user['last_name'] ?? '',
              },
            };
          }).toList()
        : <Map<String, dynamic>>[];

    /// 🔹 TIME + STATUS
    final time = message['time'] ?? DateTime.now().toIso8601String();
    final status = message['messageStatus'] ?? 'delivered';

    /// 🔹 SENDER / RECEIVER
    final sender = message['sender'] ?? {'_id': currentUserId};
    final receiver = message['receiver'] ?? {'_id': ''};

    /// 🔹 FINAL NORMALIZED MESSAGE (UI SAFE)
    return {
      'message_id': messageId?.toString() ?? '',
      'content': content,
      'sender': sender,
      'receiver': receiver,
      'messageStatus': status,
      'time': time,

      /// media
      'imageUrl': imageUrl,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileType': fileType,

      /// flags
      'isForwarded': isForwarded,
      'is_deleted': message['is_deleted'] == true,
      'isReplyMessage': isReplyMessage,
      'is_grouped_message': message['is_grouped_message'] == true ||
          message['is_grouped_message'] == 'true' ||
          message['is_grouped_message'] == 1,
      'group_message_id': message['group_message_id']?.toString(),

      /// reply (OLD UI COMPATIBLE)
      if (normalizedReply != null) 'reply': normalizedReply,
      'reply_message_id': normalizedReply?['reply_message_id'],
      'replyContent': replyContent,
      'replyToUser': replyToUser,
      'reactions': reactions,
      'localImagePath': message['localImagePath'],
      'isSelected': false,
    };
  }

  // ================= HELPERS =================

  bool isMessageFromMe(Map<String, dynamic> msg) {
    final sender =
        msg['sender'] is Map ? Map<String, dynamic>.from(msg['sender']) : {};
    return sender['_id'] == currentUserId;
  }

  bool shouldShowStatus(Map<String, dynamic> msg) {
    return isMessageFromMe(msg) && msg['messageStatus'] != null;
  }

  DateTime parseTime(dynamic time) {
    if (time is DateTime) return time;
    if (time is String) return DateTime.tryParse(time) ?? DateTime.now();
    if (time is int) return DateTime.fromMillisecondsSinceEpoch(time);
    return DateTime.now();
  }

  String generateMessageKey(Map<String, dynamic> msg) {
    return '${msg['message_id']}_${msg['time']}_${msg['content']}';
  }

  String formatTime(DateTime dateTime) {
    return DateFormat('hh:mm a').format(dateTime);
  }
}
