import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:nde_email/presantation/chat/chat_group_Screen/group_model.dart';

abstract class GroupChatEvent extends Equatable {
  const GroupChatEvent();
  @override
  List<Object?> get props => [];
}

class FetchGroupMessages extends GroupChatEvent {
  final String convoId;
  final int page;
  final int limit;
  final void Function(int newMessagesCount)? onMessagesFetched;

  const FetchGroupMessages({
    required this.convoId,
    required this.page,
    required this.limit,
    this.onMessagesFetched,
  });

  @override
  List<Object?> get props => [convoId, page, limit, onMessagesFetched];
}

class ListenToMessages extends GroupChatEvent {
  final String senderId;
  final String receiverId;

  const ListenToMessages({required this.senderId, required this.receiverId});

  @override
  List<Object> get props => [senderId, receiverId];
}

class NewMessageReceived extends GroupChatEvent {
  final GroupMessageResponse message;

  const NewMessageReceived(this.message);

  @override
  List<Object> get props => [message];
}

class PermissionCheck extends GroupChatEvent {
  final String grpId;

  const PermissionCheck(this.grpId);

  @override
  List<Object> get props => [grpId];
}

class SendMessageEvent extends GroupChatEvent {
  final String senderId;
  final String receiverId;
  final String message;
  final String convoId;
  final String contentType;
  final String? mediaUrl;
  final Map<String, dynamic>? replyTo;
  final String? replyMessageId;
  final String? replyGroupMessageCount;

  const SendMessageEvent({
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.convoId,
    this.contentType = 'text',
    this.mediaUrl,
    this.replyTo,
    this.replyMessageId,
    this.replyGroupMessageCount,
  });

  @override
  List<Object?> get props => [
        senderId,
        receiverId,
        message,
        convoId,
        contentType,
        mediaUrl,
        replyTo,
        replyGroupMessageCount
      ];
}

class GrpUploadFileEvent extends GroupChatEvent {
  final File file;
  final String convoId;
  final String senderId;
  final String receiverId;
  final String groupId;
  final String message;
  final bool isGroupMessage;
  final String? groupMessageId;
  final String messageId;
  final String contentType;
  final String? duration;

  const GrpUploadFileEvent({
    required this.file,
    required this.convoId,
    required this.senderId,
    required this.receiverId,
    required this.groupId,
    required this.message,
    this.isGroupMessage = false,
    this.groupMessageId,
    required this.messageId,
    this.contentType = 'file',
    this.duration,
  });

  @override
  List<Object?> get props => [
        file,
        convoId,
        senderId,
        receiverId,
        groupId,
        message,
        isGroupMessage,
        groupMessageId,
        messageId,
        contentType,
        duration,
      ];
}

class ForwardMessageEvent extends GroupChatEvent {
  final String senderId;
  final List<String> receiverIds;
  final String message;
  final String contentType;
  final String originalMessageId;
  final String conversationId;
  final String workspaceId;

  final bool isGroupChat;
  final Map<String, String> currentUserInfo;
  final dynamic file;
  final String? fileName;
  final String? image;

  const ForwardMessageEvent({
    required this.senderId,
    required this.receiverIds,
    required this.message,
    this.contentType = 'text',
    required this.originalMessageId,
    required this.conversationId,
    required this.workspaceId,
    required this.isGroupChat,
    required this.currentUserInfo,
    this.file,
    this.fileName,
    this.image,
  });

  @override
  List<Object?> get props => [
        senderId,
        receiverIds,
        message,
        contentType,
        originalMessageId,
        conversationId,
        workspaceId,
        isGroupChat,
        currentUserInfo,
        file,
        fileName,
        image,
      ];
}

class DeleteMessagesEvent extends GroupChatEvent {
  final List<String> messageIds;
  final String convoId;
  final String senderId;
  final String receiverId;
  final String message;
  final String deleteFor;

  const DeleteMessagesEvent({
    required this.messageIds,
    required this.convoId,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.deleteFor,
  });

  @override
  List<Object> get props =>
      [messageIds, convoId, senderId, receiverId, message, deleteFor];
}

class StarMessagesEvent extends GroupChatEvent {
  final List<String> messageIds;
  final String convoId;

  const StarMessagesEvent({required this.messageIds, required this.convoId});

  @override
  List<Object> get props => [messageIds, convoId];
}

class GroupAddReaction extends GroupChatEvent {
  final String messageId;
  final String conversationId;
  final String emoji;
  final String userId;
  final String receiverId;
  final String? firstName;
  final String? lastName;

  const GroupAddReaction({
    required this.messageId,
    required this.conversationId,
    required this.emoji,
    required this.userId,
    required this.receiverId,
    this.firstName,
    this.lastName,
  });
}

class GroupRemoveReaction extends GroupChatEvent {
  final String messageId;
  final String conversationId;
  final String emoji;
  final String userId;
  final String receiverId;
  final String? firstName;
  final String? lastName;

  const GroupRemoveReaction({
    required this.messageId,
    required this.conversationId,
    required this.emoji,
    required this.userId,
    required this.receiverId,
    this.firstName,
    this.lastName,
  });
}

class FetchGroupDetails extends GroupChatEvent {
  final String groupId;

  const FetchGroupDetails({required this.groupId});

  @override
  List<Object> get props => [groupId];
}
