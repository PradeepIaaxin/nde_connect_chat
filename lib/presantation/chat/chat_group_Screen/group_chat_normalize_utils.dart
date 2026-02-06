import 'group_model.dart';

class GroupChatNormalizeUtils {
  static Map<String, dynamic> normalizeMessage(dynamic rawMsg) {
    if (rawMsg == null) return {};
    if (rawMsg is String) return {};
    if (rawMsg is! Map && rawMsg is! GroupMessageModel) return {};

    Map<String, dynamic> message = {};

    if (rawMsg is GroupMessageModel) {
      message = rawMsg.toJson();
    } else if (rawMsg is Map) {
      try {
        message = Map<String, dynamic>.from(rawMsg);
      } catch (e) {
        return {};
      }
    }

    final content = message['content']?.toString().trim() ?? '';
    final userName = message['userName'] ?? '';
    final isForwarded = message['isForwarded'] ?? false;
    final imageUrl = message['originalUrl'] ?? message['imageUrl'];
    final fileUrl = message['originalUrl'] ?? message['fileUrl'];
    final fileName = message['fileName'];
    final fileType = message['mimeType'] ?? message['fileType'];
    final messageId = message['message_id'] ?? message['id'];
    final contentType = message['ContentType'] ?? message['contentType'];

    final isReplyMessage = message['isReplyMessage'] ?? false;
    final reply = message['reply'] ?? message['repliedMessage'];

    final senderData = message['sender'] is Map ? message['sender'] : {};
    final String profilePic = senderData['profile_pic_path'] ??
        senderData['profilePic'] ??
        senderData['avatar'] ??
        '';

    final normalizedReply = (reply != null && reply is Map<String, dynamic>)
        ? (() {
            final String mediaUrl = reply["originalUrl"]?.toString() ??
                reply["imageUrl"]?.toString() ??
                reply["fileUrl"]?.toString() ??
                "";
            final String fileName = reply["fileName"]?.toString() ?? "";

            String ext = "";
            if (mediaUrl.isNotEmpty) {
              final uri = Uri.tryParse(mediaUrl);
              ext = uri?.path.split('.').last.toLowerCase() ?? "";
            } else if (fileName.isNotEmpty) {
              ext = fileName.split('.').last.toLowerCase();
            }

            String mimeType = reply["mimeType"]?.toString() ??
                reply["fileType"]?.toString() ??
                "";
            String contentType = reply["ContentType"]?.toString() ??
                reply["contentType"]?.toString() ??
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
              } else if ([
                "pdf",
                "doc",
                "docx",
                "xls",
                "xlsx",
                "ppt",
                "pptx",
                "txt"
              ].contains(ext)) {
                mimeType = "application/$ext";
                contentType = "document";
              } else if (mediaUrl.isNotEmpty) {
                mimeType = "application/octet-stream";
                contentType = "file";
              }
            }

            return {
              "userId": reply["userId"] ?? reply["senderId"],
              "id": reply["id"] ?? reply["message_id"] ?? reply["messageId"],
              "mimeType": mimeType,
              "fileType": mimeType,
              "ContentType": contentType,
              "contentType": contentType,
              "replyContent": reply["content"] ?? reply["replyContent"] ?? "",
              "replyToUser": reply["senderName"] ??
                  reply["userName"] ??
                  reply["replyToUser"] ??
                  reply["replyToUSer"] ??
                  "",
              "fileName": reply["fileName"] ?? "",
              "first_name": reply["first_name"] ?? "",
              "last_name": reply["last_name"] ?? "",
              "imageUrl": reply["imageUrl"] ?? reply["thumbnailUrl"] ?? "",
              "fileUrl": reply["fileUrl"] ?? "",
              "originalUrl": reply["originalUrl"] ?? "",
              "duration": reply["duration"] ?? reply["videoDuration"],
              "videoDuration": reply["videoDuration"] ?? reply["duration"],
              'profile_pic_path': message['sender']?['profile_pic_path'] ??
                  message['sender']?['profilePic'] ??
                  message['profile_pic_path'] ??
                  '',
              "imageCount": reply["imageCount"] ?? 0,
              "videoCount": reply["videoCount"] ?? 0,
            };
          })()
        : null;

    final rawReactions = message['reactions'] as List? ?? [];
    final List<Map<String, dynamic>> normalizedReactions = [];

    for (var r in rawReactions) {
      if (r is! Map) continue;
      final reactionMap = Map<String, dynamic>.from(r);

      var userObj = reactionMap['user'];
      String? userId = reactionMap['userId']?.toString();

      if (userObj is String) {
        if (userId == null || userId.isEmpty) userId = userObj;
        userObj = {'_id': userId};
      } else if (userObj is Map) {
        if (userId == null || userId.isEmpty) {
          userId = userObj['_id']?.toString() ??
              userObj['id']?.toString() ??
              userObj['userId']?.toString();
        }
      }

      reactionMap['userId'] = userId;
      reactionMap['user'] = userObj;

      normalizedReactions.add(reactionMap);
    }

    final messageStatus = (message['messageStatus'] ??
            message['status'] ??
            message['deliveryStatus'] ??
            'sent')
        .toString();

    final bool isDeleted =
        message['is_deleted'] == true || message['isDeleted'] == true;

    final conversationId = message['conversationId'] ??
        message['convoId'] ??
        message['conversation_id'];

    return {
      'conversationId': conversationId,
      'message_id': messageId,
      'messageId': messageId,
      'content': isDeleted ? '🚫 This message was deleted' : content,
      'userName': userName,
      'sender': message['sender'],
      'receiver': message['receiver'],
      'messageStatus': isDeleted
          ? 'deleted'
          : (messageStatus.isEmpty ? 'sent' : messageStatus),
      'time': message['time'],
      'imageUrl': isDeleted ? null : imageUrl,
      'fileName': isDeleted ? null : fileName,
      'ContentType': contentType,
      'contentType': contentType,
      'fileUrl': isDeleted ? null : fileUrl,
      'fileType': isDeleted ? null : fileType,
      'isForwarded': isForwarded,
      'isReplyMessage': isReplyMessage,
      'repliedMessage': normalizedReply,
      'reactions': normalizedReactions,
      'profile_pic_path': profilePic,
      'isDeleted': isDeleted,
      'is_deleted': isDeleted,
      'duration': message['duration']?.toString() ??
          message['videoDuration']?.toString(),
      'is_grouped_message':
          message['is_grouped_message'] ?? message['isGroupedMessage'],
      'group_message_id':
          message['group_message_id'] ?? message['groupMessageId'],
    };
  }
}
