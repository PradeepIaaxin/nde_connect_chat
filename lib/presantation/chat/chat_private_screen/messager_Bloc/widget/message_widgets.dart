import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/widget/privat_common_funtions/privat_chat_funtions.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/messager_Bloc/widget/privat_common_funtions/privat_chat_funtions_2.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../../utils/datetime/date_time_utils.dart';
import '../../../../../utils/router/router.dart';
import '../../../../widgets/chat_widgets/Common/grouped_media_viewer.dart';
import '../../../../widgets/chat_widgets/Common/whatsapp_swipe_to_reply.dart';
import '../../../../widgets/chat_widgets/messager_Wifgets/ForwardMessageScreen_widget.dart';
import '../../../widget/reation_bottom.dart';
import 'MixedMediaViewer.dart';
import 'commonfuntion.dart';
import 'date_separate.dart';
import 'double_tick_ui.dart';

class MessageWidgets extends StatelessWidget {
  final bool isLoadingMore;
  final List<Map<String, dynamic>> groupedMessages;
  final  ScrollController scrollController;
  final Function(Map<String, dynamic>) getMessageSenderId;
  final String? highlightedMessageId;
  final Map<String, BuildContext>? messageContexts;
   final String currentUser;
  final String currentUserId;
  final bool isSentMe;
  final Widget Function({
    required int length,
  required Map<String, dynamic> message,
  required bool isSentByMe,
  required bool isReply,
  }) buildMessageBubble;
  final DateTime Function(dynamic) parseTime;
  final bool isSelectionMode;
  final TextEditingController searchController;
  final Set<String> selectedMessageKeys;
  final  Function(Map<String, dynamic>) generateMessageKey;
   final List<String> recentEmojis;
  final bool showSearchAppBar;
  final List<Map<String, dynamic>> selectedMessages;
  final String convoId;
  final String receiverId;
  final String firstname;
  final String lastname;
  final void Function(List<Map<String, dynamic>>) selectGroupedMessages;
  final void Function(void Function()) setState;
  final Widget Function(Map<String, dynamic>, bool)
  buildReactionsBar;
  final void Function(String senderId, bool isSentByMe) onMessageOwnerResolved;
  final Map<String, dynamic> Function(List<Map<String, dynamic>>, bool, String) buildReplyPreviewFromGroup;
  final void Function(List<String>) onRecentEmojisChanged;
  final void Function(Map<String, dynamic> msg, String emoji)
  onReactionSelected;
  final void Function(
      Map<String, dynamic> replyMessage,
      Map<String, dynamic> replyPreview,
      ) onReplySelected;
  final void Function(
      Map<String, dynamic> message,
      bool isSentByMe,
      ) onReplyRequested;

  const MessageWidgets({super.key, required this.isLoadingMore, required this.groupedMessages, required this.scrollController, required this.getMessageSenderId,required this.highlightedMessageId, required this.messageContexts, required this.currentUser, required this.currentUserId, required this.isSentMe, required this.buildMessageBubble, required this.parseTime, required this.isSelectionMode, required this.searchController, required this.selectedMessageKeys, required this.generateMessageKey, required this.recentEmojis, required this.showSearchAppBar, required this.selectedMessages, required this.convoId, required this.receiverId, required this.firstname, required this.lastname, required this.selectGroupedMessages, required this.setState, required this.buildReactionsBar, required this.onRecentEmojisChanged, required this.onReactionSelected, required this.onReplySelected, required this.buildReplyPreviewFromGroup, required this.onReplyRequested, required this.onMessageOwnerResolved});

