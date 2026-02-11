
import 'dart:convert';

import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/MessagerBloc.dart';

import '../../../../../../data/respiratory.dart';
import '../../../../../../utils/reusbale/common_import.dart';
import '../../../../chat_list/chat_bloc.dart';
import '../../../../chat_list/chat_event.dart';
import '../../../../chat_list/chat_session_storage/chat_session.dart';
import '../../../localstorage/local_storage.dart';
import '../../../messager_model.dart';
import '../../MessagerState.dart';
import '../../MessagerEvent.dart';
import '../MediaPreviewScreen.dart';


Future<void> saveDraft({
  required String draft,
  required String conversationId,
  required String currentConversationId,
  required ChatListBloc chatListBloc,
}) async {
  final convoId =
  conversationId.isNotEmpty ?conversationId : currentConversationId;
  if (convoId.isEmpty) return;
  await LocalChatStorage.saveDraftMessage(convoId, draft);
  ChatSessionStorage.updateDraftMessage(
    convoId: convoId,
    draftMessage: draft.isEmpty ? null : draft,
  );
  // Trigger UI refresh in chat list
  chatListBloc.add(UpdateLocalChatList());
}

Future<void> clearDraft(
{
  required String conversationId,
  required String currentConversationId,
  required ChatListBloc chatListBloc,
}
    ) async {
  final convoId =
  conversationId.isNotEmpty ?conversationId : currentConversationId;
  if (convoId.isEmpty) return;
  await LocalChatStorage.clearDraftMessage(convoId);
  ChatSessionStorage.updateDraftMessage(
    convoId: convoId,
    draftMessage: null,
  );
  // Trigger UI refresh in chat list
  chatListBloc.add(UpdateLocalChatList());
}



Future<void> flushOfflinePendingMessages({
  required MessagerBloc  messagerBloc,
  required List<Map<String, dynamic>> offlineQueue,
  required String currentUserId,
  required String receiverId,
  required String currentConversationId,
  required void Function(String tempId, String realId, String status)
  replaceTempMessage,
  required void Function(String localId, String status) updateMessageStatus,
})
async {
  if (offlineQueue.isEmpty) return;

  final pending = List<Map<String, dynamic>>.from(offlineQueue);
  offlineQueue.clear();

  for (final item in pending) {
    final text = item['text'] as String;
    final reply = item['reply'];
    final replyMessageId = item['replyMessageId'] as String?;
    final localId = item['localId'] as String;

    try {
      final completer = Completer<Message>();

      late final StreamSubscription subscription;
      subscription = messagerBloc.stream.listen((state) {
        if (state is MessageSentSuccessfully &&
            !completer.isCompleted) {
          completer.complete(state.sentMessage);
        }
      });

      final String? convoId =
      currentConversationId.isEmpty ? null : currentConversationId;

      messagerBloc.add(
        SendMessageEvent(
          convoId: convoId!,
          message: text,
          senderId: currentUserId,
          receiverId: receiverId,
          replyTo: reply!,
          replyMessageId: replyMessageId!,
        ),
      );

      final sent = await completer.future;
      await subscription.cancel();

      replaceTempMessage(
        localId,
        sent.messageId,
        sent.messageStatus,
      );
    } catch (e, st) {
      log('❌ resend offline msg failed: $e\n$st');
      updateMessageStatus(localId, 'failed');
    }
  }
}
void markVisibleMessagesAsRead({
  required bool screenActive,
  required List<Map<String, dynamic>> messages,
  required Set<String> alreadyRead,
  required List<String> Function(List<Map<String, dynamic>> messages)
  getUnreadMessageIds,
  required void Function(String messageId, String status)
  updateMessageStatus,
  required void Function(List<String> messageIds) sendReadReceipts,
}) {
  if (!screenActive) return;

  // 1️⃣ Collect unread message IDs
  final allUnreadIds = getUnreadMessageIds(messages);

  // 2️⃣ Filter already sent
  final idsToSend = allUnreadIds
      .where((id) => id.trim().isNotEmpty && !alreadyRead.contains(id))
      .toList();

  if (idsToSend.isEmpty) return;

  // 3️⃣ Mark locally as read
  for (final id in idsToSend) {
    updateMessageStatus(id, 'read');
  }

  // 4️⃣ Track sent reads
  alreadyRead.addAll(idsToSend);

  // 5️⃣ Send to server/socket
  sendReadReceipts(idsToSend);
}

Future<void> initializeSocket() async {
  final token = await UserPreferences.getAccessToken();
  if (token == null) {
    log("Access token is null. Socket connection not initialized.");
  }
}

