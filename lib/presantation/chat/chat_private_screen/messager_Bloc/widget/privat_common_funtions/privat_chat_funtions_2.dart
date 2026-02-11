
import 'dart:developer';

import '../../../../model/emoj_model.dart';

void updateMessageWithReaction({
 required MessageReaction reaction,
  required bool mounted,
  required String currentUserId,
  required  List<Map<String, dynamic>> Function(dynamic) extractReactions,
  required  List<Map<String, dynamic>> dbMessages,
  required  List<Map<String, dynamic>> messages,
  required  List<Map<String, dynamic>> socketMessages,
  required  void Function({bool isInitialLoad}) updateNotifier,
  required  void Function() scheduleSaveMessages,
  required   Future<void> Function() fetchMessages,
}) {
  if (!mounted) return;

  // 🔕 Ignore my own reaction echo on this device (sender already updated optimistically)
  if (reaction.user.id == currentUserId) {
    return;
  }

  String normalizeId(dynamic id) => id?.toString().trim() ?? '';

  final targetId = normalizeId(reaction.messageId);
  if (targetId.isEmpty) return;

  bool updated = false;

  void updateReactions(List<Map<String, dynamic>> list) {
    for (var msg in list) {
      final msgId = normalizeId(
        msg['message_id'] ?? msg['messageId'] ?? msg['_id'],
      );

      if (msgId != targetId) continue;

      // Normalize existing reactions
      final reactions = extractReactions(msg['reactions']);

      // remove old reaction from this user (if any)
      reactions.removeWhere((r) {
        final uid = (r['userId'] ?? r['user']?['_id'])?.toString();
        return uid == reaction.user.id;
      });

      // add new if not removal
      if (!reaction.isRemoval) {
        reactions.add({
          'emoji': reaction.emoji,
          'userId': reaction.user.id,
          'user': {
            '_id': reaction.user.id,
            'first_name': reaction.user.firstName,
            'last_name': reaction.user.lastName,
          },
          'reacted_at': reaction.reactedAt.toIso8601String(),
        });
      }

      msg['reactions'] = reactions;
      updated = true;
      break;
    }
  }

  updateReactions(dbMessages);
  updateReactions(messages);
  updateReactions(socketMessages);

  if (updated) {
    updateNotifier();
    scheduleSaveMessages();
  } else {
    // if message not found locally (older / pagination), try refetch
    fetchMessages();
  }
}
List<Map<String, dynamic>> extractReactions(dynamic raw) {
  final List<Map<String, dynamic>> out = [];

  if (raw is! List) return out;

  for (final e in raw) {
    if (e is! Map) continue;
    final m = Map<String, dynamic>.from(e);

    final emoji = m['emoji']?.toString();
    if (emoji == null || emoji.trim().isEmpty) continue;

    String? userId = m['userId']?.toString();
    final user = m['user'];

    // user is full object
    if ((userId == null || userId.isEmpty) && user is Map) {
      userId = (user['_id'] ?? user['id'] ?? user['userId'])?.toString();
    }

    // user is just string id
    if ((userId == null || userId.isEmpty) && user is String) {
      userId = user;
    }

    if (userId == null || userId.isEmpty) continue;

    out.add({
      'emoji': emoji,
      'userId': userId,
      'user': user is Map ? Map<String, dynamic>.from(user) : null,
      'reacted_at': (m['reacted_at'] ?? m['createdAt'] ?? '').toString(),
    });
  }

  return out;
}
bool _hasValidReply(dynamic rawReply, dynamic rawReplyId, dynamic rawReplyContent) {
  if (rawReply is Map && rawReply.isNotEmpty) return true;
  if (rawReplyId != null && rawReplyId.toString().trim().isNotEmpty) return true;
  if (rawReplyContent != null &&
      rawReplyContent.toString().trim().isNotEmpty) {
    return true;
  }
  return false;
}

