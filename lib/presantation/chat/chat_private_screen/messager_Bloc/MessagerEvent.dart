import 'package:equatable/equatable.dart';
import '../messager_model.dart';
import 'dart:io';

abstract class MessagerEvent extends Equatable {
  const MessagerEvent();

  @override
  List<Object?> get props => [];
}

class FetchMessagesEvent extends MessagerEvent {
  final String convoId;
  final int page;
  final int limit;
  final void Function(int newMessagesCount)? onMessagesFetched;

  const FetchMessagesEvent({
    required this.convoId,
    required this.page,
    required this.limit,
    this.onMessagesFetched,
  });

  @override
  List<Object?> get props => [convoId, page, limit];
}

class GroupMessagesEvent extends MessagerEvent {
  final String convoId;
  final int page;
  final int limit;
  final String messageType;

  const GroupMessagesEvent(
      {required this.convoId,
      required this.page,
      required this.limit,
      required this.messageType});

  @override
  List<Object?> get props => [convoId, page, limit, messageType];
}

class UploadFileEvent extends MessagerEvent {
  final File file;
  final String convoId;
  final String senderId;
  final String receiverId;
  final String message;
  final bool isGroupMessage;
  final String? groupMesageId;
  final String? contentType;
    final String? messageId;


  const UploadFileEvent(
    this.file,
    this.convoId,
    this.senderId,
    this.receiverId,
    this.message, {
    this.isGroupMessage = false,
    this.groupMesageId, this.contentType,this.messageId
  });

  @override
  List<Object?> get props => [file, senderId, receiverId, message , isGroupMessage , groupMesageId];
}

class SendMessageEvent extends MessagerEvent {
  final String senderId;
  final String receiverId;
  final String message;
  final String convoId;
  final String contentType;
  final String? mediaUrl;
  final Map<String, dynamic>? replyTo;
  final String? clientTempId;
  final String? replyMessageId;
  final String? replyGroupMessageId;
  final bool? replyIsGroupMessage;

  const SendMessageEvent({
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.convoId,
    this.contentType = 'text',
    this.mediaUrl,         // 👈 NEW

    this.replyTo, this.clientTempId, this.replyMessageId,this.replyIsGroupMessage,this.replyGroupMessageId
  });

  @override
  List<Object?> get props =>
      [senderId, receiverId, message, convoId, contentType, mediaUrl, replyTo];
}

class DeleteMessagesEvent extends MessagerEvent {
  final List<String> messageIds;
  final String convoId;
  final String senderId;
  final String receiverId;
  final String message;

  const DeleteMessagesEvent({
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.messageIds,
    required this.convoId,
  });

  @override
  List<Object?> get props => [
        messageIds,
        convoId,
        senderId,
        receiverId,
        message,
      ];
}

class ForwardMessageEvent extends MessagerEvent {
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

// class ForwardMessageEvent extends MessagerEvent {
//   final String message;
//   final String senderId;
//   final List<String> receiverIds;
//   final String originalMessageId;
//   final String conversationId;
//   final String workspaceId;
//   final bool isGroupChat;
//   final Map<String, String> currentUserInfo;
//   final dynamic file;
//   final String? fileName;
//   final String? image;
//   final String contentType;

//   ForwardMessageEvent({
//     required this.message,
//     required this.senderId,
//     required this.receiverIds,
//     required this.originalMessageId,
//     required this.conversationId,
//     required this.workspaceId,
//     required this.isGroupChat,
//     required this.currentUserInfo,
//     this.file,
//     this.fileName,
//     this.image,
//     this.contentType = 'text',
//   });
// }

class AddTemporaryMessageEvent extends MessagerEvent {
  final Message tempmessage;

  const AddTemporaryMessageEvent({required this.tempmessage});
}

class ListenToMessages extends MessagerEvent {
  final String senderId;
  final String receiverId;

  const ListenToMessages({required this.senderId, required this.receiverId});

