import 'package:intl/intl.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_model.dart';

class MessageHandler {
  final String currentUserId;
  final String convoId;

  MessageHandler({required this.currentUserId, required this.convoId});

  Map<String, dynamic> normalizeMessage(dynamic rawMsg) {
    final Map<String, dynamic> message = rawMsg is Datum
        ? rawMsg.toJson()
        : rawMsg is Map
            ? Map<String, dynamic>.from(rawMsg)
            : {};

    if (message.isEmpty) return {};

    // 1️⃣ Basic message content
    final content = (message['content']?.toString().trim() ?? '');
    final isForwarded = message['isForwarded'] ?? false;

    // 2️⃣ Media handling
    final originalUrl = message['originalUrl'];
    final imageUrl = originalUrl ?? message['thumbnailUrl'];
    final fileUrl = originalUrl ?? message['fileUrl'];
    final fileName = message['fileName'];
    final fileType = message['mimeType'] ?? message['fileType'];

    final messageId =
        message['message_id'] ?? message['messageId'] ?? message['_id'];
    final isReplyMessage = message['isReplyMessage'] ?? false;

    // 3️⃣ Reply normalization
    Map<String, dynamic>? normalizedReply;
    String replyContent = '';
    String replyToUser = '';

    if (rawMsg is Datum && rawMsg.reply != null) {
      // Prefer strongly typed reply
      replyContent = rawMsg.reply?.replyContent ?? '';
      replyToUser = rawMsg.reply?.replyToUser ?? '';
      normalizedReply = rawMsg.reply!.toJson();
    } else if (message['reply'] is Map) {
      final replyMap = Map<String, dynamic>.from(message['reply']);
      replyContent = replyMap["content"] ?? replyMap["replyContent"] ?? '';
      replyToUser = replyMap["replyToUser"] ?? replyMap["replyToUSer"] ?? '';

      normalizedReply = {
        "userId": replyMap["userId"] ?? replyMap["senderId"] ?? '',
        "id": replyMap["id"] ?? replyMap["message_id"] ?? '',
        "mimeType": replyMap["mimeType"] ?? '',
        "ContentType": replyMap["ContentType"] ?? '',
        "replyContent": replyContent,
        "replyToUser": replyToUser,
        "fileName": replyMap["fileName"] ?? '',
        "first_name": replyMap["first_name"] ?? '',
        "last_name": replyMap["last_name"] ?? '',
      };

      // print("📩 replyContent (Map): $replyContent");
      // print("👤 replyToUser (Map): $replyToUser");
    } else {
      //print("ℹ No reply content found for message: $messageId");
    }

    // 4️⃣ Reactions normalization
    List<Map<String, dynamic>> normalizedReactions = [];
    if (message['reactions'] is List) {
      normalizedReactions = (message['reactions'] as List).map((reactionRaw) {
        final reaction =
            reactionRaw is Map ? Map<String, dynamic>.from(reactionRaw) : {};
        final user = reaction['user'] is Map
            ? Map<String, dynamic>.from(reaction['user'])
            : {};
        return {
          'emoji': reaction['emoji'] ?? '',
          'reacted_at': reaction['reacted_at'] ?? '',
          'user': {
            '_id': user['_id'] ?? '',
            'first_name': user['first_name'] ?? '',
            'last_name': user['last_name'] ?? '',
          }
        };
      }).toList();
    }

    // 5️⃣ Status and metadata
    final status = message['messageStatus'] ?? 'delivered';
    final time = message['time'] ?? DateTime.now().toIso8601String();
    final sender = message['sender'] ?? {'_id': currentUserId};
    final receiver = message['receiver'] ?? {'_id': ''};

    // 6️⃣ Return normalized structure
    return {
      'message_id': messageId?.toString() ?? '',
      'content': content,
      'sender': sender,
      'receiver': receiver,
      'messageStatus': status,
      'time': time,
      'imageUrl': imageUrl,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'isForwarded': isForwarded,
      'isReplyMessage': isReplyMessage,
      'is_group_message': message['is_group_message'] == true ||
          message['is_group_message'] == 'true' ||
          message['is_group_message'] == 1,
      'group_message_id': message['group_message_id']?.toString(),
      'originalUrl': originalUrl,
      'thumbnailUrl': message['thumbnailUrl'],
      'ContentType': message['ContentType'],
      if (normalizedReply != null) 'repliedMessage': normalizedReply,
      'reactions': normalizedReactions,
      'localImagePath': message['localImagePath'],
      "replyContent": replyContent,
      "replyToUser": replyToUser,
      'isSelected': false,
    };
  }

  bool isSameDay(DateTime? date1, DateTime? date2) {
    if (date1 == null || date2 == null) return false;
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  DateTime parseTime(dynamic time) {
    if (time == null) return DateTime.now();
    if (time is int) return DateTime.fromMillisecondsSinceEpoch(time);
    if (time is String) {
      try {
        return DateTime.parse(time);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  String generateMessageKey(Map<String, dynamic> msg) {
    final time = msg['time']?.toString() ?? '';
    final content = msg['content']?.toString() ?? '';
    final image = msg['imageUrl']?.toString() ?? '';
    final file = msg['fileUrl']?.toString() ?? '';
    return '${msg['message_id']}_${time}_$content\_$image\_$file';
  }

  // String formatMessageTime(DateTime dateTime) {
  //   final now = DateTime.now();
  //   final today = DateTime(now.year, now.month, now.day);
  //   final yesterday = today.subtract(const Duration(days: 1));
  //   final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

  //   if (messageDate == today) {
  //     return DateFormat('h:mm a').format(dateTime); // 2:30 PM
  //   } else if (messageDate == yesterday) {
  //     return 'Yesterday';
  //   } else if (dateTime.year == now.year) {
  //     return DateFormat('MMM d').format(dateTime); // Jun 15
  //   } else {
  //     return DateFormat('MMM d, y').format(dateTime); // Jun 15, 2023
  //   }
  // }

  bool isMessageFromMe(Map<String, dynamic> message) {
    final sender = message['sender'] is Map
        ? Map<String, dynamic>.from(message['sender'])
        : {};
    return sender['_id'] == currentUserId;
  }

  bool shouldShowStatus(Map<String, dynamic> message) {
    return isMessageFromMe(message) && (message['messageStatus'] != null);
  }

  String getMessageStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'sent':
        return '✓';
      case 'delivered':
        return '✓✓';
      case 'read':
        return '✓✓';
      default:
        return '';
    }
  }
}
