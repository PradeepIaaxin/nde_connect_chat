import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/MessagerBloc.dart';

import '../../MessagerEvent.dart';

Map<String, dynamic>? resolveRepliedMessage({
  required Map<String, dynamic> message,
  required List<Map<String, dynamic>> allMessages,
}) {
  if (message['isReplyMessage'] != true) return null;

  // already resolved
  if (message['repliedMessage'] != null) {
    return Map<String, dynamic>.from(message['repliedMessage']);
  }

  final String? replyId = message['replyMessageId']?.toString();
  if (replyId == null || replyId.isEmpty) return null;

  try {
    final original = allMessages.firstWhere(
      (m) => m['message_id']?.toString() == replyId,
    );

    return {
      'content': original['content'],
      'imageUrl': original['imageUrl'],
      'fileUrl': original['fileUrl'],
      'fileType': original['fileType'],
      'originalUrl': original['originalUrl'],
      'isVideo': original['isVideo'],
      'fileName': original['fileName'],
      'senderName': original['senderName'],
    };
  } catch (_) {
    return null;
  }
}

void normalizeReplyMessages(List<Map<String, dynamic>> messages) {
  for (final msg in messages) {
    if (msg['isReplyMessage'] == true &&
        msg['repliedMessage'] == null &&
        msg['reply_message_id'] != null) {
      final replyId = msg['reply_message_id'].toString();

      try {
        final original = messages.firstWhere(
          (m) =>
              (m['message_id'] ?? m['messageId'] ?? m['id'])?.toString() ==
              replyId,
        );

        msg['repliedMessage'] = {
          'replyContent': original['content'],
          'fileType': original['fileType'] ?? original['mimeType'],
          'originalUrl': original['originalUrl'] ??
              original['imageUrl'] ??
              original['fileUrl'],
          'thumbnailUrl': original['thumbnailUrl'],
          'fileUrl': original['fileUrl'],
          'imageUrl': original['imageUrl'],
          'senderName': original['senderName'],
          'duration': original['duration'],
        };
      } catch (_) {}
    }
  }
}

bool _isVisualMedia(Map m) {
  // 1️⃣ Metadata (fast & clean)
  final type = (m['ContentType'] ?? m['fileType'] ?? m['mimeType'] ?? '')
      .toString()
      .toLowerCase();

  if (type.contains('image') || type.contains('video')) {
    return true;
  }

  // 2️⃣ URL / filename fallback (critical for forwarded media)
  final String url = (m['fileUrl'] ?? m['originalUrl'] ?? m['imageUrl'] ?? '')
      .toString()
      .toLowerCase();

  final String name = (m['fileName'] ?? '').toString().toLowerCase();

  bool hasExt(String s) =>
      s.contains('.jpg') ||
      s.contains('.jpeg') ||
      s.contains('.png') ||
      s.contains('.webp') ||
      s.contains('.mp4') ||
      s.contains('.mov') ||
      s.contains('.mkv');

  return hasExt(url) || hasExt(name);
}

String? senderIdOf(Map msg) {
  return msg['sender']?['_id']?.toString() ??
      msg['senderId']?.toString() ??
      msg['from']?.toString();
}

String _forwardBatchKey(
    Map<String, dynamic> m, DateTime Function(dynamic) parseTime) {
  return [
    senderIdOf(m),
    m['isForwarded'] == true ? 'FWD' : 'NF',
    parseTime(m['time']).millisecondsSinceEpoch ~/ 60000 // 1-min bucket
  ].join('_');
}

