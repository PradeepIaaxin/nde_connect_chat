import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/widget/privat_common_funtions/privat_chat_funtions.dart';
import '../../../../../../utils/const/consts.dart';
import '../../../../../../utils/snackbar/snackbar.dart';
import '../../../../widget/reation_bottom.dart';
import '../double_tick_ui.dart';
import '../message_ui.dart';

Map<String, dynamic>? resolveReplyOriginal(
    Map<String, dynamic> message,
    List<Map<String, dynamic>> allMessages,
    )
{
  final reply = message['reply'];

  final replyId =
      reply?['message_id'] ?? reply?['id'] ?? message['reply_message_id'];

  if (replyId == null) return null;

  for (final m in allMessages) {
    final id = (m['message_id'] ?? m['id'] ?? m['_id'] ?? m['messageId'])
        ?.toString();

    if (id == replyId.toString()) {
      return _mapReplyWithReplyPayload(m, reply);
    }
  }

  return null;
}

Map<String, dynamic> _mapReplyWithReplyPayload(
    Map<String, dynamic> original,
    Map<String, dynamic>? replyPayload,
    )
{
  String replyText = (replyPayload?['replyContent'] ??
      replyPayload?['content'] ??
      original['replyContent'] ??
      original['content'] ??
      '')
      .toString()
      .trim();
  log("replyPayload?['group_message_id'] ${replyPayload?['group_message_id']}");
  return {
    'replyContent': replyText,
    'content': replyText,
    'imageUrl': original['imageUrl'],
    'fileUrl': original['fileUrl'],
    'originalUrl': original['originalUrl'],
    'fileName': original['fileName'],
    'fileType': original['fileType'],
    'mimeType': original['mimeType'],
    'group_message_id': replyPayload?['group_message_id'],
    'is_grouped_message': replyPayload?['is_grouped_message'] ?? false,
  };
}

