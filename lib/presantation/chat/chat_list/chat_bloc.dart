import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:nde_email/bridge_generated.dart/api.dart';
import 'package:nde_email/convo_list_crdt.dart';
import 'package:nde_email/data/respiratory.dart';
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
      final updatedList =
          ChatSessionStorage.getChatList().map((c) => c.copyWith()).toList();
      _applyDrafts(updatedList);

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
        //   paginationData: PaginationData(
        //     totalDocs: updatedList.length,
        //     page: 1,
        //     limit: updatedList.length,
        //     totalPages: 1,
        //   ),
        //   page: 1,
      ));
    });

    _setupSocketListeners();
  }

  // void _setupSocketListeners() {
  //   socketService.setChatListUpdateCallback((socketChats) {
  //     ChatSessionStorage.clear();
  //     add(ChatListUpdated(chats: socketChats));
  //   });
  // }

  void _setupSocketListeners() {
    socketService.setChatListUpdateCallback((chats) {
      add(ChatListUpdated(chats: chats));
    });
  }

  // void _setupSocketListeners() {
  //   socketService.setChatListUpdateCallback((chats) {
  //     final updated = List<Datu>.from(chats);
  //     _applyDrafts(updated);
  //     _sortChats(updated);
  //     add(ChatListUpdated(chats: updated));
  //   });
  // }

  void _sortChats(List<Datu> chats) {
    chats.sort((a, b) {
      if ((a.isPinned ?? false) && !(b.isPinned ?? false)) return -1;
      if (!(a.isPinned ?? false) && (b.isPinned ?? false)) return 1;

      final aTime = a.lastMessageTime ?? DateTime(2000);
      final bTime = b.lastMessageTime ?? DateTime(2000);
      return bTime.compareTo(aTime);
    });
  }

  void _applyDrafts(List<Datu> chats) {
    for (final chat in chats) {
      String? draft;

      if (chat.isGroupChat == true && chat.conversationId != null) {
        draft = GrpLocalChatStorage.getDraftMessage(chat.conversationId!);
      } else if (chat.id != null) {
        draft = LocalChatStorage.getDraftMessage(chat.id!);
      }

      chat.draftMessage = (draft?.isNotEmpty == true) ? draft : null;
    }
  }

  /// ⚡ Show cached chats instantly (no loading UI)
  void _onSetLocalChatList(
      SetLocalChatList event, Emitter<ChatListState> emit) {
    if (event.chats.isEmpty) return;

    final chats = event.chats.map((c) => c.copyWith()).toList();
    _applyDrafts(chats);

    // Save cache again (optional)
    ChatSessionStorage.clear();
    ChatSessionStorage.saveChatList(event.chats);

    emit(ChatListLoaded(
      chats: chats,
    ));
  }

  Future<void> _onFetchChatList(
    FetchChatList event,
    Emitter<ChatListState> emit,
  ) async {
    if (state is! ChatListLoaded) {
      emit(ChatListLoading());
    }

    try {
      final userId = await UserPreferences.getUserId();
      if (userId == null) {
        emit(ChatListError("User not found"));
        return;
      }

      // ======================================================
      // 1️⃣ OFFLINE-FIRST → LOAD FROM HIVE (CRDT SNAPSHOT)
      // ======================================================
      final box = await Hive.openBox<ConvoListCrdt>('convo_crdt');
      final local = box.get(userId);

      bool loadedFromCrdt = false;

      if (local != null && local.snapshot.isNotEmpty) {
        final jsonString = await importChatUpdate(
          updateBytes: local.snapshot,
        );

        final decoded = jsonDecode(jsonString);
       //log("chataNameLIst ${decoded}");
        final List list = decoded['chatDataList'] ?? [];

        final chats = list.map<Datu>((e) => Datu.fromJson(e)).toList();
        _applyDrafts(chats);

        ChatSessionStorage.saveChatList(chats);

        emit(ChatListLoaded(chats: chats));
        loadedFromCrdt = true;
      }

      // ======================================================
      // 2️⃣ INITIALIZE SOCKET
      // 👉 convoList:sync WILL HAPPEN INSIDE SocketService
      // ======================================================
      await SocketService().initialize();

      // ======================================================
      // 3️⃣ FALLBACK → REST API (ONLY FIRST TIME, NO CRDT)
      // ======================================================
      if (!loadedFromCrdt) {
        final chats = await apiService.fetchChats(
          page: event.page,
          limit: event.limit,
          filter: event.filter,
        );
        _applyDrafts(chats);
        ChatSessionStorage.saveChatList(chats);

        emit(ChatListLoaded(chats: chats));
      }
    } catch (e) {
      emit(ChatListError("Failed to load chats"));
    }
  }

  void _onChatListUpdated(ChatListUpdated event, Emitter<ChatListState> emit) {
    if (event.chats.isEmpty) return;

    ChatSessionStorage.mergeChatList(event.chats);

    // final chats = List<Datu>.from(ChatSessionStorage.getChatList());
    final chats =
        ChatSessionStorage.getChatList().map((c) => c.copyWith()).toList();

    _applyDrafts(chats);
    _sortChats(chats);

    emit(ChatListLoaded(chats: chats));
  }

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
}