bool hasReplyForMessage(Map<String, dynamic> message) {
  if (message['_localHasReply'] == true) return true;

  final replyRaw = message['reply'];
  Map<String, dynamic>? reply;
  if (replyRaw is Map) {
    reply = Map<String, dynamic>.from(replyRaw);
  } else if (replyRaw is String) {
    try {
      final decoded = jsonDecode(replyRaw);
      if (decoded is Map) reply = Map<String, dynamic>.from(decoded);
    } catch (_) {}
  }

  if (reply != null && reply.isNotEmpty) {
    final id = (reply['id'] ??
        reply['message_id'] ??
        reply['messageId'] ??
        reply['reply_message_id'] ??
        reply['_id'])
        ?.toString();

    final replyContent =
    (reply['replyContent'] ?? reply['content'] ?? reply['message'] ?? '')
        .toString();

    final hasMedia = (reply['originalUrl'] ??
        reply['fileUrl'] ??
        reply['imageUrl'] ??
        reply['replyUrl'] ??
        reply['reply_url'] ??
        reply['thumbnailUrl'] ??
        reply['thumbnail_url'])
        ?.toString()
        .isNotEmpty ==
        true;

    if ((id != null && id.isNotEmpty) ||
        replyContent.isNotEmpty ||
        hasMedia) {
      return true;
    }
  }

  final topReplyId = (message['reply_message_id'] ??
      message['replyMessageId'] ??
      message['reply_to'] ??
      message['replyId'] ??
      message['repliedMessageId'])
      ?.toString();
  if (topReplyId != null && topReplyId.isNotEmpty) return true;

  return false;
}

void replaceTempMessageWithReal({
  required String tempId,
  required String realId,
  required String status,
  required List<Map<String, dynamic>> socketMessages,
  required List<Map<String, dynamic>> messages,
  required List<Map<String, dynamic>> dbMessages,
  required List<Map<String, dynamic>> allMessages,
  required Set<String> seenMessageIds,
  required void Function() updateNotifierFromAll,
  required void Function() scheduleSaveMessages,

})
{
  bool changed = false;

  void updateList(List<Map<String, dynamic>> list) {
    for (var i = 0; i < list.length; i++) {
      final m = list[i];
      final mid =
      (m['message_id'] ?? m['messageId'] ?? m['id'] ?? m['_id'] ?? '')
          .toString();

      if (mid == tempId) {
        final copy = Map<String, dynamic>.from(m);

        // 🔥 preserve reply info
        if (copy['reply'] != null || copy['reply_message_id'] != null) {
          copy['_localHasReply'] = true;
          try {
            copy['_localReply'] =
            Map<String, dynamic>.from(copy['reply'] ?? {});
          } catch (_) {
            copy['_localReply'] = copy['reply'];
          }
        }

        // 🔥 preserve grouping
        if (copy['group_message_id'] != null) {
          copy['group_message_id'] = copy['group_message_id']?.toString();
          copy['is_grouped_message'] = copy['is_grouped_message'] == true;
        }

        // 🔥 replace temp id with real id (ALL fields)
        copy['message_id'] = realId;
        copy['messageId'] = realId;
        copy['id'] = realId;
        copy['_id'] = realId;

        // 🔥 update status
        copy['messageStatus'] = status;
        copy['status'] = status;

        // 🔥 mark no longer temp
        copy['_isTempMessage'] = false;
        copy['_isOptimistic'] = false;

        list[i] = copy;
        changed = true;
        break;
      }
    }
  }

  // 🔥 UPDATE ALL STORES
  updateList(socketMessages);
  updateList(messages);
  updateList(dbMessages);
  updateList(allMessages);
  // _audioPlayerService.playMessageSentSound();

  if (changed) {
    seenMessageIds.remove(tempId);
    seenMessageIds.add(realId);

    // 🔥 rebuild UI from single source of truth
    updateNotifierFromAll();
    scheduleSaveMessages();
  }
}

Future<bool> scrollToMessageById(
    String messageId, {
      bool fetchIfMissing = false,
      required Map<String, BuildContext> messageContexts,
      required void Function(BuildContext, String) highlightAndScrollToContext,
      required  ValueNotifier<List<Map<String, dynamic>>> messagesNotifier,
      required ScrollController scrollController,
      required  double Function(int, List<Map<String, dynamic>>) estimateScrollOffset,
      required  void Function(String) highlightMessage,
      required   Future<bool> Function(String) fetchUntilMessageFound,
      required   double Function(int, List<Map<String, dynamic>>) estimateMessageHeight,
    })
