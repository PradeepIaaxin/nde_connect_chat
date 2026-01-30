abstract class ChatSendState {}

class ChatSendInitial extends ChatSendState {}

class ChatSendLoading extends ChatSendState {}

class ChatSendSuccess extends ChatSendState {}

class ChatSendError extends ChatSendState {
  final String message;
  ChatSendError(this.message);
}
