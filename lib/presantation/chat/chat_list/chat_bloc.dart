import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/presantation/chat/Socket/Socket_Service.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/localstorage/local_storage.dart';
import 'package:nde_email/presantation/chat/chat_contact_list/local_strorage.dart';
import 'chat_api.dart';
import 'chat_event.dart';
import 'chat_state.dart';
import 'chat_response_model.dart';
import 'chat_session_storage/chat_session.dart';

class ChatListBloc extends Bloc<ChatListEvent, ChatListState> {
  final ChatListApiService apiService;

  final SocketService socketService;
  StreamSubscription<List<Datu>>? _chatStreamSubscription;

  ChatListBloc({required this.apiService, required this.socketService})
      : super(ChatListInitial()) {
    on<FetchChatList>(_onFetchChatList);
    on<ChatListUpdated>(_onChatListUpdated);
    on<ClearChatList>(_onClearChatList);
    on<SetLocalChatList>(_onSetLocalChatList);
    on<UpdateLocalChatList>((event, emit) {
      //final updatedList = ChatSessionStorage.getChatList();
      final updatedList = List<Datu>.from(ChatSessionStorage.getChatList());

      /// WhatsApp sorting: pinned first, then latest message
      updatedList.sort((a, b) {
        if ((a.isPinned ?? false) && !(b.isPinned ?? false)) return -1;
        if (!(a.isPinned ?? false) && (b.isPinned ?? false)) return 1;

        final aTime = a.lastMessageTime ?? DateTime(2000);
        final bTime = b.lastMessageTime ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });

      emit(ChatListLoaded(
        chats: updatedList,
        paginationData: PaginationData(
          totalDocs: updatedList.length,
          page: 1,
          limit: updatedList.length,
          totalPages: 1,
        ),
        page: 1,
      ));
    });

    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    socketService.setChatListUpdateCallback((socketChats) {
      ChatSessionStorage.clear();
      add(ChatListUpdated(chats: socketChats));
    });
  }

  /// ⚡ Show cached chats instantly (no loading UI)
  void _onSetLocalChatList(
      SetLocalChatList event, Emitter<ChatListState> emit) {
    if (event.chats.isEmpty) return;

    // Merge drafts
    // Merge drafts
    _applyDrafts(event.chats);

    // Save cache again (optional)
    ChatSessionStorage.clear();
    ChatSessionStorage.saveChatList(event.chats);

    final pagination = PaginationData(
      totalDocs: event.chats.length,
      page: 1,
      limit: event.chats.length,
      totalPages: 1,
      nextPage: null,
      prevPage: null,
    );

    emit(ChatListLoaded(
      chats: event.chats,
      paginationData: pagination,
      page: 1,
    ));
  }

  Future<void> _onFetchChatList(
    FetchChatList event,
    Emitter<ChatListState> emit,
  ) async {
    // Show shimmer only when no cached data and no previous state loaded
    if (state is! ChatListLoaded && ChatSessionStorage.getChatList().isEmpty) {
      emit(ChatListLoading());
    }

    try {
      // Normal fetch
      final initialChats = await apiService.fetchChats(
        page: event.page,
        limit: event.limit,
        filter: event.filter,
      );

      // Update state
      add(ChatListUpdated(chats: initialChats));
    } catch (e) {
      emit(ChatListError('Failed to fetch chats: $e'));
    }
  }

  /// 🔁 When new chats come from stream/API updates
  void _onChatListUpdated(ChatListUpdated event, Emitter<ChatListState> emit) {
    if (event.chats.isEmpty) {
      emit(ChatListEmpty());
      return;
    }

    // 🔥 IMPORTANT: clear before saving API/snapshot data
    ChatSessionStorage.clear();
    ChatSessionStorage.saveChatList(event.chats);

    _applyDrafts(ChatSessionStorage.getChatList());

    final chats = List<Datu>.from(ChatSessionStorage.getChatList());

    emit(ChatListLoaded(
      chats: chats,
      paginationData: PaginationData(
        totalDocs: chats.length,
        page: 1,
        limit: chats.length,
        totalPages: 1,
      ),
      page: 1,
    ));
  }

  // void _onChatListUpdated(ChatListUpdated event, Emitter<ChatListState> emit) {
  //   if (event.chats.isEmpty) {
  //     emit(ChatListEmpty());
  //     return;
  //   }

  //   // Merge drafts
  //   // Merge drafts
  //   _applyDrafts(event.chats);

  //   // Save to local cache
  //   ChatSessionStorage.saveChatList(event.chats);

  //   final pagination = PaginationData(
  //     totalDocs: event.chats.length,
  //     page: 1,
  //     limit: event.chats.length,
  //     totalPages: 1,
  //     nextPage: null,
  //     prevPage: null,
  //   );

  //   emit(ChatListLoaded(
  //     chats: event.chats,
  //     paginationData: pagination,
  //     page: pagination.nextPage ?? 1,
  //   ));
  // }

  /// 🧹 Clear
  void _onClearChatList(
      ClearChatList event, Emitter<ChatListState> emit) async {
    await _chatStreamSubscription?.cancel();
    emit(ChatListInitial());
  }

  @override
  Future<void> close() async {
    await _chatStreamSubscription?.cancel();
    apiService.dispose();
    return super.close();
  }

  /// 📝 Helper to apply drafts from local storage
  void _applyDrafts(List<Datu> chats) {
    for (var chat in chats) {
      String? draft;

      if (chat.isGroupChat == true) {
        // For group chats, use conversationId with GrpLocalChatStorage
        if (chat.conversationId != null && chat.conversationId!.isNotEmpty) {
          draft = GrpLocalChatStorage.getDraftMessage(chat.conversationId!);
        }
      } else {
        if (chat.id != null) {
          draft = LocalChatStorage.getDraftMessage(chat.id!);
        }
      }

      if (draft != null && draft.isNotEmpty) {
        chat.draftMessage = draft;
      } else {
        chat.draftMessage = null;
      }
    }
  }
}