async {
  final ctx = messageContexts[messageId];

  if (ctx != null && ctx.mounted) {
    highlightAndScrollToContext(ctx, messageId);
    return true;
  }

  final combinedMessages = messagesNotifier.value;
  final int msgIndex = combinedMessages.indexWhere((m) {
    final mid =
    (m['message_id'] ?? m['messageId'] ?? m['id'] ?? '').toString();
    return mid == messageId;
  });

  if (msgIndex != -1) {
    final int listIndex = combinedMessages.length - 1 - msgIndex;

    final double estimatedOffset =
    estimateScrollOffset(listIndex, combinedMessages);

    if (scrollController.hasClients) {
      scrollController.jumpTo(estimatedOffset.clamp(
        0.0,
        scrollController.position.maxScrollExtent,
      ));
    }

    // Increased delay for better stability
    await Future.delayed(const Duration(milliseconds: 150));

    final targetCtx = messageContexts[messageId];
    if (targetCtx != null && targetCtx.mounted) {
      highlightAndScrollToContext(targetCtx, messageId);
      return true;
    }

    double currentEstimate = estimatedOffset;
    // Increased retries and delay
    for (int attempt = 0; attempt < 5; attempt++) {
      await Future.delayed(const Duration(milliseconds: 100));

      final targetCtx = messageContexts[messageId];
      if (targetCtx != null && targetCtx.mounted) {
        highlightAndScrollToContext(targetCtx, messageId);
        return true;
      }

      int? closestVisibleIndex;
      double minDiff = double.infinity;

      for (final entry in messageContexts.entries) {
        final ctx = entry.value;
        if (ctx.mounted) {
          final idx = combinedMessages.indexWhere((m) {
            final mid = (m['message_id'] ?? m['messageId'] ?? m['id'] ?? '')
                .toString();
            return mid == entry.key;
          });

          if (idx != -1) {
            final diff = (idx - msgIndex).abs().toDouble();
            if (diff < minDiff) {
              minDiff = diff;
              closestVisibleIndex = idx;
            }
          }
        }
      }

      if (closestVisibleIndex != null) {
        final int indexDiff = msgIndex - closestVisibleIndex;

        double correction = 0;
        final int start = indexDiff > 0 ? closestVisibleIndex : msgIndex;
        final int end = indexDiff > 0 ? msgIndex : closestVisibleIndex;

        for (int k = start; k < end; k++) {
          correction += estimateMessageHeight(k, combinedMessages);
        }

        if (indexDiff < 0) correction = -correction;

        currentEstimate += correction;
        if (scrollController.hasClients) {
          scrollController.jumpTo(currentEstimate.clamp(
            0.0,
            scrollController.position.maxScrollExtent,
          ));
        }
      } else {
        break;
      }
    }

    final finalCtx = messageContexts[messageId];
    if (finalCtx != null && finalCtx.mounted) {
      highlightAndScrollToContext(finalCtx, messageId);
      return true;
    }

    highlightMessage(messageId);
    return true;
  }

  if (fetchIfMissing) {
    final found = await fetchUntilMessageFound(messageId);
    if (found) {
      return scrollToMessageById(
        messageId,
        fetchIfMissing: false,
        messageContexts: messageContexts,
        highlightAndScrollToContext: highlightAndScrollToContext,
        messagesNotifier: messagesNotifier,
        scrollController: scrollController,
        estimateScrollOffset: estimateScrollOffset,
        highlightMessage: highlightMessage,
        fetchUntilMessageFound: fetchUntilMessageFound,
        estimateMessageHeight: estimateMessageHeight,
      );
    }
    return false;
  }

  return false;
}

Future<void> openCamera(
{
 required BuildContext context,
  required String convoId,
  required String currentUserId,
  required String receiverId,
  required  void Function(void Function()) setState,
  required  List<Map<String, dynamic>> socketMessages,
  required  Set<String> seenMessageIds,
  required   void Function({bool isInitialLoad}) updateNotifier,
  required   void Function() scheduleSaveMessages,
  required   void Function() scrollToBottom,
}
    ) async {
  try {
    final XFile? file =
    await ImagePicker().pickImage(source: ImageSource.camera);

    if (file == null) return;

    // Open preview screen (like Gallery does)
    final localMessages = await Navigator.push<List<Map<String, dynamic>>>(
      context,
      MaterialPageRoute(
        builder: (_) => MediaPreviewScreen(
          files: [file],
          conversationId: convoId,
          senderId: currentUserId,
          receiverId: receiverId,
          isGroupChat: false,
        ),
      ),
    );

    // Add messages to UI when user confirms send
    if (localMessages != null && localMessages.isNotEmpty) {
      setState(() {
        socketMessages.addAll(localMessages);
        for (var msg in localMessages) {
          final id = (msg['message_id'] ?? '').toString();
          if (id.isNotEmpty) seenMessageIds.add(id);
        }
      });

      updateNotifier();
      scheduleSaveMessages();

      // _audioPlayerService.playMessageSentSound();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        scrollToBottom();
      });
    }
  } catch (e) {
    log('❌ Error opening camera: $e');
    Messenger.alert(msg: "Could not open camera.");
  }
}

String anyId(Map<String, dynamic> m) {
  final candidates = [
    m['message_id'],
    m['messageId'],
    m['id'],
    m['_id'],
    m['reply_message_id'],
    m['replyMessageId'],
    if (m['reply'] is Map) m['reply']['reply_message_id'],
    if (m['reply'] is Map) m['reply']['message_id'],
    if (m['reply'] is Map) m['reply']['id'],
    if (m['repliedMessage'] is Map) m['repliedMessage']['reply_message_id'],
    if (m['repliedMessage'] is Map) m['repliedMessage']['message_id'],
    if (m['repliedMessage'] is Map) m['repliedMessage']['id'],
  ];

  for (final c in candidates) {
    if (c != null && c.toString().isNotEmpty) {
      return c.toString();
    }
  }
  return '';
}



