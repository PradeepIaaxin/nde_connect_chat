abstract class ChatSendEvent {}

class SendReplyMessageEvent extends ChatSendEvent {
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String content;
  final bool isGrpchat;
  final String? grpId ;


  SendReplyMessageEvent({
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.isGrpchat,
    required this.grpId
  });
}