List<Map<String, dynamic>> buildGroupedMessages(
    List raw, DateTime Function(dynamic) parseTime) {
  final List<Map<String, dynamic>> messages =
      List<Map<String, dynamic>>.from(raw)
        ..sort((a, b) => parseTime(a['time']).compareTo(parseTime(b['time'])));

  final List<Map<String, dynamic>> result = [];
  final Map<String, Map<String, dynamic>> lastMediaBySender = {};

  String normCaption(Map m) => (m['content'] ?? '').toString().trim();

  for (final current in messages) {
    final senderId = senderIdOf(current);

    if (senderId == null || !_isVisualMedia(current)) {
      result.add(current);
      continue;
    }

    final prev = lastMediaBySender[senderId];

    if (prev != null && _isVisualMedia(prev)) {
      final diffSeconds = parseTime(current['time'])
          .difference(parseTime(prev['time']))
          .inSeconds
          .abs();

      final bool prevHasCaption = normCaption(prev).isNotEmpty;
      final bool currHasCaption = normCaption(current).isNotEmpty;

      final bool sameForwardBatch = prev['isForwarded'] == true &&
          current['isForwarded'] == true &&
          _forwardBatchKey(prev, parseTime) ==
              _forwardBatchKey(current, parseTime);

      final bool sameCaption = normCaption(prev) == normCaption(current);

      final bool shouldGroup =
          // 🔹 Normal send (no captions)
          (!prevHasCaption && !currHasCaption && diffSeconds <= 60) ||

              // 🔥 Forwarded batch (ALLOW captions if SAME)
              (prev['isForwarded'] == true &&
                  current['isForwarded'] == true &&
                  sameForwardBatch &&
                  ((!prevHasCaption && !currHasCaption) || sameCaption));

      if (shouldGroup) {
        final groupId = prev['group_message_id'] ??
            prev['message_id'] ??
            current['message_id'];

        prev['is_grouped_message'] = true;
        prev['group_message_id'] = groupId;

        current['is_grouped_message'] = true;
        current['group_message_id'] = groupId;
      }
    }

    result.add(current);
    lastMediaBySender[senderId] = current;
  }

  return result;
}

bool isUnreadMessage(dynamic msg, String currentUserId) {
  if (msg is Map<String, dynamic>) {
    final senderId =
        (msg['senderId'] ?? msg['sender']?['_id'] ?? msg['sender']?['id'])
            ?.toString();

    return msg['messageStatus'] != 'read' &&
        senderId != currentUserId &&
        msg['message_id'] != null;
  }
  return false;
}

List<String> getUnreadMessageIds(List<dynamic> msgs, String currentUserId) {
  return msgs
      .where(
        (element) {
          return isUnreadMessage(msgs, currentUserId);
        },
      )
      .map((m) => m['message_id'].toString())
      .toList();
}

bool isNearBottom(ScrollController _scrollController) {
  if (!_scrollController.hasClients) return true;
  return _scrollController.offset < 80; // 👈 threshold
}

void sendAudioMessage(
{
  required String path,
  required int duration,
  required MessagerBloc messagerBloc,
  required String currentUserId,
  required String receiverId,
  required String convoId,

}
) {
  debugPrint("Sending audio message: $path, duration: $duration");

  messagerBloc.add(
    SendAudioMessageEvent(
        senderId: currentUserId,
        receiverId:receiverId ?? '',
        audioPath: path,
        duration: duration.toString(),
        convoId: convoId,
        isRecord: true),
  );
}

List<Map<String, dynamic>> getCombinedMessages(
{
  required List<Map<String, dynamic>> dbMessages,
  required List<Map<String, dynamic>> messages,
  required List<Map<String, dynamic>> socketMessages,
  required  DateTime Function(dynamic) parseTime,
  required   bool Function(Map<String, dynamic>) hasReplyForMessage,
}
    ) {
  final combined = <Map<String, dynamic>>[];
  int idx = 0;

  void addWithIndex(List<Map<String, dynamic>> source) {
    for (var m in source) {
      if (m.isNotEmpty) {
        final copy = Map<String, dynamic>.from(m);
        copy['_localIndex'] ??= idx++;
        combined.add(copy);
      }
    }
  }

  addWithIndex(dbMessages);
  addWithIndex(messages);
  addWithIndex(socketMessages);

  // 🔥 SORT BY TIME (LIKE WEB)
  combined.sort((a, b) {
    try {
      final ta = parseTime(a['time']);
      final tb = parseTime(b['time']);
      final cmp = ta.compareTo(tb);
      if (cmp != 0) return cmp;

      final ia = a['_localIndex'] as int? ?? 0;
      final ib = b['_localIndex'] as int? ?? 0;
      return ia.compareTo(ib);
    } catch (_) {
      return 0;
    }
  });

  final result = <Map<String, dynamic>>[];

  for (final m in combined) {
    final id = (m['message_id'] ?? m['messageId'] ?? m['id'])?.toString() ?? '';

    if (id.isEmpty) {
      result.add(m);
      continue;
    }

    final existingIndex = result.indexWhere((e) {
      final eid =
          (e['message_id'] ?? e['messageId'] ?? e['id'])?.toString() ?? '';
      if (eid == id) return true;

      // 🔥 AGGRESSIVE DEDUPLICATION:
      // If IDs differ, check if it's potentially the same message
      // (Same sender, same content/fileName, and very close time)
      final eIsTemp = e['_isTempMessage'] == true;
      final mIsTemp = m['_isTempMessage'] == true;

      if (eIsTemp != mIsTemp) {
        final eSender = (e['senderId'] ?? e['from'])?.toString();
        final mSender = (m['senderId'] ?? m['from'])?.toString();

        if (eSender == mSender && eSender != null) {
          final eContent = (e['content'] ?? '').toString();
          final mContent = (m['content'] ?? '').toString();
          final eFileName = (e['fileName'] ?? '').toString();
          final mFileName = (m['fileName'] ?? '').toString();

          final bool contentMatch = eContent.isNotEmpty && eContent == mContent;
          final bool fileMatch = eFileName.isNotEmpty && eFileName == mFileName;

          if (contentMatch || fileMatch) {
            try {
              final te = parseTime(e['time']);
              final tm = parseTime(m['time']);
              // Within 5 seconds (to account for server time skew)
              if (te.difference(tm).inSeconds.abs() < 5) {
                return true;
              }
            } catch (_) {}
          }
        }
      }
      return false;
    });

    if (existingIndex == -1) {
      result.add(m);
    } else {
      final existing = result[existingIndex];

      // Preference logic: keep server message over temp message
      final existingIsTemp = existing['_isTempMessage'] == true;
      final newIsTemp = m['_isTempMessage'] == true;

      if (existingIsTemp && !newIsTemp) {
        // Replace temp with real
        result[existingIndex] = m;
      } else if (!existingIsTemp && newIsTemp) {
        // Keep the existing real message, skip new temp
      } else {
        // Both real or both temp, keep latest info
        final existingHasReply = hasReplyForMessage(existing);
        final newHasReply = hasReplyForMessage(m);

        if (newHasReply && !existingHasReply) {
          result[existingIndex] = m;
        } else {
          result[existingIndex] = m;
        }
      }
    }
  }

  // 🔥 RESOLVE REPLIES AFTER MERGE
  for (final msg in result) {
    if (msg['isReplyMessage'] == true && msg['repliedMessage'] == null) {
      final resolved = resolveRepliedMessage(
        message: msg,
        allMessages: result,
      );
      if (resolved != null) {
        msg['repliedMessage'] = resolved;
      }
    }
  }

  return result;
}




