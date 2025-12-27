import 'dart:async';
import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/data/respiratory.dart';
import 'package:nde_email/presantation/chat/Socket/socket_service.dart';
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
  late final StreamSubscription<Map<String, dynamic>> _crdtSubscription;

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
    _crdtSubscription =
        grpSocket.crdtMessageStream.listen(_onCrdtMessageReceived);
    // on<ReactionReceived>(_onReactionReceived);
  }

  @override
  Future<void> close() {
    _reactionSubscription.cancel();
    _crdtSubscription.cancel();
    return super.close();
  }

  Future<void> _onCrdtMessageReceived(Map<String, dynamic> payload) async {
    try {
      final convoId = payload['conversationId']?.toString();
      if (convoId == null) return;

      // 🔴 CRDT payload does NOT send isGroupChat → REMOVE this check
      // final isGroup = payload['isGroupChat'] == true;
      // if (!isGroup) return;

      final List<GroupMessageModel> existing = [];
      int page = 1;
      int limit = 40;
      bool hasPrev = false;
      bool hasNext = false;

      if (state is GroupChatLoaded) {
        final current = state as GroupChatLoaded;

        existing.addAll(
          current.response.data.expand((g) => g.messages),
        );

        page = current.response.page;
        limit = current.response.limit;
        hasPrev = current.response.hasPreviousPage;
        hasNext = current.response.hasNextPage;
      }

      /// 2️⃣ Decode CRDT messages
      final Map<String, dynamic> messagesMap =
          Map<String, dynamic>.from(payload['messages'] ?? {});
      if (messagesMap.isEmpty) return;

      final incoming = messagesMap.values
          .map(
            (e) => GroupMessageModel.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList();

      /// 3️⃣ MERGE (ID is source of truth)
      final Map<String, GroupMessageModel> merged = {};

      // Existing messages first
      for (final m in existing) {
        final id = m.messageId.isNotEmpty ? m.messageId : m.id;
        if (id.isNotEmpty) {
          merged[id] = m;
        }
      }

      // CRDT overrides
      for (final m in incoming) {
        final id = m.messageId.isNotEmpty ? m.messageId : m.id;
        if (id.isNotEmpty) {
          merged[id] = m;
        }
      }

      /// 4️⃣ SORT by time (Old → New)
      final mergedFlat = merged.values.toList()
        ..sort((a, b) => a.time.compareTo(b.time));

      /// 5️⃣ Persist merged result
      await GrpLocalChatStorage.saveMessages(
        convoId,
        mergedFlat.map((e) => e.toJson()).toList(),
      );

      /// 6️⃣ EMIT UI STATE (THIS TRIGGERS REBUILD)
      emit(
        GroupChatLoaded(
          GroupMessageResponse(
            data: _groupMessagesByDate(mergedFlat),
            total: mergedFlat.length,
            page: page,
            limit: limit,
            hasPreviousPage: hasPrev,
            hasNextPage: hasNext,
          ),
        ),
      );

      log('✅ CRDT merged & emitted → ${mergedFlat.length} messages');
    } catch (e, st) {
      log("❌ GROUP CRDT merge error: $e");
      log(st.toString());
    }
  }

  // Future<void> _onCrdtMessageReceived(Map<String, dynamic> payload) async {
  //   try {
  //     final convoId = payload['conversationId']?.toString();
  //     if (convoId == null) return;

  //     final isGroup = payload['isGroupChat'] == true;
  //     if (!isGroup) return;

  //     if (state is! GroupChatLoaded) return;
  //     final current = state as GroupChatLoaded;

  //     final Map<String, dynamic> messagesMap =
  //         Map<String, dynamic>.from(payload['messages'] ?? {});
  //     if (messagesMap.isEmpty) return;

  //     // 1️⃣ CRDT → models
  //     final incoming = messagesMap.values
  //         .map((e) => GroupMessageModel.fromJson(
  //               Map<String, dynamic>.from(e),
  //             ))
  //         .toList();

  //     // 2️⃣ FLATTEN CURRENT UI (authoritative)
  //     final existing = current.response.data.expand((g) => g.messages).toList();

  //     // 3️⃣ MERGE BY MESSAGE ID
  //     final Map<String, GroupMessageModel> merged = {};

  //     // ✅ Keep existing (socket + optimistic)
  //     for (final m in existing) {
  //       final id = m.messageId.isNotEmpty ? m.messageId : m.id;
  //       if (id.isNotEmpty) merged[id] = m;
  //     }

  //     // ✅ CRDT overrides same IDs
  //     for (final m in incoming) {
  //       final id = m.messageId.isNotEmpty ? m.messageId : m.id;
  //       if (id.isNotEmpty) merged[id] = m;
  //     }

  //     // 4️⃣ SORT (web behavior)
  //     final mergedFlat = merged.values.toList()
  //       ..sort((a, b) => a.time.compareTo(b.time));

  //     // 5️⃣ OPTIONAL: save locally (safe now)
  //     await GrpLocalChatStorage.saveMessages(
  //       convoId,
  //       mergedFlat.map((e) => e.toJson()).toList(),
  //     );

  //     // 6️⃣ EMIT UI (NO MESSAGE LOSS)
  //     emit(
  //       GroupChatLoaded(
  //         GroupMessageResponse(
  //           data: _groupMessagesByDate(mergedFlat),
  //           total: mergedFlat.length,
  //           page: current.response.page,
  //           limit: current.response.limit,
  //           hasPreviousPage: current.response.hasPreviousPage,
  //           hasNextPage: current.response.hasNextPage,
  //         ),
  //       ),
  //     );
  //   } catch (e, st) {
  //     log("❌ GROUP CRDT merge error: $e");
  //     log(st.toString());
  //   }
  // }

  // Future<void> _onCrdtMessageReceived(Map<String, dynamic> payload) async {
  //   try {
  //     final convoId = payload['conversationId']?.toString();

  //     final isGroup = payload['isGroupChat'] == true;

  //     if (!isGroup) return;
  //     if (convoId == null) return;

  //     if (state is! GroupChatLoaded) return;

  //     final current = state as GroupChatLoaded;

  //     // Convert CRDT map → models
  //     final Map<String, dynamic> messagesMap =
  //         Map<String, dynamic>.from(payload['messages'] ?? {});

  //     if (messagesMap.isEmpty) return;

  //     final incoming = messagesMap.entries
  //         .map((e) => GroupMessageModel.fromJson(
  //               Map<String, dynamic>.from(e.value),
  //             ))
  //         .toList();

  //     // Flatten current UI messages
  //     final oldFlat = current.response.data.expand((g) => g.messages).toList();

  //     // Merge by ID
  //     final Map<String, GroupMessageModel> merged = {};

  //     for (final m in oldFlat) {
  //       final id = m.messageId.isNotEmpty ? m.messageId : m.id;
  //       merged[id] = m;
  //     }

  //     for (final m in incoming) {
  //       final id = m.messageId.isNotEmpty ? m.messageId : m.id;
  //       merged[id] = m;
  //     }

  //     final mergedFlat = merged.values.toList()
  //       ..sort((a, b) => a.time.compareTo(b.time));

  //     // 💾 Save to local storage
  //     await GrpLocalChatStorage.saveMessages(
  //       convoId,
  //       mergedFlat.map((e) => e.toJson()).toList(),
  //     );

  //     // 🔄 Emit updated UI state
  //     emit(
  //       GroupChatLoaded(
  //         GroupMessageResponse(
  //           data: _groupMessagesByDate(mergedFlat),
  //           total: mergedFlat.length,
  //           page: current.response.page,
  //           limit: current.response.limit,
  //           hasPreviousPage: current.response.hasPreviousPage,
  //           hasNextPage: current.response.hasNextPage,
  //         ),
  //       ),
  //     );
  //   } catch (e, st) {
  //     log("❌ CRDT merge error: $e");
  //     log(st.toString());
  //   }
  // }

  Future<void> _onFetchGroupMessages(
    FetchGroupMessages event,
    Emitter<GroupChatState> emit,
  ) async {
    try {
      /// 1️⃣ Load local cached messages FIRST (flat)
      final localMaps = GrpLocalChatStorage.loadMessages(event.convoId);

      List<GroupMessageModel> localMessages =
          localMaps.map((e) => GroupMessageModel.fromJson(e)).toList();

      // 🔹 Emit local cache immediately for page 1
      if (event.page == 1 && localMessages.isNotEmpty) {
        emit(
          GroupChatLoaded(
            GroupMessageResponse(
              data: _groupMessagesByDate(localMessages),
              total: localMessages.length,
              page: 1,
              limit: event.limit,
              hasPreviousPage: false,
              hasNextPage: true,
            ),
          ),
        );

        log("📌 Loaded local cache: ${localMessages.length}");
      }

      /// 2️⃣ Fetch from API
      final apiResp = await api.fetchMessages(
        convoId: event.convoId,
        page: event.page,
        limit: event.limit,
      );

      /// 3️⃣ Flatten API messages
      final apiFlat = apiResp.data.expand((group) => group.messages).toList();

      /// 4️⃣ Preserve pending local messages (sending)
      final pendingMessages = localMessages.where((m) {
        return m.messageStatus == 'sending' &&
            !apiFlat.any((apiMsg) =>
                apiMsg.id == m.id || apiMsg.messageId == m.messageId);
      }).toList();

      if (pendingMessages.isNotEmpty) {
        log("🔄 Preserving ${pendingMessages.length} pending messages");
        apiFlat.addAll(pendingMessages);
      }

      /// 5️⃣ 🔥 MERGE LOCAL + API (CRITICAL FIX)
      final Map<String, GroupMessageModel> mergeMap = {};

      // Existing local messages
      for (final m in localMessages) {
        final id = (m.messageId.isNotEmpty ? m.messageId : m.id).toString();
        if (id.isNotEmpty) mergeMap[id] = m;
      }

      // Overlay API messages
      for (final m in apiFlat) {
        final id = (m.messageId.isNotEmpty ? m.messageId : m.id).toString();
        if (id.isNotEmpty) mergeMap[id] = m;
      }

      final mergedFlat = mergeMap.values.toList()
        ..sort((a, b) => a.time.compareTo(b.time));

      log("✅ Merged messages count: ${mergedFlat.length}");

      /// 6️⃣ Save merged result to local storage
      await GrpLocalChatStorage.saveMessages(
        event.convoId,
        mergedFlat.map((m) => m.toJson()).toList(),
      );

      /// 7️⃣ Emit ONLY merged data (NO overwrite anymore)
      emit(
        GroupChatLoaded(
          GroupMessageResponse(
            data: _groupMessagesByDate(mergedFlat),
            total: apiResp.total,
            page: apiResp.page,
            limit: apiResp.limit,
            hasPreviousPage: apiResp.hasPreviousPage,
            hasNextPage: apiResp.hasNextPage,
          ),
        ),
      );

      log("📤 GroupChatLoaded emitted → page=${apiResp.page}, total=${apiResp.total}");
    } catch (e, st) {
      log("❌ FetchGroupMessages error: $e");
      log(st.toString());
      emit(GroupChatError("Failed to load messages"));
    }
  }

  // Future<void> _onFetchGroupMessages(
  //     FetchGroupMessages event, Emitter<GroupChatState> emit) async {
  //   try {
  //     /// 1. Load ALL local stored (flat) messages first
  //     final localMaps = GrpLocalChatStorage.loadMessages(event.convoId);
  //     List<GroupMessageModel> localMessages =
  //         localMaps.map((json) => GroupMessageModel.fromJson(json)).toList();

  //     if (event.page == 1) {
  //       if (localMessages.isNotEmpty) {
  //         emit(GroupChatLoaded(
  //           GroupMessageResponse(
  //             data: _groupMessagesByDate(localMessages),
  //             total: localMessages.length,
  //             page: event.page,
  //             limit: event.limit,
  //             hasPreviousPage: false,
  //             hasNextPage: true,
  //           ),
  //         ));

  //         log("📌 Loaded local cache: ${localMessages.length}");
  //       }
  //     }

  //     // =============================
  //     // 🔥 Fetch API Grouped Response
  //     // =============================
  //     final apiResp = await api.fetchMessages(
  //       convoId: event.convoId,
  //       page: event.page,
  //       limit: event.limit,
  //     );

  //     // API returns:
  //     // data = List<GroupMessageGroup>
  //     final List<GroupMessageGroup> incomingGroups = apiResp.data;

  //     // Flatten messages for saving to local
  //     final flatIncoming =
  //         incomingGroups.expand((group) => group.messages).toList();

  //     // 🛠️ FIX: Preserve pending 'sending' messages from local cache that are missing in API
  //     final pendingMessages = localMessages.where((m) {
  //       return m.messageStatus == 'sending' &&
  //           !flatIncoming.any((apiMsg) =>
  //               apiMsg.id == m.id || apiMsg.messageId == m.messageId);
  //     }).toList();

  //     if (pendingMessages.isNotEmpty) {
  //       log("🔄 Providing persistence for ${pendingMessages.length} pending messages");
  //       flatIncoming.addAll(pendingMessages);

  //       final todayLabel = _formatDate(DateTime.now());
  //       final todayGroupIndex =
  //           incomingGroups.indexWhere((g) => g.label == todayLabel);

  //       if (todayGroupIndex != -1) {
  //         incomingGroups[todayGroupIndex].messages.addAll(pendingMessages);
  //       } else {
  //         incomingGroups.insert(0,
  //             GroupMessageGroup(label: todayLabel, messages: pendingMessages));
  //       }
  //     }

  //     // 🛠️ CRITICAL FIX: Merge flatIncoming into localMessages instead of overwriting
  //     final Map<String, GroupMessageModel> mergeMap = {};
  //     // 1. Put existing local messages into map
  //     for (var m in localMessages) {
  //       final id = (m.messageId.isNotEmpty ? m.messageId : m.id).toString();
  //       if (id.isNotEmpty) mergeMap[id] = m;
  //     }
  //     // 2. Overlay incoming API messages
  //     for (var m in flatIncoming) {
  //       final id = (m.messageId.isNotEmpty ? m.messageId : m.id).toString();
  //       if (id.isNotEmpty) mergeMap[id] = m;
  //     }

  //     final mergedFlatList = mergeMap.values.toList();
  //     log("💾 Saving merged local storage: ${mergedFlatList.length} messages (was ${localMessages.length})");

  //     await GrpLocalChatStorage.saveMessages(
  //       event.convoId,
  //       mergedFlatList.map((m) => m.toJson()).toList(),
  //     );

  //     // Merge Pages for State Emission
  //     if (state is GroupChatLoaded && event.page > 1) {
  //       final prev = (state as GroupChatLoaded).response;
  //       log("🔄 Merging Page ${event.page} into existing state (Page ${prev.page})");

  //       // merge groups properly
  //       final mergedGroups = _mergeGroupedPages(prev.data, incomingGroups);

  //       final newState = GroupChatLoaded(
  //         GroupMessageResponse(
  //           data: mergedGroups,
  //           total: apiResp.total,
  //           page: apiResp.page,
  //           limit: apiResp.limit,
  //           hasPreviousPage: apiResp.hasPreviousPage,
  //           hasNextPage: apiResp.hasNextPage,
  //         ),
  //       );

  //       log("📤 Emitting merged GroupChatLoaded: Page ${newState.response.page}, Total ${newState.response.total}, Groups ${newState.response.data.length}");
  //       emit(newState);
  //     } else {
  //       log("📤 Emitting fresh GroupChatLoaded: Page ${apiResp.page}, Total ${apiResp.total}, Groups ${apiResp.data.length}");
  //       emit(GroupChatLoaded(apiResp));
  //     }
  //   } catch (e) {
  //     log("❌ FetchGroupMessages Error: $e");
  //     emit(GroupChatError("Failed to load messages"));
  //   }
  // }

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

      if (!grpSocket.isConnected) {
        throw Exception("Socket not connected");
      }
      final convoidId = event.convoId;
      grpSocket.sendMessage(
        isGroupMessage: false,
        messageId: messageId,
        conversationId: convoidId.isEmpty ? '' : convoidId,
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
    } catch (e, stackTrace) {
      log("❌ GroupChatBloc._onSendMessage error: $e\n$stackTrace");
      emit(GroupChatError("Failed to send message: $e"));
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
          final messageId = event.messageId ?? ObjectId().toString();
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
