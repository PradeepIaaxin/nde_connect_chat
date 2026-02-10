

import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nde_email/presantation/chat/Socket/Socket_Service.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/widget/privat_common_funtions/privat_chat_funtions_2.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/widget/privat_common_funtions/privat_chat_funtions_4.dart';

import '../../../../../../data/respiratory.dart';
import '../../../../../../utils/router/router.dart';
import '../../../../../widgets/chat_widgets/messager_Wifgets/ForwardMessageScreen_widget.dart';


import '../../MessagerBloc.dart';
import '../../MessagerEvent.dart';
import '../../MessagerState.dart';
import '../../message_handler.dart';

Future<bool> fetchUntilMessageFound({
  required String messageId,
  required bool mounted,
  required  List<Map<String, dynamic>> dbMessages,
  required  List<Map<String, dynamic>> messages,
  required  List<Map<String, dynamic>> socketMessages,
  required DateTime Function(dynamic) parseTime,
  required  bool Function(Map<String, dynamic>) hasReplyForMessage,
  required  bool hasNextPage,
  required  MessagerBloc messagerBloc,
  required  String convoId,
  required   int currentPage,
  required   int initialLimit,

}) async {
  if (messageId.isEmpty) return false;
  int safety = 0;

  while (safety < 10 && mounted) {
    safety++;

    final combined = getCombinedMessages(dbMessages: dbMessages, messages: messages, socketMessages: socketMessages, parseTime: parseTime, hasReplyForMessage:hasReplyForMessage);
    final exists = combined.any((m) {
      final mid =
      (m['message_id'] ?? m['messageId'] ?? m['id'] ?? '').toString();
      return mid == messageId;
    });

    if (exists) return true;
    if (!hasNextPage) return false;

    // Wait for the BLoC to finish loading this page
    final completer = Completer<void>();
    late final StreamSubscription sub;

    sub = messagerBloc.stream.listen((state) {
      if (state is MessagerLoaded && !completer.isCompleted) {
        completer.complete();
      }
    });

    currentPage++;
    log('📡 _fetchUntilMessageFound: Fetching page $currentPage...');
    messagerBloc.add(
      FetchMessagesEvent(
        convoId: convoId,
        page: currentPage,
        limit: initialLimit,
      ),
    );

    try {
      await completer.future.timeout(const Duration(seconds: 5));
    } catch (_) {
      // Timeout - continue anyway
    } finally {
      await sub.cancel();
    }
  }

  final combined = getCombinedMessages(dbMessages: dbMessages, messages: messages, socketMessages: socketMessages, parseTime: parseTime, hasReplyForMessage:hasReplyForMessage);
  return combined.any((m) {
    final mid =
    (m['message_id'] ?? m['messageId'] ?? m['id'] ?? '').toString();
    return mid == messageId;
  });
}

void highlightAndScrollToContext(BuildContext ctx, String messageId,void Function(String) highlightMessage,) {
  if (!ctx.mounted) return;

  highlightMessage(messageId);

  Scrollable.ensureVisible(
    ctx,
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeOut,
    alignment: 0.5,
  );
}

double estimateScrollOffset(
    int listIndex, List<Map<String, dynamic>> messages,DateTime Function(dynamic) parseTime,bool Function(DateTime?, DateTime?) isSameDay)
{
  double offset = 0.0;
  for (int i = 0; i < listIndex; i++) {
    final realIndex = messages.length - 1 - i;
    if (realIndex >= 0 && realIndex < messages.length) {
      offset += estimateMessageHeight(realIndex, messages,parseTime,isSameDay);
    }
  }
  return offset;
}