Map<String, dynamic> normalizeMessage(dynamic rawMsg,{String? text}) {
  if (rawMsg == null) return {};
  log("rawMsgccccccccccccccccc:${text??""}....> $rawMsg");
  // Handle LORRO specific structure
  if (rawMsg is Map) {
    // Check if it's a LORRO-style message
    if (rawMsg.containsKey('v') && rawMsg.containsKey('ts')) {
      log('⚠️ Detected LORRO vector message format');
      // Extract actual message data from LORRO structure
      final content = rawMsg['v'] is Map ? rawMsg['v'] : rawMsg;
      return _normalizeStandardMessage(content);
    }
  }

  return _normalizeStandardMessage(rawMsg);
}

Map<String, dynamic> _normalizeStandardMessage(dynamic rawMsg) {
  if (rawMsg == null) return {};

  final m = <String, dynamic>{};
//log("rawMsgccccccccccccccccc: $rawMsg");
  // ================= EXTRACT ID =================
  String? canonicalId;
  for (final k in ['message_id', 'messageId', 'id', '_id', 'messageID']) {
    final v = rawMsg[k];
    if (v != null && v.toString().isNotEmpty) {
      canonicalId = v.toString();
      break;
    }
  }

  // If no ID found, generate one for debugging
  if (canonicalId == null) {
    canonicalId = 'no_id_${DateTime.now().millisecondsSinceEpoch}';
    log('⚠️ Message has no ID, generated: $canonicalId');
  }

  m['message_id'] = rawMsg["message_id"];
  m['id'] = rawMsg["message_id"];
  m['messageId'] = rawMsg["message_id"];
  m['_id'] = rawMsg["message_id"];

  // ================= EXTRACT CONTENT =================
  m['content'] = (rawMsg['content'] ?? rawMsg['content'] ?? '').toString();

  // Check for LORRO content structure
  if (m['content'].isEmpty && rawMsg is Map) {
    final v = rawMsg['v'];
    if (v is Map) {
      m['content'] = (v['content'] ?? v['content'] ?? '').toString();
    }
  }

  // ================= EXTRACT TIME =================
  dynamic timeRaw =
      rawMsg['time'] ?? rawMsg['createdAt'] ?? rawMsg['created_at'];

  // Handle LORRO timestamp structure
  if (timeRaw == null && rawMsg is Map && rawMsg.containsKey('ts')) {
    final ts = rawMsg['ts'];
    if (ts is Map && ts.containsKey('wallTime')) {
      timeRaw = ts['wallTime'];
    } else if (ts is int) {
      // Convert milliseconds to ISO string
      timeRaw = DateTime.fromMillisecondsSinceEpoch(ts).toIso8601String();
    }
  }

  m['time'] = timeRaw;
  //////////
  final List<Map<String, dynamic>> reactions = [];
  final Map<String, Map<String, dynamic>> unique = {};

// from reactions array
  if (rawMsg['reactions'] is List) {
    for (final r in rawMsg['reactions']) {
      if (r is Map) {
        final user = r['user'] ?? {};
        final uid = user['_id']?.toString() ?? r['userId']?.toString();
        if (uid == null || uid.isEmpty) continue;

        unique[uid] = {
          'emoji': r['emoji'],
          'reacted_at': r['reacted_at'],
          'user': {
            '_id': uid,
            'first_name': user['first_name'] ?? '',
            'last_name': user['last_name'] ?? '',
          }
        };
      }
    }
  }

// from properties.reaction (SOCKET CASE)
  if (rawMsg['properties'] is List) {
    for (final p in rawMsg['properties']) {
      if (p is Map && p['reaction'] != null) {
        final r = p['reaction'];
        final uid = p['member_id']?.toString();
        if (uid == null || uid.isEmpty) continue;

        unique[uid] = {
          'emoji': r['emoji'],
          'reacted_at': r['reacted_at'],
          'user': {
            '_id': uid,
            'first_name': '',
            'last_name': '',
          }
        };
      }
    }
  }

  reactions.addAll(unique.values);
  m['reactions'] = reactions;

  // ================= EXTRACT SENDER =================
  dynamic senderRaw = rawMsg['sender'];
  String? senderId = rawMsg['senderId']?.toString();

  // Handle LORRO sender structure
  if (senderRaw == null && rawMsg is Map) {
    final v = rawMsg['v'];
    if (v is Map) {
      senderRaw = v['sender'];
      senderId = v['senderId']?.toString();
    }
  }

  if (senderRaw is Map) {
    senderId ??= senderRaw['_id']?.toString() ??
        senderRaw['id']?.toString() ??
        senderRaw['userId']?.toString();

    senderRaw = {
      '_id': senderId,
      'id': senderId,
      'first_name': senderRaw['first_name'] ?? senderRaw['firstName'] ?? '',
      'last_name': senderRaw['last_name'] ?? senderRaw['lastName'] ?? '',
    };
  } else if (senderRaw != null && senderId == null) {
    senderId = senderRaw.toString();
    senderRaw = {'_id': senderId, 'id': senderId};
  } else if (senderRaw == null && senderId != null) {
    senderRaw = {'_id': senderId, 'id': senderId};
  }

  // Also check 'from' field
  if ((senderId == null || senderId.isEmpty) && rawMsg['from'] != null) {
    senderId = rawMsg['from'].toString();
    senderRaw = {'_id': senderId, 'id': senderId};
  }

  m['sender'] = senderRaw;
  m['senderId'] = senderId ?? '';
  m['from'] = senderId ?? '';

  // ================= STATUS =================
  m['messageStatus'] = (rawMsg['messageStatus'] ??
      rawMsg['status'] ??
      rawMsg['deliveryStatus'] ??
      'sent')
      .toString();

  final rawReply = rawMsg['reply'] ?? rawMsg['repliedMessage'];
  String? originalKey = rawMsg['originalKey'];

  if (rawReply is Map) {

    final String? replyUrl = rawReply['replyUrl'] ??
        rawReply['originalUrl'] ??
        rawReply['fileUrl'];

    final String? fileName = rawReply['fileName'];
    final String? contentType =
        rawReply['ContentType'] ?? rawReply['fileType'];

    m['reply'] = {
      'message_id': rawReply['reply_message_id'],
      'reply_message_id': rawReply['reply_message_id'],
      'content': rawReply['replyContent'] ?? '',
      'replyContent': rawReply['replyContent'] ?? '',
      'originalUrl': replyUrl,
      'imageUrl': replyUrl,
      'fileUrl': replyUrl,
      'fileName': fileName,
      'fileType': contentType,
      'group_message_id': rawReply['isGroupedMessageId']??rawReply['is_grouped_message'],
      'is_grouped_message': rawReply['isGroupedMessage'] ?? rawReply['is_grouped_message']??false,
    };

    m['isReplyMessage'] = true;
  }
  final bool isGrouped =
      rawMsg['is_grouped_message'] == true ||
          rawMsg['isGroupedMessage'] == true;

  final String? groupId =
      rawMsg['group_message_id'] ??
          rawMsg['groupMessageId'] ??
          rawMsg['isGroupedMessageId'];

  m['is_grouped_message'] = isGrouped;
  m['group_message_id'] = isGrouped ? groupId : null;
  // ================= DELETED STATUS =================
  m['is_deleted'] = rawMsg['is_deleted'] == true;
  m['isForwarded'] = rawMsg['isForwarded'];
  m['originalKey'] = originalKey;
  m['mimeType'] = rawMsg['mimeType'];
  m['duration'] = rawMsg['duration'];

  // ================= MEDIA =================
  String? imageUrl = rawMsg['imageUrl'];
  if (imageUrl == null || imageUrl.toString().isEmpty) {
    imageUrl = rawMsg['thumbnailUrl'];
  }

  // Check LORRO structure
  if ((imageUrl == null || imageUrl.isEmpty) && rawMsg is Map) {
    final v = rawMsg['v'];
    if (v is Map) {
      imageUrl = v['imageUrl'] ?? v['thumbnailUrl'];
    }
  }

  String? originalUrl = rawMsg['originalUrl'];
  if (originalUrl == null || originalUrl.toString().isEmpty) {
    originalUrl = rawMsg['fileUrl'];
  }

  // Check LORRO structure
  if ((originalUrl == null || originalUrl.isEmpty) && rawMsg is Map) {
    final v = rawMsg['v'];
    if (v is Map) {
      originalUrl = v['originalUrl'] ?? v['fileUrl'];
    }
  }

  m['imageUrl'] = imageUrl;
  m['originalUrl'] = originalUrl;
  m['fileUrl'] = rawMsg['fileUrl'] ?? originalUrl;
  m['fileName'] = rawMsg['fileName'] ?? rawMsg['filename'] ?? rawMsg['name'];
  if (m['fileName'] == null && rawMsg is Map) {
    final v = rawMsg['v'];
    if (v is Map) {
      m['fileName'] = v['fileName'] ?? v['filename'] ?? v['name'];
    }
  }

  // 🔥 Fix: Preserve ContentType and duration for Audio
  m['ContentType'] = rawMsg['ContentType'] ?? rawMsg['contentType'];
  if (m['ContentType'] == null && rawMsg is Map) {
    final v = rawMsg['v'];
    if (v is Map) {
      m['ContentType'] = v['ContentType'] ?? v['contentType'];
    }
  }

  // 🔥 NEW: Robust inference if ContentType is still missing
  if (m['ContentType'] == null || m['ContentType'].toString().isEmpty) {
    final fname = (m['fileName'] ?? '').toString().toLowerCase();
    final furl =
    (m['fileUrl'] ?? m['originalUrl'] ?? '').toString().toLowerCase();
    if (fname.contains('audio_') ||
        fname.endsWith('.m4a') ||
        fname.endsWith('.mp3') ||
        fname.endsWith('.opus') ||
        furl.contains('/audio/')) {
      m['ContentType'] = 'audio';
      log('🎵 Inferred ContentType: audio for ${m['message_id']}');
    }
  }

  m['duration'] = rawMsg['duration'] ??
      rawMsg['audioDuration'] ??
      rawMsg['videoDuration'];
  if (m['duration'] == null && rawMsg is Map) {
    final v = rawMsg['v'];
    if (v is Map) {
      m['duration'] =
          v['duration'] ?? v['audioDuration'] ?? v['videoDuration'];
    }
  }

// ================= EXTRACT REPLY DATA =================
  // Ensure reply fields are set on snapshot load

  final rawReplyId = rawMsg['reply_message_id'] ?? rawMsg['replyMessageId'];
  final rawReplyContent = rawMsg['replyContent'];
  final rawIsReplyMessage = rawMsg['isReplyMessage'];
  final bool hasReply =
  _hasValidReply(rawReply, rawReplyId, rawReplyContent);

  // Set isReplyMessage flag
  if (rawIsReplyMessage == true ||
      rawReply != null ||
      rawReplyId != null ||
      rawReplyContent != null) {
    m['isReplyMessage'] = true;
  }

  if (m['message_id'] == null) {
    final sender = m['senderId'] ?? '';
    final time = m['time'] ?? '';
    final content = m['content'] ?? '';
    final media = m['fileUrl'] ?? m['imageUrl'] ?? '';

    m['forwardFingerprint'] = '$sender|$time|$content|$media';
  }

  // Set reply object if present
  if (hasReply &&rawReply is Map) {
    m['reply'] = {
      'reply_message_id':
      rawReply['reply_message_id'] ?? rawReply['message_id'],
      'message_id': rawReply['reply_message_id'] ?? rawReply['message_id'],
      'id': rawReply['reply_message_id'] ?? rawReply['message_id'],
      'replyContent': rawReply['replyContent'] ?? rawReply['content'] ?? '',
      'content': rawReply['replyContent'] ?? rawReply['content'] ?? '',
      'fileName': rawReply['fileName'],
      'fileType': rawReply['fileType'] ?? rawReply['ContentType'],
      'group_message_id': rawReply['group_message_id']??rawReply['isGroupedMessageId'],
      'is_grouped_message':rawReply['is_grouped_message']?? rawReply['isGroupedMessage'] ??false,
      'originalUrl': rawReply['originalUrl'],
      'imageUrl': rawReply['imageUrl'],
      'fileUrl': rawReply['fileUrl'],
    };
  }else {
    // 🔥 CLEAN GHOST REPLY DATA
    m.remove('reply');
    m.remove('reply_message_id');
    m.remove('replyMessageId');
    m.remove('replyContent');
  }

  // Set reply_message_id if present
  if (rawReplyId != null) {
    m['reply_message_id'] = rawReplyId;
    m['replyMessageId'] = rawReplyId;
  }

  // Set replyContent if present
  if (rawReplyContent != null) {
    m['replyContent'] = rawReplyContent.toString();
  }

  return m;
}


