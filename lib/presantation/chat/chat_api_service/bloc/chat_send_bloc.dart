import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/chat/chat_api_service/service/chat_api_service.dart';
import 'chat_send_event.dart';
import 'chat_send_state.dart';

class ChatSendBloc extends Bloc<ChatSendEvent, ChatSendState> {
  final ChatApiService apiService;

  ChatSendBloc(this.apiService) : super(ChatSendInitial()) {
    on<SendReplyMessageEvent>(_sendReply);
  }

  Future<void> _sendReply(
      SendReplyMessageEvent event, Emitter<ChatSendState> emit) async {
    emit(ChatSendLoading());
    try {
      await apiService.sendMessage(
          conversationId: event.conversationId,
          senderId: event.senderId,
          receiverId: event.receiverId,
          content: event.content,
          isGrpchat: event.isGrpchat,
          grpId: event.grpId);
      emit(ChatSendSuccess());
    } catch (e) {
      emit(ChatSendError(e.toString()));
    }
  }
}