double estimateMessageHeight(
    int index, List<Map<String, dynamic>> messages,DateTime Function(dynamic) parseTime,bool Function(DateTime?, DateTime?) isSameDay)
{
  if (index < 0 || index >= messages.length) return 0.0;
  final message = messages[index];

  // Date separator logic
  double separatorHeight = 0.0;
  try {
    final currentTime = parseTime(message['time']);
    final prevTime =
    index > 0 ? parseTime(messages[index - 1]['time']) : null;
    if (index == 0 || !isSameDay(currentTime, prevTime)) {
      separatorHeight = 40.0;
    }
  } catch (_) {}

  // Grouping logic: only the first message in a group has height
  final isGrouped = message['is_grouped_message'] == true;
  final groupId = message['group_message_id']?.toString();
  if (isGrouped && groupId != null && index > 0) {
    final prev = messages[index - 1];
    if (prev['is_grouped_message'] == true &&
        prev['group_message_id']?.toString() == groupId) {
      return 0.0;
    }
  }

  // System message check
  final contentType = message['ContentType'] ?? message['contentType'] ?? "";
  final content = (message['content'] ?? '').toString();
  if (contentType == "system") {
    return 0.0 + separatorHeight;
  }

  double height = 60.0;

  if (content.isNotEmpty) {
    height += (content.length / 40) * 20.0;
  }

  // Media
  if ((message['imageUrl'] != null &&
      message['imageUrl'].toString().isNotEmpty) ||
      (message['localImagePath'] != null &&
          message['localImagePath'].toString().isNotEmpty) ||
      (message['fileUrl'] != null &&
          message['fileUrl'].toString().isNotEmpty)) {
    if (isGrouped) {
      height += 250.0;
    } else {
      height += 250.0;
    }
  }

  // Reply preview
  if (message['isReplyMessage'] == true || message['reply'] != null) {
    height += 60.0;
  }

  return height + separatorHeight;
}
Map<String, dynamic> buildReplyPreviewFromGroup(
    List<Map<String, dynamic>> messages,
    bool isSendMe,
    String currentUserId,
    )
{
  int imageCount = 0;
  int videoCount = 0;

  for (final m in messages) {
    final String fileType =
    (m['fileType'] ?? m['mimeType'] ?? '').toString().toLowerCase();
    final String? fileUrl = m['fileUrl']?.toString();
    final String? imageUrl = m['imageUrl']?.toString();

    final bool isVideo = fileType.startsWith('video/') ||
        (fileUrl != null &&
            RegExp(r'\.(mp4|mov|mkv|avi|webm)$', caseSensitive: false)
                .hasMatch(fileUrl));

    if (isVideo) {
      videoCount++;
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      imageCount++;
    }
  }

  String previewText;
  if (imageCount > 0 && videoCount > 0) {
    previewText = 'Media × ${imageCount + videoCount}';
  } else if (imageCount > 0) {
    previewText = 'Photo × $imageCount';
  } else if (videoCount > 0) {
    previewText = 'Video × $videoCount';
  } else {
    previewText = 'Message';
  }

  final first = messages.first;

  return {
    'message_id': first['message_id']?.toString(),
    'content': previewText,
    'isGroupedMedia': true,
    'imageCount': imageCount,
    'videoCount': videoCount,
    'userName': first['senderName'] ?? first['sender']?['first_name'] ?? '',
    'sender': first['sender'],
    'receiver': first['receiver'],
    'isSendMe': isSendMe,
    'senderId': currentUserId,
  };
}

void forwardSelectedMessages(
{
  required  List<Map<String, dynamic>> selectedMessages,
  required String currentUserId,
  required String convoId,
  required String firstname,
  required bool isSentMe,
  required void Function(void Function()) setState,
  required Set<String> selectedMessageKeys,
  required  Set<String> selectedMessageIds,
  required  bool isSelectionMode,
}
    ) {
  MyRouter.pushReplace(
    screen: ForwardMessageScreen(
      messages: selectedMessages.toList(),
      currentUserId: currentUserId,
      conversionalid:convoId,
      username: firstname ?? "",
      isForward: isSentMe,
    ),
  );

  setState(() {
    selectedMessages.clear();
    selectedMessageKeys.clear();
    selectedMessageIds.clear();
    isSelectionMode = false;
  });
}




