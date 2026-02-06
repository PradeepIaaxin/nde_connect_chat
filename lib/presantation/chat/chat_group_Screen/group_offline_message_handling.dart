import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nde_email/presantation/chat/chat_contact_list/local_strorage.dart';
import 'package:nde_email/presantation/chat/chat_group_Screen/group_bloc.dart';
import 'package:nde_email/presantation/chat/chat_group_Screen/group_event.dart';
import 'package:nde_email/presantation/chat/chat_group_Screen/group_model.dart';
import 'package:nde_email/presantation/chat/chat_group_Screen/group_state.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/widget/double_tick_ui.dart';
import 'package:nde_email/presantation/chat/Socket/socket_service.dart';
import 'package:nde_email/utils/snackbar/snackbar.dart';

class GroupOfflineMessageHandler {
  final BuildContext Function() getContext;
  final List<Map<String, dynamic>> Function() getSocketMessages;
  final List<Map<String, dynamic>> Function() getMessages;
  final List<Map<String, dynamic>> Function() getDbMessages;
  final Set<String> Function() getSeenMessageIds;
  final Map<String, String> Function() getPendingStatusUpdates;
  final List<Map<String, dynamic>> Function() getOfflineQueue;
  final bool Function() isOnline;
  final SocketService Function() getSocketService;
  final GroupChatBloc Function() getGroupBloc;
  final String Function() getConversationId;
  final String Function() getCurrentUserId;
  final String Function() getDatumId;
  final void Function(VoidCallback fn) setState;
  final void Function() refreshMessages;
  final List<Map<String, dynamic>> Function() getCombinedMessages;
  final void Function(String messageId, String status) updateMessageStatus;

  GroupOfflineMessageHandler({
    required this.getContext,
    required this.getSocketMessages,
    required this.getMessages,
    required this.getDbMessages,
    required this.getSeenMessageIds,
    required this.getPendingStatusUpdates,
    required this.getOfflineQueue,
    required this.isOnline,
    required this.getSocketService,
    required this.getGroupBloc,
    required this.getConversationId,
    required this.getCurrentUserId,
    required this.getDatumId,
    required this.setState,
    required this.refreshMessages,
    required this.getCombinedMessages,
    required this.updateMessageStatus,
  });

  Widget buildStatusIcon(String status, Map<String, dynamic> message) {
    // Add tap handler for all unsent/pending messages
    // Allow resend/delete for: failed, pending_offline, pending, sending
    if (status == 'failed' ||
        status == 'pending_offline' ||
        status == 'pending' ||
        status == 'sending') {
      return GestureDetector(
        onTap: () => showResendDialog(message),
        child: MessageStatusIcon(status: status),
      );
    }
    return MessageStatusIcon(status: status);
  }