void selectGroupedMessages({
 required List<Map<String, dynamic>> grouped,
 required  Set<String> selectedMessageKeys,
 required  Set<String> selectedMessageIds,
 required  bool isSelectionMode,
 required   List<Map<String, dynamic>> selectedMessages,
 required  void Function(void Function()) setState,
 required  String Function(Map<String, dynamic>) generateMessageKey,

}) {
  final bool isGroupSelected = grouped.any(
        (m) => selectedMessageKeys.contains(generateMessageKey(m)),
  );

  setState(() {
    for (final m in grouped) {
      final key = generateMessageKey(m);
      final id = m['message_id']?.toString();

      if (isGroupSelected) {
        selectedMessageKeys.remove(key);
        selectedMessageKeys.remove(id);
       // selectedMessageKeys.removeWhere((x) => generateMessageKey(x) == key);
      } else {
        selectedMessageKeys.add(key);
        if (id != null) selectedMessageIds.add(id);
        selectedMessages.add(m);
      }
    }

    isSelectionMode = selectedMessageKeys.isNotEmpty;
  });
}

void replyToMessage(
    {
      required Map<String, dynamic> message,
      required Map<String, dynamic>? replyMessage,
      required Map<String, dynamic> replyPreview,
      required List<Map<String, dynamic>> allMessages,
      required String currentUserId,
      required  FocusNode  focusNode,
      required   void Function(void Function())  setState,
      bool isSendMe = false,
    })
{
  if (message.isEmpty) return;

  log("Reply source (swiped) => $message");

  // ✅ ALWAYS reply to the swiped message itself
  final Map<String, dynamic> replySource = Map<String, dynamic>.from(message);

  final String? originalUrl = replySource['originalUrl'] ??
      replySource['imageUrl'] ??
      replySource['fileUrl'];
  log("Reply replySource (swiped) => $replySource");

  final String fileType =
      replySource['mimeType'] ?? replySource['fileType'] ?? '';

  final bool isVideo = fileType.toLowerCase().startsWith('video/');
  log("Reply replySource (swiped) => $fileType");

  setState(() {
    replyMessage = replySource;
    // Calculate counts if it's a grouped message
    int imageCount = 0;
    int videoCount = 0;
    final String? groupId = replySource['group_message_id']?.toString();

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

    replyPreview = {
      'message_id': replySource['message_id'] ??
          replySource['messageId'] ??
          replySource['id'],

      'content': (replySource['content'] ?? '').toString(),

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

    focusNode.requestFocus();
  });
}