/// Call this after messages are loaded and socket is connected.
Future<void> sendInitialReadReceiptsIfNeeded({
  required bool mounted,
  required SocketService socketService,
  required bool screenActive,
  required  List<Map<String, dynamic>> dbMessages,
  required  List<Map<String, dynamic>> messages,
  required  List<Map<String, dynamic>> socketMessages,
  required  String currentUserId,
  required  String datumId,
  required  String convoId,
  required  DateTime Function(dynamic) parseTime,
  required  bool Function(Map<String, dynamic>) hasReplyForMessage,
  required  Set<String> alreadyRead,
  required void Function({bool isInitialLoad}) updateNotifier,
  required void Function() scheduleSaveMessages,
}) async {
  if (!mounted) return;
  //log("🔁 _sendInitialReadReceiptsIfNeeded(): start");

  // Wait short time for socket to become connected (try a few times)
  const maxAttempts = 8;
  var attempt = 0;
  while (!socketService.isConnected && attempt < maxAttempts) {
    await Future.delayed(const Duration(milliseconds: 250));
    attempt++;
  }

  if (!socketService.isConnected) {
    log("⚠️ Socket not connected after wait — skipping initial read receipts.");
    return;
  }

  // Only send if the screen is active and visible to user
  if (!screenActive) {
    log("ℹ️ Screen not active — skipping initial read receipts.");
    return;
  }

  // Build combined messages and collect unread ids (messages from other user)
  final combined = getCombinedMessages(dbMessages: dbMessages, messages: messages, socketMessages: socketMessages, parseTime: parseTime, hasReplyForMessage:hasReplyForMessage);
  final unread = getUnreadMessageIds(combined,currentUserId)
      .where((id) => id.trim().isNotEmpty && !alreadyRead.contains(id))
      .toList();

  //log("🟢 initial unread IDs found (pre-check): $unread");

  // if (unread.isEmpty) {
  //   log("ℹ️ No unread messages to mark as read on init.");
  //   return;
  // }

  // Mark locally & remember
  for (final id in unread) {
    updateMessageStatus(
        messageId: id,
        status: 'read',
        messages: messages,
        socketMessages: socketMessages,
        updateNotifier: updateNotifier,
        scheduleSaveMessages: scheduleSaveMessages,
        dbMessages: dbMessages);
  }
  alreadyRead.addAll(unread);

  // compute consistent roomId
  final computedRoomId =
  socketService.generateRoomId(currentUserId, datumId ?? '');
  socketService.sendReadReceipts(
    messageIds: unread,
    conversationId: convoId,
    roomId: computedRoomId,
  );

  //   log("✅ initial read receipts emitted: $unread (roomId=$computedRoomId)");
}

void scrollToBottom(ScrollController scrollController,void Function(void Function()) setState,  bool showScrollToBottomButton) {
  if (!scrollController.hasClients) return;

  scrollController.animateTo(
    0.0,
    duration: const Duration(milliseconds: 250),
    curve: Curves.easeOut,
  );

  setState(() {
    showScrollToBottomButton = false;
  });
}

Map<String, dynamic> resolveReplySource(Map<String, dynamic> message) {
  return message;
}

//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

void updateNotifierFromAll({
  required List<Map<String, dynamic>> allMessages,
  required  ValueNotifier<List<Map<String, dynamic>>> messagesNotifier,
}) {
  final int total = allMessages.length;

  if (total == 0) {
    messagesNotifier.value = const [];
    return;
  }

  final visibleSlice =
  allMessages.map((msg) => Map<String, dynamic>.from(msg)).toList();

  // ✅ immutable list
  messagesNotifier.value =
  List<Map<String, dynamic>>.unmodifiable(visibleSlice);

  debugPrint('📊 UI now showing: ${messagesNotifier.value.length} messages');
}