  @override
  Widget build(BuildContext context) {
    String? CurrentUser = currentUser;
    bool? isendMe = isSentMe;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: isLoadingMore
                ? Padding(
              key: const ValueKey('top_loader'),
              padding: const EdgeInsets.symmetric(
                  vertical: 8.0),
              child: const SizedBox.shrink(),
            )
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ListView.builder(
                controller: scrollController,
                itemCount: groupedMessages.length,
                reverse: true,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  // final message = combinedMessages[index];
                  final int realIndex =
                      groupedMessages.length - 1 - index;
                  final message = groupedMessages[realIndex];
                  //     log("messagessssssssssssssssssssssssss $message");
                  final String? senderId =
                  getMessageSenderId(message);

                  final messageId = (message['message_id'] ??
                      message['messageId'] ??
                      message['id'] ??
                      '')
                      .toString();
                  log("messageId $messageId");
                  log("currentid $currentUserId");

                  final bool isHighlighted =
                      highlightedMessageId == messageId ||
                          (message['is_grouped_message'] ==
                              true &&
                              message['group_message_id'] !=
                                  null &&
                              highlightedMessageId != null &&
                              groupedMessages.any((m) =>
                              m['group_message_id']
                                  ?.toString() ==
                                  message['group_message_id']
                                      ?.toString() &&
                                  anyId(m)?.toString() ==
                                      highlightedMessageId));
                  final List<GroupMediaItem> groupMedia = [];

                  // 🔥 FIX: Properly determine if message is sent by current user
                  final bool isSentByMe =
                      senderId == currentUserId &&
                          senderId != null &&
                          senderId.isNotEmpty;
                  CurrentUser = senderId;
                  isendMe = isSentByMe;

                  log("isendme $isSentByMe");
                  onMessageOwnerResolved(senderId ?? "", isSentByMe);
                  // Debug logging (remove after fixing)
                  if (senderId != null) {}

                  final showDate = realIndex == 0 ||
                      !isSameDay(
                        parseTime(message['time']),
                        parseTime(
                            groupedMessages[realIndex - 1]
                            ['time']),
                      );
                  final isGroupMessage =
                      message['is_grouped_message'] == true;
                  final groupMessageId =
                  message['group_message_id']?.toString();

                  if (message['is_grouped_message'] == true &&
                      message['group_message_id'] != null &&
                      message['group_message_id']
                          .toString()
                          .isNotEmpty) {
                    // Is this the first message in the group?
                    final isFirstInGroup = realIndex == 0 ||
                        groupedMessages[realIndex - 1]
                        ['group_message_id']
                            ?.toString() !=
                            groupMessageId;

                    // Skip non-first items
                    if (!isFirstInGroup) {
                      return const SizedBox.shrink();
                    }

                    for (int i = realIndex;
                    i < groupedMessages.length;
                    i++) {
                      final nextMsg = groupedMessages[i];
                      final nextGrpId =
                      nextMsg['group_message_id']
                          ?.toString();
                      if (nextGrpId != groupMessageId) break;

                      final String? previewUrl =
                          nextMsg['originalUrl']?.toString() ??
                              nextMsg['imageUrl']?.toString() ??
                              nextMsg['localImagePath']
                                  ?.toString();
                      final String? mediaUrl =
                          nextMsg['originalUrl']?.toString() ??
                              nextMsg['imageUrl']?.toString() ??
                              nextMsg['localImagePath']
                                  ?.toString();

                      final String? fileUrl =
                      nextMsg['fileUrl']?.toString();
                      final String fileType =
                      (nextMsg['fileType'] ??
                          nextMsg['mimeType'] ??
                          '')
                          .toString()
                          .toLowerCase();

                      final bool isVideo = fileType
                          .startsWith('video/') ||
                          (fileUrl != null &&
                              RegExp(r'\.(mp4|mov|mkv|avi|webm)$',
                                  caseSensitive: false)
                                  .hasMatch(fileUrl));
                      final String uniqueId =
                          '${message['message_id']}_${groupMedia.length}';
                      if (!isVideo &&
                          mediaUrl != null &&
                          mediaUrl.isNotEmpty) {
                        groupMedia.add(GroupMediaItem(
                            previewUrl: mediaUrl,
                            mediaUrl: mediaUrl,
                            isVideo: false,
                            uniqueId: uniqueId,
                            message: nextMsg));
                      } else if (isVideo) {
                        final preview =
                            previewUrl ?? fileUrl ?? '';
                        final media = fileUrl ?? mediaUrl ?? '';
                        if (media.isNotEmpty) {
                          groupMedia.add(GroupMediaItem(
                              previewUrl: preview,
                              mediaUrl: media,
                              isVideo: true,
                              uniqueId: uniqueId,
                              message: nextMsg));
                        }
                      }
                    }

                    // Render grouped media if we have any
                    if (groupMedia.isNotEmpty) {
                      return Builder(builder: (ctx) {
                        final groupId =
                        message['group_message_id']
                            ?.toString();
                        final bool? isForwarded =
                            message['isForwarded'] ?? false;
                        final messageId =
                        anyId(message)?.toString();
                        final isReaction =
                            message['reactions'] != null &&
                                (message['reactions'] as List)
                                    .isNotEmpty;
                        final String groupAnchorMessageId =
                            message['message_id'] ??
                                message['id'];

                        if (groupAnchorMessageId.isNotEmpty) {
                          messageContexts![
                          groupAnchorMessageId] =
                              ctx; // 🔥 IMPORTANT
                        } else if (messageId != null &&
                            messageId.isNotEmpty) {
                          messageContexts![messageId] = ctx;
                        }

                        // Register all individual messages in the group
                        for (final item in groupMedia) {
                          final msg = item.message;
                          if (msg != null) {
                            final id = (msg['message_id'] ??
                                msg['messageId'] ??
                                msg['id'])
                                ?.toString();
                            if (id != null && id.isNotEmpty) {
                              messageContexts![id] = ctx;
                            }
                          }
                        }
                        return Column(
                          crossAxisAlignment: isSentByMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            if (showDate)
                              DateSeparator(
                                  dateTime: parseTime(
                                      message['time'])),
                            Padding(
                              padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                  vertical: 4.0),
                              child: GroupedMediaWidget(
                                  isSelectionMode:
                                  isSelectionMode,
                                  searchText:
                                  searchController.text,
                                  onLongPress: () {
                                    final grouped =
                                    getGroupedMessages(
                                        groupedMessages,
                                        realIndex);
                                    selectGroupedMessages(
                                        grouped);
                                  },
                                  selectedMessageColor:
                                  Colors.blue,
                                  isSelected: getGroupedMessages(
                                      groupedMessages, realIndex)
                                      .any((m) => selectedMessageKeys.contains(
                                      generateMessageKey(
                                          m))),
                                  recentEmojis: recentEmojis,
                                  onEmojiUpdated: onRecentEmojisChanged,
                                  buildReactionsBar:
                                      (msg, sentByMe) =>
                                      buildReactionsBar(
                                          msg, sentByMe),
                                  onReact:onReactionSelected,
                                  emojpicker: () =>
                                      ReactionDialog.show(
                                        context: context,
                                        messageId: message[
                                        'message_id']
                                            ?.toString() ??
                                            '',
                                        reactions: message[
                                        'reactions']
                                        as List<
                                            Map<String,
                                                dynamic>>? ??
                                            [],
                                        currentUserId:
                                        currentUserId,
                                        convoId:convoId,
                                        receiverId:
                                       receiverId ??
                                            "",
                                        firstName:
                                        firstname ??
                                            "",
                                        lastName:
                                       lastname ??
                                            "",
                                      ),
                                  message: message,
                                  isForwarded: isForwarded,
                                  isReaction: isReaction,
                                  isHighlighted: isHighlighted,
                                  messageId:
                                  groupAnchorMessageId,
                                  media: groupMedia,
                                  caption: message['content']
                                      ?.toString(),
                                  isSentByMe: isSentByMe,
                                  time: TimeUtils.formatUtcToIst(
                                      message['time']),
                                  messageStatus:
                                  message['messageStatus']?.toString() ?? 'sent',
                                  buildStatusIcon: (status) => MessageStatusIcon(
                                    status: status,
                                    isStatus: true,
                                  ),
                                  onImageTap: (tappedIndex) {
                                    final conversationMedia =
                                    buildConversationMedia(
                                        groupedMessages);
                                    print(
                                        "tappedIndex $tappedIndex");
                                    final tappedItem =
                                    groupMedia[tappedIndex];

                                    final startIndex =
                                    conversationMedia
                                        .indexWhere(
                                          (m) =>
                                      m.mediaUrl ==
                                          tappedItem.mediaUrl,
                                    );

                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        opaque: false,
                                        transitionDuration:
                                        const Duration(
                                            milliseconds:
                                            300),
                                        pageBuilder: (_, __,
                                            ___) =>
                                            MixedMediaViewer(
                                              items:
                                              conversationMedia,
                                              initialIndex:
                                              startIndex < 0
                                                  ? 0
                                                  : startIndex,
                                              currentUserId:
                                              currentUser,
                                              isGroup: false,
                                              conversionalId:
                                             convoId,
                                              receiverId:
                                            receiverId,
                                            ),
                                      ),
                                    );
                                  },
                                  onForwardTap: () {
                                    print(
                                        "realIndexss $realIndex");
                                    log("combinedMessages ${groupedMessages.length}");
                                    final forwardMessages =
                                    getGroupedMessages(
                                        groupedMessages,
                                        realIndex);

                                    print(
                                        "forwardMessagessss ${forwardMessages.length}");
                                    for (final m
                                    in forwardMessages) {
                                      print(
                                          "ITEM TYPE => ${m.runtimeType}");
                                      log("ITEM VALUE => $m");
                                    }

                                    MyRouter.pushReplace(
                                      screen:
                                      ForwardMessageScreen(
                                        messages:
                                        forwardMessages,
                                        currentUserId: message[
                                        'senderId'] ??
                                            '',
                                        conversionalid: "",
                                        username: message[
                                        'senderName'] ??
                                            '',
                                        isForward: isSentByMe,
                                      ),
                                    );
                                  },
                                onRightSwipe: (details) {
                                  final grouped = getGroupedMessages(groupedMessages, realIndex);

                                  final replyPreview = buildReplyPreviewFromGroup(
                                    grouped,
                                    isSentByMe,
                                    currentUserId,
                                  );

                                  onReplySelected(grouped.first, replyPreview);
                                },

                              ),
                            ),
                          ],
                        );
                      });
                    }
                  }
                  final bool hasReaction =
                      message['reactions'] != null &&
                          (message['reactions'] as List)
                              .isNotEmpty;
                  final hasReply = hasReplyForMessage(message);
                  final String? bubbleSenderId =
                  getMessageSenderId(message);
                  final bool correctIsSentByMe =
                      bubbleSenderId == currentUserId &&
                          bubbleSenderId != null &&
                          bubbleSenderId.isNotEmpty;

                  return Builder(builder: (ctx) {
                    final messageId =
                    anyId(message).toString();
                    if (messageId.isNotEmpty) {
                      messageContexts![messageId] = ctx;
                    }
                    final bool isDeleted =
                        message['is_deleted'] == true ||
                            message['messageStatus'] ==
                                'deleted';
                    return SwipeToReply(
                      onReply: isDeleted
                          ? null
                          : () {
                        onReplyRequested(message, isSentByMe);
                      },
                      child: AnimatedContainer(
                          key: ValueKey(messageId),
                          duration:
                          const Duration(milliseconds: 600),
                          curve: Curves.easeOut,
                          margin: EdgeInsets.only(
                            top: hasReply ? 4 : 0,
                            bottom: hasReaction
                                ? (hasReply ? 20 : 5)
                                : (hasReply ? 10 : 0),
                          ),
                          color: isHighlighted
                              ? Colors.blueAccent
                              .withValues(alpha: 0.3)
                              : Colors.transparent,
                          child: Column(
                            crossAxisAlignment:
                            correctIsSentByMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              if (showDate)
                                DateSeparator(
                                    dateTime: parseTime(
                                        message['time'])),
                              buildMessageBubble(
                                message: message,
                                isSentByMe: correctIsSentByMe,
                                isReply: hasReply,
                                  length: groupMedia.length
                              ),
                            ],
                          )),
                    );
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
