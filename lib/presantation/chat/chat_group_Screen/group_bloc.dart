import 'dart:async';
import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/data/respiratory.dart';
import 'package:nde_email/presantation/chat/Socket/Socket_Service.dart';
import 'package:nde_email/presantation/chat/chat_contact_list/local_strorage.dart';
import 'package:nde_email/presantation/chat/chat_group_Screen/api_servicer.dart';
import 'package:nde_email/presantation/chat/chat_group_Screen/group_event.dart';
import 'package:nde_email/presantation/chat/chat_group_Screen/group_model.dart';
import 'package:nde_email/presantation/chat/chat_group_Screen/group_state.dart';
import 'package:objectid/objectid.dart';
import 'package:nde_email/presantation/chat/model/emoj_model.dart';

class GroupChatBloc extends Bloc<GroupChatEvent, GroupChatState> {
  final SocketService grpSocket;
  final GrpMessagerApiService api;

  late final StreamSubscription<MessageReaction> _reactionSubscription;

  GroupChatBloc(this.grpSocket, this.api) : super(GroupChatInitial()) {
    on<FetchGroupMessages>(_onFetchGroupMessages);
    on<SendMessageEvent>(_onSendMessage);
    on<GrpUploadFileEvent>(_onUploadFile);
    on<DeleteMessagesEvent>(_onDeleteMessage);
    on<GroupAddReaction>(_onGroupAddReaction);
    on<GroupRemoveReaction>(_onGroupRemoveReaction);
    on<ForwardMessageEvent>(_forwardMessage);
    on<PermissionCheck>(_chatPermission);
    on<FetchGroupDetails>(_onFetchGroupDetails);
    // on<ReactionReceived>(_onReactionReceived);

// Listen to reaction stream from SocketService
    // _reactionSubscription = grpSocket.reactionStream.listen((reaction) {
    //   add(ReactionReceived(
    //     messageId: reaction.messageId,
    //     conversationId: reaction.conversationId,
    //     emoji: reaction.emoji,
    //     userId: reaction.user.id,
    //     receiverId: "",
    //     firstName: reaction.user.firstName,
    //     lastName: reaction.user.lastName,
    //   ));
    // });
  }

  @override
  Future<void> close() {
    _reactionSubscription.cancel();
    return super.close();
  }

  // ==========================================================
  //                📌 FETCH GROUPED MESSAGES
  // ==========================================================
  Future<void> _onFetchGroupMessages(
      FetchGroupMessages event, Emitter<GroupChatState> emit) async {
    try {
      List<GroupMessageModel> localMessages = [];
      if (event.page == 1) {
        emit(GroupChatLoading());

        /// Load local stored (flat) messages
        final localMaps = GrpLocalChatStorage.loadMessages(event.convoId);

        localMessages =
            localMaps.map((json) => GroupMessageModel.fromJson(json)).toList();

        if (localMessages.isNotEmpty) {
          emit(GroupChatLoaded(
            GroupMessageResponse(
              data: _groupMessagesByDate(localMessages),
              total: localMessages.length,
              page: 1,
              limit: event.limit,
              hasPreviousPage: false,
              hasNextPage: false,
            ),
          ));

          log("📌 Loaded local cache: ${localMessages.length}");
        }
      }

      // =============================
      // 🔥 Fetch API Grouped Response
      // =============================
      final apiResp = await api.fetchMessages(
        convoId: event.convoId,
        page: event.page,
        limit: event.limit,
      );

      // API returns:
      // data = List<GroupMessageGroup>
      final List<GroupMessageGroup> incomingGroups = apiResp.data;

      // Flatten messages for saving to local
      final flatIncoming =
          incomingGroups.expand((group) => group.messages).toList();

      // 🛠️ FIX: Preserve pending 'sending' messages from local cache that are missing in API
      // Because API sync might be faster than upload + server indexing
      final pendingMessages = localMessages.where((m) {
        return m.messageStatus == 'sending' &&
            !flatIncoming.any((apiMsg) =>
                apiMsg.id == m.id || apiMsg.messageId == m.messageId);
      }).toList();

      if (pendingMessages.isNotEmpty) {
        log("🔄 Providing persistence for ${pendingMessages.length} pending messages");
        flatIncoming.addAll(pendingMessages);

        // Also add to incomingGroups for immediate UI reflection
        // We find the group for "Today" or create it
        final todayLabel = _formatDate(DateTime.now());
        final todayGroupIndex =
            incomingGroups.indexWhere((g) => g.label == todayLabel);

        if (todayGroupIndex != -1) {
          incomingGroups[todayGroupIndex].messages.addAll(pendingMessages);
        } else {
          incomingGroups.insert(0,
              GroupMessageGroup(label: todayLabel, messages: pendingMessages));
        }
      }

      if (flatIncoming.isNotEmpty) {
        await GrpLocalChatStorage.saveMessages(
          event.convoId,
          flatIncoming.map((m) => m.toJson()).toList(),
        );
      }

      // Merge Pages
      if (state is GroupChatLoaded && event.page > 1) {
        final prev = (state as GroupChatLoaded).response;

        // merge groups properly
        final mergedGroups = _mergeGroupedPages(prev.data, incomingGroups);

        emit(GroupChatLoaded(
          GroupMessageResponse(
            data: mergedGroups,
            total: apiResp.total,
            page: apiResp.page,
            limit: apiResp.limit,
            hasPreviousPage: apiResp.hasPreviousPage,
            hasNextPage: apiResp.hasNextPage,
          ),
        ));
      } else {
        emit(GroupChatLoaded(apiResp));
      }
    } catch (e, st) {
      log("❌ FetchGroupMessages Error: $e");
      emit(GroupChatError("Failed to load messages"));
    }
  }