void handleIncomingRawMessage({
  String? event,
  required Map<String, dynamic> raw,
  required List<Map<String, dynamic>> allMessages,
  required String currentUserId,
  required DateTime Function(dynamic) parseTime,
  required int visibleCount,
  required void Function() updateNotifierFromAll,
  required bool mounted,
  required ScrollController scrollController,
  required void Function(void Function()) setState,
  required bool showScrollToBottomButton
}) {
  log("lllllllllllllllllllll: $raw");
  try {
    if (raw['isGroupChat'] == true) return;
    final normalized = normalizeMessage(raw);
    if (normalized.isEmpty) {
      debugPrint('⚠️ normalizeMessage returned empty');
      return;
    }

    final realId = normalized['message_id']?.toString();
    if (realId == null || realId.isEmpty) {
      debugPrint('⚠️ No message ID in normalized message');
      return;
    }

    final senderId = normalized['senderId']?.toString();
    final content = normalized['content']?.toString() ?? '';
    final status = normalized['messageStatus']?.toString() ?? '';

    debugPrint(
        '📥 Incoming message: id=$realId, sender=$senderId, content="$content", status="$status"');
    // Check if we already have this message
    final existingIndex = allMessages.indexWhere((m) {
      final mid =
      (m['message_id'] ?? m['messageId'] ?? m['id'] ?? '').toString();
      return mid == realId;
    });

    // If sender is current user, try to find and replace temp message
    if (senderId == currentUserId) {
      bool foundTemp = false;

      // Look for temp message to replace
      for (int i = 0; i < allMessages.length; i++) {
        final m = allMessages[i];
        final isTemp = m['_isTempMessage'] == true;
        final tempContent = (m['content'] ?? '').toString();
        final tempFileName = (m['fileName'] ?? '').toString();

        // 🆕 Enhanced matching: content for text, fileName for files
        final bool contentMatch =
            tempContent == content && content.isNotEmpty;
        final bool fileMatch = tempFileName.isNotEmpty &&
            tempFileName == (normalized['fileName'] ?? '').toString();

        if (isTemp &&
            m['senderId'] == currentUserId &&
            (contentMatch || fileMatch) &&
            (m['messageStatus'] == 'sending' ||
                m['messageStatus'] == 'pending_offline')) {
          debugPrint(
              '🔄 Replacing temp message at index $i with real id $realId');

          // Keep important local data
          final updated = Map<String, dynamic>.from(normalized);
          updated['_isTempMessage'] = false;
          updated['_isOptimistic'] = false;

          // Preserve locals
          if (m['_localHasReply'] == true) {
            updated['_localHasReply'] = true;
            updated['reply'] = m['reply'] ?? m['_localReply'];
            updated['reply_message_id'] = m['reply_message_id'];
          }

          allMessages[i] = updated;
          foundTemp = true;
          break;
        }
      }

      // If no temp found, just add the message
      if (!foundTemp && existingIndex == -1) {
        debugPrint('➕ Adding my own message (no temp found)');
        allMessages.add(normalized);
      } else if (existingIndex != -1) {
        allMessages[existingIndex] = normalized;
      }
    }
    // Message from other user
    else if (existingIndex == -1) {
      debugPrint('➕ Adding message from other user');
      allMessages.add(normalized);
    } else {
      debugPrint('♻️ Updating existing message');
      allMessages[existingIndex] = normalized;
    }

    // Sort messages chronologically
    allMessages.sort((a, b) {
      try {
        final ta = parseTime(a['time']);
        final tb = parseTime(b['time']);
        return ta.compareTo(tb);
      } catch (e) {
        return 0;
      }
    });

    visibleCount = allMessages.length;

    // Update the UI
    updateNotifierFromAll();


    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        scrollToBottom(scrollController,setState,showScrollToBottomButton);

      }
    });
  } catch (e, st) {
    debugPrint('❌ Error in _handleIncomingRawMessage: $e');
    debugPrint('Stack: $st');
  }
}

Future<void> loadCurrentUserId(
{
  required String currentUserId,
  required  MessageHandler? messageHandler,
  required String datumId,
  required String convoId,
  required  void Function() setupMessageListener,
  required  void Function() setupReactionListener,
  required  bool mounted,
  required   void Function(void Function()) setState,

}
    ) async {
  final userId = await UserPreferences.getUserId() ?? '';
  if (userId.isEmpty || (datumId?.isEmpty ?? true)) {
    debugPrint('⚠️ _loadCurrentUserId: missing userId or datumId');
    return;
  }

  currentUserId = userId;
  messageHandler =
      MessageHandler(currentUserId: currentUserId, convoId: convoId);

  setupMessageListener();
  setupReactionListener();

  if (mounted) setState(() {});
}