  void showResendDialog(Map<String, dynamic> message) {
    showDialog(
      context: getContext(),
      builder: (context) => AlertDialog(
        title: const Text('Message not sent'),
        content: const Text(
            'This message couldn\'t be sent. Do you want to try again?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              deleteMessage(message);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              resendMessage(message);
            },
            child: const Text('Resend'),
          ),
        ],
      ),
    );
  }

  Future<void> resendMessage(Map<String, dynamic> failedMessage) async {
    final oldMessageId = failedMessage['message_id']?.toString() ?? '';
    final content = failedMessage['content']?.toString() ?? '';

    if (content.isEmpty) return;

    if (!(isOnline() && getSocketService().isConnected)) {
      Messenger.alertError("Cannot resend: No internet or socket disconnected");
      updateMessageStatus(oldMessageId, 'failed');
      return;
    }

    // Update status to sending for the existing message
    updateMessageStatus(oldMessageId, 'sending');

    try {
      // Create a completer to wait for the sent message
      final completer = Completer<GrpMessage>();
      final subscription = getGroupBloc().stream.listen((state) {
        if (state is GrpMessageSentSuccessfully) {
          completer.complete(state.sentMessage);
        } else if (state is GroupChatError) {
          completer.completeError(state.message);
        }
      });

      // Dispatch the send event (this creates a NEW message with NEW ID)
      getGroupBloc().add(
        SendMessageEvent(
          convoId: getConversationId(),
          message: content,
          senderId: getCurrentUserId(),
          receiverId: getDatumId(),
          replyTo: failedMessage['reply'],
        ),
      );

      // Wait for the server response
      final sentMsg = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Resend timed out');
        },
      );
      await subscription.cancel();

      // Replace the old failed message with the new successful one
      replaceTempMessageWithReal(
        tempId: oldMessageId,
        realId: sentMsg.messageId,
        status: 'sent',
      );
    } catch (e) {
      updateMessageStatus(oldMessageId, 'failed');
      if (e is! TimeoutException) {
        Messenger.alertError("Resend failed: $e");
      }
    }
  }

  /// Delete a failed message
  void deleteMessage(Map<String, dynamic> message) {
    final messageId = message['message_id']?.toString() ?? '';

    setState(() {
      getSocketMessages()
          .removeWhere((m) => (m['message_id'] ?? '').toString() == messageId);
      getMessages()
          .removeWhere((m) => (m['message_id'] ?? '').toString() == messageId);
      getDbMessages()
          .removeWhere((m) => (m['message_id'] ?? '').toString() == messageId);

      refreshMessages();
    });

    // Save to storage
    final combined = getCombinedMessages();
    GrpLocalChatStorage.saveMessages(getConversationId(), combined);
  }

  void replaceTempMessageWithReal({
    required String tempId,
    required String realId,
    required String status,
  }) {
    bool changed = false;

    // Check if we have a buffered status update for this realId
    String finalStatus = status;
    final pendingUpdates = getPendingStatusUpdates();
    if (pendingUpdates.containsKey(realId)) {
      final bufferedStatus = pendingUpdates[realId]!;
      // Only apply if buffered status is "better" (e.g. read > delivered > sent)
      // For simplicity, we assume buffered is always newer/better than "sent"
      finalStatus = bufferedStatus;
      pendingUpdates.remove(realId);
    }

    void updateList(List<Map<String, dynamic>> list) {
      for (var i = 0; i < list.length; i++) {
        final m = list[i];
        final mid = (m['message_id'] ?? m['messageId'] ?? '').toString();
        if (mid == tempId) {
          final copy = Map<String, dynamic>.from(m);

          // Assign server id + status
          copy['message_id'] = realId;
          copy['messageStatus'] = finalStatus;

          list[i] = copy;
          changed = true;
          break;
        }
      }
    }

    // Usually optimistic messages are only in socketMessages
    updateList(getSocketMessages());
    updateList(getMessages());
    updateList(getDbMessages());

    if (changed) {
      final seenIds = getSeenMessageIds();
      if (!seenIds.contains(realId)) seenIds.add(realId);
      final combined = getCombinedMessages();
      GrpLocalChatStorage.saveMessages(getConversationId(), combined);
      setState(() {});
      refreshMessages();
    }
  }

  Future<void> flushOfflinePendingMessages() async {
    final offlineQueue = getOfflineQueue();
    if (offlineQueue.isEmpty) return;
    if (!(isOnline() && getSocketService().isConnected)) return;

    final pending = List<Map<String, dynamic>>.from(offlineQueue);
    offlineQueue.clear();

    for (final item in pending) {
      final String? tempId = item['message_id'];
      final String content = item['content'];
      final Map<String, dynamic>? replyTo = item['replyTo'];

      if (tempId == null) continue;

      // Update status to sending for the existing message
      updateMessageStatus(tempId, 'sending');

      try {
        // Create a completer to wait for the sent message
        final completer = Completer<GrpMessage>();
        final subscription = getGroupBloc().stream.listen((state) {
          if (state is GrpMessageSentSuccessfully) {
            completer.complete(state.sentMessage);
          } else if (state is GroupChatError) {
            completer.completeError(state.message);
          }
        });

        // Dispatch the send event (this creates a NEW message with NEW ID)
        getGroupBloc().add(
          SendMessageEvent(
            convoId: getConversationId(),
            message: content,
            senderId: getCurrentUserId(),
            receiverId: getDatumId(),
            replyTo: replyTo,
          ),
        );

        // Wait for the server response
        final sentMsg = await completer.future.timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('Flush timed out');
          },
        );
        await subscription.cancel();

        // Replace the old failed message with the new successful one
        replaceTempMessageWithReal(
          tempId: tempId,
          realId: sentMsg.messageId,
          status: 'sent',
        );
      } catch (e) {
        updateMessageStatus(tempId, 'failed');
      }
    }
  }
}