// ------------------ UI builders ------------------
Widget buildMessageBubble(
    {
     required Map<String, dynamic> message,
      required bool isSentByMe,
      required bool isReply,
      required bool mounted,
      required String? Function(Map<String, dynamic>) getMessageSenderId,
      required String currentUserId,
      required  List<Map<String, dynamic>> allMessages,
      required  Map<String, BuildContext> messageContexts,
      required bool isSelectionMode,
      required Set<String> selectedMessageKeys,
      required bool showSearchAppBar,
      required  List<Map<String, dynamic>> selectedMessages,
      required String convoId,
      required String receiverId,
      required String firstname,
      required String lastname,
      required  TextEditingController searchController,
      required   List<String> recentEmojis,
      required  void Function(void Function()) setState,
      required  String Function(Map<String, dynamic>) generateMessageKey,
      required  void Function(Map<String, dynamic>) onMessageTap,
      required  void Function(Map<String, dynamic>) onMessageLongPress,
      required   void Function(Map<String, dynamic>, {bool isSendMe}) replyToMessage,
      required   void Function(String, String?) openFile,
      required   Widget Function(Map<String, dynamic>, bool) buildReactionsBar,
      required   List<Map<String, dynamic>> Function() getCombinedMessages,
      required   void Function(Map<String, dynamic>, String) handleReactionTap,
      required  void Function(String) highlightMessage,
      required  void Function(BuildContext, String) highlightAndScrollToContext,
      required  ValueNotifier<List<Map<String, dynamic>>> messagesNotifier,
      required ScrollController scrollController,
      required  double Function(int, List<Map<String, dynamic>>) estimateScrollOffset,
      required   Future<bool> Function(String) fetchUntilMessageFound,
      required   double Function(int, List<Map<String, dynamic>>) estimateMessageHeight,

      int? length
    })
{
  final String? bubbleSenderId = message["sender"]?["_id"]??"";
  final bool correctIsSentByMe = bubbleSenderId == currentUserId;

  isSentByMe = correctIsSentByMe;
log("correctIsSentByMe $currentUserId");
log("correctIsSentByMe $bubbleSenderId");
  // Handle deleted message display
  Map<String, dynamic> displayMessage = message;
  if (message['is_deleted'] == true) {
    displayMessage = Map<String, dynamic>.from(message);
    displayMessage['content'] = "🚫 This message was deleted";
    displayMessage['imageUrl'] = "";
    displayMessage['fileUrl'] = "";
    displayMessage['fileName'] = "";
    displayMessage['originalUrl'] = "";
    displayMessage['messageStatus'] = 'deleted';
  }

  final resolved = resolveReplyOriginal(message, allMessages);

  final bubbleMessage = {
    ...displayMessage,
    'resolvedReply': resolved,
  };
  final messageId =
  (message['message_id'] ?? message['messageId'] ?? message['id'] ?? '')
      .toString();
  int replyMediaCount = 0;
  final replyData = message['reply'] ?? message['repliedMessage'];
  if (replyData != null) {
    final String? replyGroupId = replyData['group_message_id']?.toString();
    if (replyGroupId != null && replyGroupId.isNotEmpty) {
      replyMediaCount = allMessages
          .where((m) =>
      m['group_message_id']?.toString() == replyGroupId &&
          m['is_deleted'] != true)
          .length;
    }

    if (replyMediaCount == 0) {
      replyMediaCount = ((replyData['imageCount'] ?? 0) as int) +
          ((replyData['videoCount'] ?? 0) as int);
    }
  }

  return Builder(builder: (context) {
    // Register context for scrolling
    if (messageId.isNotEmpty) {
      messageContexts[messageId] = context;
    }

    return MessageBubble(
      key: ValueKey(generateMessageKey(message)),
      isSelectionMode: isSelectionMode,
      message: bubbleMessage,
      isSentByMe: correctIsSentByMe,
      //   isSelected: _selectedMessageKeys.contains(_generateMessageKey(message)),
      isSelected: selectedMessageKeys.contains(generateMessageKey(message)),
      onTap: () => onMessageTap(message),
      onLongPress: () => onMessageLongPress(message),
      onRightSwipe: message['is_deleted'] == true
          ? null
          : () => replyToMessage(message),
      onFileTap: (url, type) => openFile(url, type),
      buildStatusIcon: (status) => MessageStatusIcon(status: status),
      buildReactionsBar: (msg, sentByMe) => buildReactionsBar(msg, sentByMe),
      sentMessageColor: senderColor,
      receivedMessageColor: receiverColor,
      selectedMessageColor: senderColor.withOpacity(0.2),
      borderColor: Colors.blue,
      chatColor: chatColor,
      onReact: (msg, emoji) {
        setState(() {
          handleReactionTap(msg, emoji);
          showSearchAppBar = false;
          isSelectionMode = false;
          selectedMessages.clear();
          selectedMessageKeys.clear();
        });
      },
      emojpicker: () => ReactionDialog.show(
        context: context,
        messageId: message['message_id']?.toString() ?? '',
        reactions: message['reactions'] as List<Map<String, dynamic>>? ?? [],
        currentUserId: currentUserId,
        convoId:convoId,
        receiverId:receiverId ?? "",
        firstName: firstname ?? "",
        lastName:lastname ?? "",
      ),
      isReply: isReply,
      onReplyTap: () {
        final replyId = (message['reply']?['reply_message_id'] ??
            message['reply']?['message_id'] ??
            message['reply']?['id'] ??
            message['repliedMessage']?['reply_message_id'] ??
            message['repliedMessage']?['message_id'] ??
            message['repliedMessage']?['id'] ??
            message['reply_message_id'] ??
            message['replyMessageId'])
            ?.toString();

        if (replyId != null && replyId.isNotEmpty) {
          highlightMessage(replyId);
          scrollToMessageById(replyId!,fetchIfMissing: true,messageContexts:messageContexts, highlightAndScrollToContext: highlightAndScrollToContext, messagesNotifier: messagesNotifier, scrollController: scrollController, estimateScrollOffset:   estimateScrollOffset, highlightMessage:  highlightMessage, fetchUntilMessageFound:  fetchUntilMessageFound, estimateMessageHeight: estimateMessageHeight).then((found) {
            if (!found && mounted) {
              Messenger.alert(
                msg:
                "Original message not loaded. Scroll up to load older messages.",
              );
            }
          }).catchError((error) {
            debugPrint('Error scrolling to message: $error');
          });
        }
      },
      groupMediaLength: replyMediaCount > 0 ? replyMediaCount : length,
      allMessages: getCombinedMessages(),
      stretchReply: true,
      searchText: searchController.text,
      recentEmojis: recentEmojis,
      onEmojiUpdated: (list) {
        setState(() => recentEmojis = list);
      },
      currentUserId: currentUserId,

      //isHighlighted: messageId == _highlightedMessageId,
    );
  });
}