  Stream<GroupChatState> mapEventToState(GroupChatEvent event) async* {
    if (event is PermissionCheck) {
      try {
        final response = await api.checkPermission(grpId: event.grpId);
        yield PermissionState(response);
      } catch (e) {
        yield GroupChatError(e.toString());
      }
    }
  }

  // ==========================================================
  //                📌 MERGE PAGINATION GROUPS
  // ==========================================================
  List<GroupMessageGroup> _mergeGroupedPages(
      List<GroupMessageGroup> oldGroups, List<GroupMessageGroup> newGroups) {
    final Map<String, GroupMessageGroup> groupMap = {
      for (var g in oldGroups) g.label: g
    };

    for (var ng in newGroups) {
      if (groupMap.containsKey(ng.label)) {
        groupMap[ng.label] = GroupMessageGroup(
          label: ng.label,
          messages: [...groupMap[ng.label]!.messages, ...ng.messages],
        );
      } else {
        groupMap[ng.label] = ng;
      }
    }

    final sorted = groupMap.values.toList()
      ..sort((a, b) => a.label.compareTo(b.label));

    return sorted;
  }

  // ==========================================================
  //           📌 BUILD GROUPS FROM LOCAL CACHE
  // ==========================================================
  List<GroupMessageGroup> _groupMessagesByDate(List<GroupMessageModel> list) {
    Map<String, List<GroupMessageModel>> map = {};

    for (var m in list) {
      final label = _formatDate(m.time);
      map.putIfAbsent(label, () => []);
      map[label]!.add(m);
    }

    return map.entries
        .map((e) => GroupMessageGroup(label: e.key, messages: e.value))
        .toList();
  }

  String _formatDate(DateTime dt) {
    return "${dt.year}-${dt.month}-${dt.day}";
  }

  // ==========================================================
  //               📌 SEND MESSAGE
  // ==========================================================
  Future<void> _onSendMessage(
      SendMessageEvent event, Emitter<GroupChatState> emit) async {
    try {
      final workspace = await UserPreferences.getDefaultWorkspace();
      final username = await UserPreferences.getUsername();
      final messageId = ObjectId().toString();

      grpSocket.sendMessage(
        isGroupMessage: false,
        messageId: messageId,
        conversationId: event.convoId,
        senderId: event.senderId,
        receiverId: event.receiverId,
        message: event.message,
        roomId: event.receiverId,
        workspaceId: workspace!,
        isGroupChat: true,
        contentType: event.contentType,
        reply: event.replyTo,
        userName: username!,
      );

      emit(GrpMessageSentSuccessfully(
        GrpMessage(
          messageId: messageId,
          senderId: event.senderId,
          receiverId: event.receiverId,
          message: event.message,
          time: DateTime.now(),
          messageStatus: "sent",
        ),
      ));
    } catch (e) {
      emit(GroupChatError("Failed to send message"));
    }
  }

  Future<void> _onUploadFile(
    GrpUploadFileEvent event,
    Emitter<GroupChatState> emit,
  ) async {
    emit(UploadInProgress(0));

    try {
      await api.uploadFile(
        file: event.file,
        onProgress: (p) => emit(UploadInProgress(p)),
        onSuccess: (data) async {
          final messageId = ObjectId().toString();
          final workspace = await UserPreferences.getDefaultWorkspace();

          // ✅ Correct mapping from backend response
          final payload = {
            "isGroupMessage": event.isGroupMessage,
            "groupMessageId": event.groupMessageId,
            "messageId": messageId,
            "conversationId": event.convoId,
            "senderId": event.senderId,
            "receiverId": event.groupId,
            "message": event.message,
            "roomId": event.groupId,
            "workspaceId": workspace!,
            "isGroupChat": true,
            "contentType": data["fieldname"] ?? "file",
            "mimeType": data["mimetype"] ?? "",
            "fileWithText": false,
            "fileName": data["fileName"] ?? "",
            "size": data["size"] ?? 0,
            "thumbnailKey": data["thumbnail_key"] ?? "",
            "thumbnailUrl": data["thumbnailUrl"] ?? "",
            "originalKey": data["originalKey"] ?? "",
            "originalUrl": data["originalUrl"] ?? "",
          };

          print("=== Sending Group Socket Message ===");
          payload.forEach((key, value) => print("$key : $value"));
          print("===================================");

          grpSocket.sendMessage(
            isGroupMessage: event.isGroupMessage,
            groupMessageId: event.groupMessageId,
            messageId: messageId,
            conversationId: event.convoId,
            senderId: event.senderId,
            receiverId: event.groupId,
            message: event.message,
            roomId: event.groupId,
            workspaceId: workspace,
            isGroupChat: true,
            contentType: data["fieldname"] ?? "file",
            mimeType: data["mimetype"] ?? "",
            fileWithText: false,
            fileName: data["fileName"] ?? "",
            size: data["size"] ?? 0,
            thumbnailKey: data["thumbnail_key"] ?? "",
            thumbnailUrl: data["thumbnailUrl"] ?? "",
            originalKey: data["originalKey"] ?? "",
            originalUrl: data["originalUrl"] ?? "",
          );
        },
        onError: (err) => emit(UploadFailure(err)),
      );
    } catch (e) {
      emit(UploadFailure(e.toString()));
    }
  }