/// Collect reactions for a message id from all local lists and merge them
List<Map<String, dynamic>> collectMergedReactionsForMessage(
{
  required String messageId,
  required  List<Map<String, dynamic>> dbMessages,
  required  List<Map<String, dynamic>> messages,
  required  List<Map<String, dynamic>> socketMessages,

})
{
  final Map<String, Map<String, dynamic>> byUser = {};

  List<List<Map<String, dynamic>>> sources = [
    dbMessages,
    messages,
    socketMessages
  ];

  for (final list in sources) {
    for (final msg in list) {
      final mid = (msg['message_id'] ?? msg['messageId'] ?? msg['id'] ?? '')
          .toString();
      if (mid != messageId) continue;

      final raw = msg['reactions'];
      if (raw is! List) continue;

      for (final r in raw) {
        if (r is! Map) continue;
        final emoji = (r['emoji'] ?? '').toString();
        if (emoji.isEmpty) continue;

        String? userId = r['userId']?.toString();
        final user = r['user'];
        if ((userId == null || userId.isEmpty) && user is Map) {
          userId = (user['_id'] ?? user['id'] ?? user['userId'])?.toString();
        }
        if (userId == null || userId.isEmpty) continue;

        // Keep latest per user — later sources overwrite earlier ones
        byUser[userId] = {
          'emoji': emoji,
          'userId': userId,
          'user': user is Map ? Map<String, dynamic>.from(user) : null,
          'reacted_at': (r['reacted_at'] ??
              r['createdAt'] ??
              DateTime.now().toIso8601String())
              .toString(),
        };
      }
    }
  }

  // Return list of reactions
  return byUser.values.toList();
}
String normalizeMessageIdForApi(String messageId) {
  if (messageId.isEmpty) return messageId;

  if (messageId.startsWith('forward_')) {
    final parts = messageId.split('_');
    if (parts.length >= 3) {
      return parts[1];
    }
  }
  return messageId;
}
void setupMessageListener({
  required String currentUserId,
  required String datumId,
  required String receiverId,
  required MessagerBloc messagerBloc,
  required  List<Map<String, dynamic>> dbMessages,
  required  List<Map<String, dynamic>> messages,
  required  List<Map<String, dynamic>> socketMessages,
  required  StreamSubscription<Map<String, dynamic>>? statusSubscription,
  required SocketService socketService,
  required bool mounted,
  required  void Function({bool isInitialLoad}) updateNotifier,
  required   void Function() scheduleSaveMessages,
  required   StreamSubscription<dynamic>? messageDeletedSubscription,
  required  void Function(List<String>, {String deleteFor}) markMessagesAsDeleted,
  required  DateTime Function(dynamic) parseTime,
  required  bool Function(Map<String, dynamic>) hasReplyForMessage,
}) {
  if (currentUserId.isEmpty || datumId == null) return;

  messagerBloc.add(ListenToMessages(
      senderId: currentUserId, receiverId: receiverId ?? ""));
  statusSubscription ??=
      socketService.statusUpdateStream.listen((statusUpdate) {
        if (!mounted) return;

        final dynamic rawStatus =
            statusUpdate['messageStatus'] ?? statusUpdate['status'];
        final status = (rawStatus ?? '').toString().trim();
        if (status.isEmpty) return;

        final ids = statusUpdate['messageIds'] ??
            statusUpdate['singleMessageId'] ??
            statusUpdate['messageId'];

        debugPrint('📥 Status update received: $statusUpdate');

        // normalize to List<String>
        final List<String> idList = [];
        if (ids is List) {
          for (final id in ids) {
            if (id != null) idList.add(id.toString());
          }
        } else if (ids != null) {
          idList.add(ids.toString());
        }

        for (final id in idList) {
          // find local message
          final local = getCombinedMessages(dbMessages: dbMessages, messages: messages, socketMessages: socketMessages, parseTime: parseTime, hasReplyForMessage:hasReplyForMessage).firstWhere(
                (m) {
              final mid = normalizeMessageIdForApi(
                  (m['message_id'] ?? m['messageId'] ?? '').toString());
              final incomingIdNormalized = normalizeMessageIdForApi(mid);
              return mid == incomingIdNormalized;
            },
            orElse: () => {},
          );

          final senderId = (local.isNotEmpty)
              ? (local['senderId'] ?? local['sender']?['_id'] ?? local['sender'])
              ?.toString()
              : null;

          // If this status is about a message we sent, avoid treating it as a 'read' coming from remote.
          if (senderId != null && senderId == currentUserId && status == 'read') {
            log("⚠️ Ignoring server 'read' status for my own message id=$id");
            continue;
          }

          // apply update normally

          updateMessageStatus(
              messageId: id,
              status: status,
              messages: messages,
              socketMessages: socketMessages,
              updateNotifier: updateNotifier,
              scheduleSaveMessages: scheduleSaveMessages,
              dbMessages: dbMessages);
        }
      });

  //messgae deleted listener
  messageDeletedSubscription =
      socketService.messageDeletedStream.listen((messageId) {
        log("🗑️ Received message_deleted event for: $messageId");
        markMessagesAsDeleted([messageId], deleteFor: 'everyone');
      });
}