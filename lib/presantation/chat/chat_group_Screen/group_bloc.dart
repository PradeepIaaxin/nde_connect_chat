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
  String? _activeConvoId;

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
  }

  @override
  Future<void> close() {
    _reactionSubscription.cancel();
    grpSocket.clearActiveConversation();
    _crdtSubscription.cancel();
    return super.close();
  }

  Future<void> _onCrdtMessageReceived(Map<String, dynamic> payload) async {
    try {
      final convoId = payload['conversationId']?.toString();
      print(convoId.toString());
      if (convoId == null) return;

      if (convoId != _activeConvoId) return;

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

  Future<void> _onFetchGroupMessages(
    FetchGroupMessages event,
    Emitter<GroupChatState> emit,
  ) async {
    try {
      /// 1️⃣ Load local cached messages FIRST (flat)
      _activeConvoId = event.convoId;
      grpSocket.setActiveConversation(event.convoId);
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
        isGroupMessage:(event.replyTo?['is_grouped_message'] == true ||
            event.replyTo?['isGroupedMessage'] == true),
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
        replyGroupImageCount: event.replyGroupMessageCount,
        userName: username!,
        ackCallback: (ack) {
          final tempId = ack['tempId'] ?? messageId;
          final realId = ack['messageId'] ??
              ack['realId'] ??
              (ack['msg']?['messageId'] ?? ack['msg']?['id']);
          if (realId != null && !emit.isDone) {
            emit(GrpMessageAckReceived(
              tempId: tempId.toString(),
              realId: realId.toString(),
              status: ack['status'] ?? 'sent',
            ));
          }
        },
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
    final completer = Completer<void>();
    emit(UploadInProgress(0));

    try {
      await api.uploadFile(
        file: event.file,
        onProgress: (p) {
          if (!emit.isDone) emit(UploadInProgress(p));
        },
        onSuccess: (data) async {
          if (emit.isDone) {
            if (!completer.isCompleted) completer.complete();
            return;
          }

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
            audioDuration: event.duration,
            ackCallback: (ack) {
              final tempId = ack['tempId'] ?? messageId;
              final realId = ack['messageId'] ??
                  ack['realId'] ??
                  (ack['msg']?['messageId'] ?? ack['msg']?['id']);
              if (realId != null && !emit.isDone) {
                emit(GrpMessageAckReceived(
                  tempId: tempId.toString(),
                  realId: realId.toString(),
                  status: ack['status'] ?? 'sent',
                ));
              }
            },
          );

          emit(UploadSuccess(data, messageId: messageId));
          if (!completer.isCompleted) completer.complete();
        },
        onError: (err) {
          if (!emit.isDone) emit(UploadFailure(err));
          if (!completer.isCompleted) completer.complete();
        },
      );

      await completer.future;
    } catch (e) {
      if (!emit.isDone) emit(UploadFailure(e.toString()));
      if (!completer.isCompleted) completer.complete();
    }
  }

  // ==========================================================
  //           📌 DELETE MESSAGE
  // ==========================================================
  Future<void> _onDeleteMessage(
      DeleteMessagesEvent event, Emitter<GroupChatState> emit) async {
    try {
      grpSocket.deleteMessage(
        conversationId: event.convoId,
        messageIds: event.messageIds,
        roomId: event.receiverId,
        deleteFor: event.deleteFor,
      );

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
        // await api.reactionUpdated(
        //   conversationId: e.conversationId,
        //   messageId: e.messageId,
        //   emoji: e.emoji,
        //   userId: e.userId,
        //   receiverId: e.receiverId,
        // );
      }

      grpSocket.emitGroupReaction(
        messageId: e.messageId,
        conversationId: e.conversationId,
        emoji: e.emoji,
        userId: e.userId,
      );
    } catch (_) {}
  }

  Future<void> _onGroupRemoveReaction(
      GroupRemoveReaction e, Emitter<GroupChatState> emit) async {
    try {
      if (!e.messageId.startsWith("temp_")) {
        // await api.reactionRemove(
        //   conversationId: e.conversationId,
        //   messageId: e.messageId,
        //   userId: e.userId,
        //   receiverId: e.receiverId,
        // );
      }

      grpSocket.emitGroupRemoveReaction(
        messageId: e.messageId,
        conversationId: e.conversationId,
        emoji: e.emoji,
        userId: e.userId,
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
