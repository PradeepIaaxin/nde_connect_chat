abstract class ChatSendEvent {}

class SendReplyMessageEvent extends ChatSendEvent {
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String content;

  SendReplyMessageEvent({
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.content,
  });
}
