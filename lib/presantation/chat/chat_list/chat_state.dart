import 'package:equatable/equatable.dart';
import 'chat_response_model.dart';

abstract class ChatListState extends Equatable {
  const ChatListState();

  @override
  List<Object?> get props => [];
}

class ChatListInitial extends ChatListState {}

class ChatListLoading extends ChatListState {}

class ChatListEmpty extends ChatListState {}

class ChatListError extends ChatListState {
  final String message;

  const ChatListError(this.message);

  @override
  List<Object?> get props => [message];
}

class ChatListLoaded extends ChatListState {
  final List<Datu> chats;
  final PaginationData paginationData;
  final int page;

  const ChatListLoaded({
    required this.chats,
    required this.paginationData,
    required this.page,
  });

  @override
  List<Object?> get props => [chats, paginationData, page];
}

class ArchiveListLoaded extends ChatListState {
  final List<Datu> chats;
  final PaginationData paginationData;
  final int page;
  final bool isArchiveView;

  const ArchiveListLoaded({
    required this.chats,
    required this.paginationData,
    required this.page,
    this.isArchiveView = false,
  });

  ArchiveListLoaded copyWith({
    List<Datu>? chats,
    PaginationData? paginationData,
    int? page,
    bool? isArchiveView,
  }) {
    return ArchiveListLoaded(
      chats: chats ?? this.chats,
      paginationData: paginationData ?? this.paginationData,
      page: page ?? this.page,
      isArchiveView: isArchiveView ?? this.isArchiveView,
    );
  }
}
