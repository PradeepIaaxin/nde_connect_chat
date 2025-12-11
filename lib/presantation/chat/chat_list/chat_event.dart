// Events
import 'package:equatable/equatable.dart';
import 'package:nde_email/presantation/chat/chat_list/chat_response_model.dart';

abstract class ChatListEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FetchChatList extends ChatListEvent {
  final int page;
  final int limit;
  final String? filter;


  FetchChatList({required this.page, required this.limit, this.filter});

  @override
  List<Object?> get props => [page, limit, filter];
}

class SetLocalChatList extends ChatListEvent {
  final List<Datu> chats;
  SetLocalChatList({required this.chats});
}

class LoadChatListFromSession extends ChatListEvent {}

class ClearChatList extends ChatListEvent {}

class ChatListUpdated extends ChatListEvent {
  final List<Datu> chats;

  ChatListUpdated({required this.chats});

  @override
  List<Object?> get props => [chats];
}

class FetchArchivedChats extends ChatListEvent {}
class UpdateLocalChatList extends ChatListEvent {}