void updateMessageStatus(
    {
      required String messageId,
      required String status,
      required List<Map<String, dynamic>> messages,
      required List<Map<String, dynamic>> socketMessages,
      required List<Map<String, dynamic>> dbMessages,
      required void Function({bool isInitialLoad}) updateNotifier,
      required void Function() scheduleSaveMessages,
      bool localMark = false})
{
  //log("🔄 _updateMessageStatus called for $messageId → $status (localMark=$localMark)");

  bool updated = false;

  void updateInList(List<Map<String, dynamic>> list) {
    for (var msg in list) {
      final id = (msg['message_id'] ?? msg['messageId'] ?? '').toString();
      if (id == messageId) {
        final current = (msg['messageStatus'] ?? '').toString();

        // Once read, never downgrade to less final states
        if (current == 'read' && status != 'read') {
          return;
        }

        if (current != status) {
          msg['messageStatus'] = status;
          updated = true;
        }

        if (status == 'read' && localMark == true) {
          msg['_localMarkedRead'] = true;
        }

        break;
      }
    }
  }

  updateInList(messages);
  updateInList(socketMessages);
  updateInList(dbMessages);

  if (updated) {
    updateNotifier();
    scheduleSaveMessages();
  }
}

List<Map<String, dynamic>> getGroupedMessages(
    List<Map<String, dynamic>> combinedMessages,
    int index,
    )
{
  final message = combinedMessages[index];
  final String? groupId = message['group_message_id']?.toString();

  // 🔹 Single message fallback
  if (groupId == null || groupId.isEmpty) {
    return [normalizeForForward(message)];
  }

  final List<Map<String, dynamic>> result = [];

  for (int i = index; i < combinedMessages.length; i++) {
    final m = combinedMessages[i];

    if (m['group_message_id']?.toString() != groupId) break;

    result.add(normalizeForForward(m));
  }

  return result;
}

Map<String, dynamic> normalizeForForward(Map<String, dynamic> m) {
  final String? imageUrl =
      m['originalUrl'] ?? m['imageUrl'] ?? m['localImagePath'];

  final String? fileUrl = m['fileUrl'];
  final String fileType =
  (m['fileType'] ?? m['mimeType'] ?? '').toString().toLowerCase();

  final bool isVideo = fileType.startsWith('video/') ||
      (fileUrl != null &&
          RegExp(r'\.(mp4|mov|mkv|avi|webm)$', caseSensitive: false)
              .hasMatch(fileUrl));

  return {
    ...m,
    'imageUrl': imageUrl,
    'fileUrl': fileUrl,
    'fileType': fileType,
    'originalUrl': imageUrl,
    'isVideo': isVideo,
    'group_message_id': m['group_message_id'],
  };
}