  @override
  List<Object> get props => [senderId, receiverId];
}

class NewMessageReceived extends MessagerEvent {
  final Map<String, dynamic> message;
  NewMessageReceived(this.message);
}

/// SendImageMessageEvent.............................
class SendImageMessageEvent extends MessagerEvent {
  final String senderId;
  final String receiverId;
  final String imagePath;
  final String convoId;
  final String? caption;
  final int? width;
  final int? height;

  const SendImageMessageEvent({
    required this.senderId,
    required this.receiverId,
    required this.imagePath,
    required this.convoId,
    this.caption,
    this.width,
    this.height,
  });

  @override
  List<Object?> get props =>
      [senderId, receiverId, imagePath, convoId, caption, width, height];
}

///  SendVideoMessageEvent.................................
class SendVideoMessageEvent extends MessagerEvent {
  final String senderId;
  final String receiverId;
  final String videoPath;
  final String convoId;
  final String? caption;
  final Duration duration;
  final String? thumbnailPath;

  const SendVideoMessageEvent({
    required this.senderId,
    required this.receiverId,
    required this.videoPath,
    required this.convoId,
    this.caption,
    required this.duration,
    this.thumbnailPath,
  });

  @override
  List<Object?> get props => [
        senderId,
        receiverId,
        videoPath,
        convoId,
        caption,
        duration,
        thumbnailPath
      ];
}

/// SendDocumentMessageEvent................................
class SendDocumentMessageEvent extends MessagerEvent {
  final String senderId;
  final String receiverId;
  final String documentPath;
  final String convoId;
  final String fileName;
  final int fileSize;
  final String fileType;

  const SendDocumentMessageEvent({
    required this.senderId,
    required this.receiverId,
    required this.documentPath,
    required this.convoId,
    required this.fileName,
    required this.fileSize,
    required this.fileType,
  });

  @override
  List<Object?> get props => [
        senderId,
        receiverId,
        documentPath,
        convoId,
        fileName,
        fileSize,
        fileType
      ];
}

/// SendAudioMessageEvent..................................
class SendAudioMessageEvent extends MessagerEvent {
  final String senderId;
  final String receiverId;
  final String audioPath;
  final String convoId;

  const SendAudioMessageEvent({
    required this.senderId,
    required this.receiverId,
    required this.audioPath,
    required this.convoId,
  });

  @override
  List<Object?> get props => [senderId, receiverId, audioPath, convoId];
}

class AudioMessageSentSuccessfully extends MessagerEvent {
  final String audioUrl;

  const AudioMessageSentSuccessfully(this.audioUrl);

  @override
  List<Object?> get props => [audioUrl];
}

/// StarMessagesEvent for the long press .........................
class StarMessagesEvent extends MessagerEvent {
  final List<String> messageIds;
  final String convoId;

  const StarMessagesEvent({
    required this.messageIds,
    required this.convoId,
  });

  @override
  List<Object?> get props => [messageIds, convoId];
}

// Add to your existing MessagerEvent classes
class AddReaction extends MessagerEvent {
  final String messageId;
  final String conversationId;
  final String emoji;
  final String receiverId;
  final String userId;
  final String? firstName;
  final String? lastName;

  const AddReaction({
    required this.messageId,
    required this.conversationId,
    required this.emoji,
    required this.receiverId,
    required this.userId,
    this.firstName,
    this.lastName,
  });

  @override
  List<Object> get props => [
        messageId,
        conversationId,
        emoji,
        userId,
        receiverId,
        firstName ?? '',
        lastName ?? ''
      ];
}

class RemoveReaction extends MessagerEvent {
  final String messageId;
  final String conversationId;
  final String emoji;
  final String receiverId;
  final String userId;
  final String? firstName;
  final String? lastName;

  const RemoveReaction({
    required this.messageId,
    required this.conversationId,
    required this.emoji,
    required this.receiverId,
    required this.userId,
    this.firstName,
    this.lastName,
  });

  @override
  List<Object> get props => [
        messageId,
        conversationId,
        emoji,
        userId,
        receiverId,
        firstName ?? '',
        lastName ?? ''
      ];
}

class ReactionUpdated extends MessagerEvent {
  final Map<String, dynamic> reactionData;

  const ReactionUpdated(this.reactionData);

  @override
  List<Object?> get props => [reactionData];
}