  // ==========================================================
  //           📌 DELETE MESSAGE
  // ==========================================================
  Future<void> _onDeleteMessage(
      DeleteMessagesEvent event, Emitter<GroupChatState> emit) async {
    try {
      for (var id in event.messageIds) {
        grpSocket.deleteMessage(
          messageId: id,
          conversationId: event.convoId,
        );
      }

      emit(GroupChatMessageDeletedSuccessfully(
          deletedMessageIds: event.messageIds));
    } catch (e) {
      emit(GroupChatError("Delete failed"));
    }
  }

  // ==========================================================
  //          📌 ADD / REMOVE REACTION
  // ==========================================================
  Future<void> _onGroupAddReaction(
      GroupAddReaction e, Emitter<GroupChatState> emit) async {
    try {
      if (!e.messageId.startsWith("temp_")) {
        await api.reactionUpdated(
          conversationId: e.conversationId,
          messageId: e.messageId,
          emoji: e.emoji,
          userId: e.userId,
          receiverId: e.receiverId,
        );
      }

      grpSocket.reactToMessage(
        messageId: e.messageId,
        conversationId: e.conversationId,
        emoji: e.emoji,
        userId: e.userId,
        firstName: e.firstName ?? "",
        lastName: e.lastName ?? "",
        receiverId: e.receiverId,
      );
    } catch (_) {}
  }

  Future<void> _onGroupRemoveReaction(
      GroupRemoveReaction e, Emitter<GroupChatState> emit) async {
    try {
      if (!e.messageId.startsWith("temp_")) {
        await api.reactionRemove(
          conversationId: e.conversationId,
          messageId: e.messageId,
          userId: e.userId,
          receiverId: e.receiverId,
        );
      }

      grpSocket.removeReaction(
        messageId: e.messageId,
        conversationId: e.conversationId,
        emoji: e.emoji,
        userId: e.userId,
        firstName: e.firstName ?? "",
        lastName: e.lastName ?? "",
      );
    } catch (_) {}
  }

  // ==========================================================
  //             📌 FORWARD MESSAGE
  // ==========================================================
  Future<void> _forwardMessage(
      ForwardMessageEvent e, Emitter<GroupChatState> emit) async {
    try {
      grpSocket.forwardMessage(
        senderId: e.senderId,
        receiverIds: e.receiverIds,
        originalMessageId: e.originalMessageId,
        messageContent: e.message,
        conversationId: e.conversationId,
        workspaceId: e.workspaceId,
        isGroupChat: e.isGroupChat,
        currentUserInfo: e.currentUserInfo,
        file: e.file,
        fileName: e.fileName,
        image: e.image,
        contentType: e.contentType,
      );
    } catch (e) {
      emit(GroupChatError("Forward failed"));
    }
  }

  // ==========================================================
  //             📌 PERMISSION CHECK
  // ==========================================================
  Future<void> _chatPermission(
      PermissionCheck e, Emitter<GroupChatState> emit) async {
    final res = await api.checkPermission(grpId: e.grpId);

    if (res == null) {
      emit(GroupChatError("Permission check failed"));
      return;
    }

    if (res['type'] == "left") {
      emit(GroupLeftState());
      return;
    }

    if (res['permissions'] != null) {
      emit(GroupPermissionLoaded(
        role: res['role'],
        permissions: Map<String, dynamic>.from(res['permissions']),
        status: res['status'],
      ));
      return;
    }

    emit(GroupChatError("Invalid permission response"));
  }

  Future<void> _onFetchGroupDetails(
      FetchGroupDetails event, Emitter<GroupChatState> emit) async {
    try {
      final details = await api.fetchGroupDetails(event.groupId);
      emit(GroupDetailsLoaded(details));
    } catch (e) {
      log("❌ FetchGroupDetails Error: $e");
      // Don't emit error state to avoid disrupting chat UI, just log it
    }
  }
}
