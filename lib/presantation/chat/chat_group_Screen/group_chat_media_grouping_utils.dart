import 'group_chat_text_utils.dart';
import 'package:objectid/objectid.dart';
import 'group_chat_message_utils.dart';

class GroupChatMediaGroupingUtils {
  static bool sameMediaType(String a, String b) {
    final bool aIsVisual = a.startsWith('image') || a.startsWith('video');
    final bool bIsVisual = b.startsWith('image') || b.startsWith('video');

    return aIsVisual && bIsVisual;
  }

  static bool isVisualMedia(Map m) {
    final String url = (m['fileUrl'] ?? m['originalUrl'] ?? m['imageUrl'] ?? '')
        .toString()
        .toLowerCase();

    final String name = (m['fileName'] ?? '').toString().toLowerCase();

    return url.endsWith('.jpg') ||
        url.endsWith('.jpeg') ||
        url.endsWith('.png') ||
        url.endsWith('.webp') ||
        url.endsWith('.mp4') ||
        url.endsWith('.mov') ||
        url.endsWith('.mkv') ||
        name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.png') ||
        name.endsWith('.webp') ||
        name.endsWith('.mp4') ||
        name.endsWith('.mov') ||
        name.endsWith('.mkv');
  }

  static String? senderIdOf(Map msg) {
    return (msg['sender'] is Map ? (msg['sender'] as Map)['_id'] : null)
            ?.toString() ??
        msg['senderId']?.toString() ??
        msg['from']?.toString();
  }

  static String _forwardBatchKey(Map<String, dynamic> m) {
    return [
      senderIdOf(m),
      m['isForwarded'] == true ? 'FWD' : 'NF',
      parseChatTime(m['time']).millisecondsSinceEpoch ~/ 60000
    ].join('_');
  }

  static List<Map<String, dynamic>> buildGroupedMessages(List raw) {
    final List<Map<String, dynamic>> messages =
        List<Map<String, dynamic>>.from(raw)
          ..sort((a, b) =>
              parseChatTime(a['time']).compareTo(parseChatTime(b['time'])));

    final List<Map<String, dynamic>> result = [];
    final Map<String, Map<String, dynamic>> lastMediaBySender = {};

    String normCaption(Map m) => (m['content'] ?? '').toString().trim();

    for (final current in messages) {
      final senderId = senderIdOf(current);

      if (senderId == null || !isVisualMedia(current)) {
        result.add(current);
        continue;
      }

      final prev = lastMediaBySender[senderId];

      if (prev != null && isVisualMedia(prev)) {
        final diffSeconds = parseChatTime(current['time'])
            .difference(parseChatTime(prev['time']))
            .inSeconds
            .abs();

        final bool prevHasCaption = normCaption(prev).isNotEmpty;
        final bool currHasCaption = normCaption(current).isNotEmpty;

        final bool sameForwardBatch = prev['isForwarded'] == true &&
            current['isForwarded'] == true &&
            _forwardBatchKey(prev) == _forwardBatchKey(current);

        final bool sameCaption = normCaption(prev) == normCaption(current);

        final bool shouldGroup =
            (!prevHasCaption && !currHasCaption && diffSeconds <= 60) ||
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

  static List<Map<String, dynamic>> inferGrouping(
    List<Map<String, dynamic>> messages,
    Function(String messageId, String groupId) applyGroupingToSource,
  ) {
    if (messages.isEmpty) return messages;

    for (int i = 0; i < messages.length; i++) {
      final currentMsg = messages[i];

      // Skip if already grouped
      if (currentMsg['is_grouped_message'] == true &&
          currentMsg['group_message_id'] != null) {
        continue;
      }

      final bool isMedia = GroupChatMessageUtils.isGroupableMedia(currentMsg);
      if (!isMedia) continue;

      // Look ahead for consecutive media from same sender within time threshold
      List<int> groupIndices = [i];
      final currentSender = currentMsg['sender'] is Map
          ? currentMsg['sender']['_id']?.toString()
          : currentMsg['sender']?.toString();
      final currentTime = parseChatTime(currentMsg['time']);

      for (int j = i + 1; j < messages.length; j++) {
        final nextMsg = messages[j];
        final nextSender = nextMsg['sender'] is Map
            ? nextMsg['sender']['_id']?.toString()
            : nextMsg['sender']?.toString();
        final nextTime = parseChatTime(nextMsg['time']);

        // Detect media for next message
        // Detect media for next message
        final bool nextIsMedia =
            GroupChatMessageUtils.isGroupableMedia(nextMsg);
        final String nextContent =
            (nextMsg['content']?.toString() ?? '').trim();

        if (nextSender != currentSender ||
            !nextIsMedia ||
            nextTime.difference(currentTime).inMinutes.abs() > 1) {
          break;
        }

        // Handle Captions:
        // Group only if BOTH have NO caption OR BOTH have IDENTICAL captions
        final String currentContent =
            (currentMsg['content']?.toString() ?? '').trim();
        if (currentContent != nextContent) {
          break;
        }

        // Handle group_message_id boundary:
        // If either has a group_message_id from the server, they must match
        final String? currentGrpId =
            (currentMsg['group_message_id'] ?? currentMsg['groupMessageId'])
                ?.toString();
        final String? nextGrpId =
            (nextMsg['group_message_id'] ?? nextMsg['groupMessageId'])
                ?.toString();

        if (currentGrpId != null || nextGrpId != null) {
          if (currentGrpId != nextGrpId) {
            break;
          }
        }

        groupIndices.add(j);
      }

      // If we found a group of 2+ media items
      if (groupIndices.length > 1) {
        final groupId = ObjectId().toString();

        // ✅ CRITICAL: Persist grouping info to the ORIGINAL SOURCE messages
        for (final index in groupIndices) {
          final messageToGroup = messages[index];
          final msgId = (messageToGroup['message_id'] ??
                  messageToGroup['messageId'] ??
                  messageToGroup['id'])
              ?.toString();

          // Apply grouping to combined list
          messageToGroup['is_grouped_message'] = true;
          messageToGroup['group_message_id'] = groupId;

          // Also persist to source arrays
          if (msgId != null) {
            applyGroupingToSource(msgId, groupId);
          }
        }
        // Skip the processed messages in the outer loop
        i = groupIndices.last;
      }
    }
    return messages;
  }
}
