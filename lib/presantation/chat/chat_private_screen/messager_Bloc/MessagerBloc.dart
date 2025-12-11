import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:nde_email/data/respiratory.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/localstorage/local_storage.dart';
import 'package:objectid/objectid.dart';

import '../../Socket/Socket_Service.dart';
import '../MessagerApiService.dart';
import '../messager_model.dart';
import 'MessagerEvent.dart';
import 'MessagerState.dart';

class MessagerBloc extends Bloc<MessagerEvent, MessagerState> {
  final MessagerApiService apiService;
  final SocketService socketService;

  MessagerBloc({required this.apiService, required this.socketService})
      : super(MessagerInitial()) {
    on<FetchMessagesEvent>(_onFetchMessages);
    on<ListenToMessages>(_onListenToMessages);
    on<NewMessageReceived>(_onNewMessageReceived);
    on<UploadFileEvent>(_onUploadFile);
    on<DeleteMessagesEvent>(_onDeleteMessage);
    on<SendMessageEvent>(_onSendMessage);
    on<ForwardMessageEvent>(_forwardMessage);
    on<AddReaction>(_onAddReaction);
    on<RemoveReaction>(_onRemoveReaction);
  }

  // =====================================================
  // FETCH MESSAGES (LOCAL FIRST → SERVER)
  // =====================================================
  Future<void> _onFetchMessages(
    FetchMessagesEvent event,
    Emitter<MessagerState> emit,
  ) async {
    // ----------- PAGE 1: Load local messages instantly -----------
    if (event.page == 1) {
      final rawLocal = LocalChatStorage.loadMessages(event.convoId);

      final fixedLocal = rawLocal.whereType<Map<String, dynamic>>().map((m) {
        if (m.containsKey('message_id')) m['_id'] = m['message_id'];
        return m;
      }).toList();

      final localMessages = fixedLocal.map((m) => Datum.fromJson(m)).toList();

      if (localMessages.isNotEmpty) {
        final groupedLocal = _convertFlatToGroups(localMessages);

        emit(
          MessagerLoaded(
            MessageListResponse(
              data: groupedLocal,
              total: localMessages.length,
              page: 1,
              limit: event.limit,
              hasNextPage: true,
              hasPreviousPage: false,
              onlineParticipants: [],
            ),
          ),
        );

        log("📌 Loaded LOCAL messages");
      } else {
        emit(MessagerLoading());
        log("📌 No local → show loader");
      }
    } else {
      emit(MessagerLoadingMore());
    }

    try {
      // ---------------- FETCH SERVER DATA ----------------
      final response = await apiService.fetchMessages(
        convoId: event.convoId,
        page: event.page,
        limit: event.limit,
      );

      log("📥 API RESPONSE PAGE ${event.page} → ${response.data.length} groups");

      final newGroups = response.data;
      final newFlat = newGroups.expand((g) => g.messages).toList();

      final currentState = state;

      // ----------- PAGE 1: Replace All Data, BUT PRESERVE LOCAL REACTIONS -----------
      if (event.page == 1) {
        // 1) Server messages as JSON
        final serverJsonList = newFlat.map((m) => m.toJson()).toList();

        // 2) Merge local reactions in
        final mergedJsonList = _mergeLocalReactionsIntoServerJson(
          convoId: event.convoId,
          serverJsonList: serverJsonList,
        );

        // 3) Convert back to Datum list with reactions inside
        final mergedFlat =
            mergedJsonList.map((j) => Datum.fromJson(j)).toList();

        // 4) Regroup into MessageGroup list
        final mergedGroups = _convertFlatToGroups(mergedFlat);

        // 5) Build a new response object with merged groups
        final mergedResponse = MessageListResponse(
          data: mergedGroups,
          total: response.total,
          page: response.page,
          limit: response.limit,
          hasNextPage: response.hasNextPage,
          hasPreviousPage: response.hasPreviousPage,
          onlineParticipants: response.onlineParticipants,
        );

        // 6) Save merged (with reactions) to local storage
        await LocalChatStorage.saveMessages(
          event.convoId,
          mergedFlat.map((m) => m.toJson()).toList(),
        );

        // 7) Emit merged response to UI
        emit(MessagerLoaded(mergedResponse));

        log("🚀 Fresh server messages (page 1) with local reactions merged");
        return;
      }

      // ----------- PAGINATION (page > 1) -----------
      if (currentState is MessagerLoaded) {
        final oldGroups = currentState.response.data;
        final oldFlat = oldGroups.expand((g) => g.messages).toList();

        final oldIds = oldFlat.map((m) => m.id).toSet();
        final uniqueNew = newFlat.where((m) => !oldIds.contains(m.id)).toList();

        final combinedFlat = [...oldFlat, ...uniqueNew];

        final combinedGroups = _convertFlatToGroups(combinedFlat);

        final mergedResponse = MessageListResponse(
          data: combinedGroups,
          total: response.total,
          page: response.page,
          limit: response.limit,
          hasNextPage: response.hasNextPage,
          hasPreviousPage: response.hasPreviousPage,
          onlineParticipants: response.onlineParticipants,
        );

        emit(MessagerLoaded(mergedResponse));

        await LocalChatStorage.saveMessages(
          event.convoId,
          combinedFlat.map((m) => m.toJson()).toList(),
        );

        log("📥 Pagination loaded → ${uniqueNew.length} new messages");
        return;
      }

      // fallback
      emit(MessagerLoaded(response));
    } catch (e) {
      log("❌ Fetch error: $e");
      if (event.page > 1 && state is MessagerLoaded) {
        emit(state);
      } else {
        emit(MessagerError(e.toString()));
      }
    }
  }

  Future<void> _onDeleteMessage(
    DeleteMessagesEvent event,
    Emitter<MessagerState> emit,
  ) async {
    log("entering Delete message and MessagerBloc : $event");

    final roomId =
        socketService.generateRoomId(event.senderId, event.receiverId);
    log(roomId);

    try {
      socketService.deleteMessage(
        messageId: event.messageIds.first,
        conversationId: event.convoId,
      );
    } catch (e) {
      log("Failed to emit delete_message: $e");
    }
  }

  String _normalizeMessageIdForApi(String messageId) {
    if (messageId.isEmpty) return messageId;

    // For forwarded messages like: forward_<realId>_<timestamp>
    if (messageId.startsWith('forward_')) {
      final parts = messageId.split('_');
      if (parts.length >= 3) {
        return parts[1]; // the realId in the middle
      }
    }

    return messageId;
  }

  // =====================================================
  // REACTIONS
  // =====================================================
  Future<void> _onAddReaction(
    AddReaction event,
    Emitter<MessagerState> emit,
  ) async {
    try {
      log('🔹 _onAddReaction called with: rawMessageId=${event.messageId}');

      // 1️⃣ raw id from UI (might be temp_ or forward_)
      final String rawId = event.messageId;

      // 2️⃣ Normalize for backend (strip forward_… prefix)
      final String backendId = _normalizeMessageIdForApi(rawId);

      // 3️⃣ temp_ check must be on RAW id (only local synthetic)
      final bool isTemp = rawId.startsWith('temp_');
      print("receivarrr ${event.receiverId}");
      // 4️⃣ Only hit REST if this is a real server id
      if (!isTemp) {
        await apiService.reactionUpdated(
          conversationId: event.conversationId,
          messageId: backendId, // 👈 normalized id
          emoji: event.emoji,
          userId: event.userId,
          receiverId: event.receiverId,
        );
      } else {
        log('ℹ️ Skipping HTTP reactionUpdated for temp messageId=$rawId');
      }

      // 5️⃣ Always send via socket so others see it
      socketService.reactToMessage(
        messageId: backendId, // 👈 normalized id
        conversationId: event.conversationId,
        emoji: event.emoji,
        userId: event.userId,
        firstName: event.firstName ?? "",
        lastName: event.lastName ?? "",
        receiverId: event.receiverId, // 👈 ADD THIS
      );
    } catch (e, st) {
      log('❌ Error adding reaction: $e');
      log(st.toString());
      emit(MessagerError('Failed to add reaction: ${e.toString()}'));
    }
  }

  Future<void> _onRemoveReaction(
    RemoveReaction event,
    Emitter<MessagerState> emit,
  ) async {
    try {
      log('🔹 _onRemoveReaction called with: rawMessageId=${event.messageId}');

      final String rawId = event.messageId;
      final String backendId = _normalizeMessageIdForApi(rawId);
      final bool isTemp = rawId.startsWith('temp_');

      if (!isTemp) {
        await apiService.reactionRemove(
          conversationId: event.conversationId,
          messageId: backendId, // 👈 normalized id
          userId: event.userId,
          receiverId: event.receiverId,
        );
      } else {
        log('ℹ️ Skipping HTTP reactionRemove for temp messageId=$rawId');
      }

      socketService.removeReaction(
        messageId: backendId, // 👈 normalized id
        conversationId: event.conversationId,
        emoji: event.emoji,
        userId: event.userId,
        firstName: event.firstName ?? "",
        lastName: event.lastName ?? "",
      );
    } catch (e, st) {
      log('❌ Error removing reaction: $e');
      log(st.toString());
    }
  }

  Future<void> _forwardMessage(
    ForwardMessageEvent event,
    Emitter<MessagerState> emit,
  ) async {
    emit(MessagerLoading());

    try {
      final successes = <Map<String, dynamic>>[];
      final failures = <Map<String, dynamic>>[];
      final results = <Map<String, dynamic>>[];

      for (final receiverId in event.receiverIds) {
        // forwardMessage returns List<Map<String, dynamic>>
        final List<Map<String, dynamic>> ackList =
            await socketService.forwardMessage(
          senderId: event.senderId,
          receiverIds: [receiverId],
          originalMessageId: event.originalMessageId,
          messageContent: event.message,
          conversationId: event.conversationId,
          workspaceId: event.workspaceId,
          isGroupChat: event.isGroupChat,
          currentUserInfo: event.currentUserInfo,
          file: event.file,
          fileName: event.fileName,
          image: event.image,
          contentType: event.contentType,
        );

        // Take first object (backend sends single entry list)
        final Map<String, dynamic> ack =
            ackList.isNotEmpty ? ackList.first : {"success": false};

        final bool ok = ack["success"] == true;

        if (ok) {
          successes.add({"receiverId": receiverId, "response": ack});
        } else {
          failures.add({"receiverId": receiverId, "response": ack});
        }

        results.add(ack);
      }

      // Emit results
      if (failures.isEmpty) {
        emit(MessageForwardedSuccess(results));
      } else if (successes.isNotEmpty) {
        emit(MessageForwardedPartialSuccess(
          successes: successes,
          failures: failures,
        ));
      } else {
        emit(MessagerError("Forwarding failed for all recipients"));
      }
    } catch (e, st) {
      log("Forward message error: $e\n$st");
      emit(MessagerError("Error forwarding message: $e"));
    }
  }

  // =====================================================
  // FILE UPLOAD
  // =====================================================
  Future<void> _onUploadFile(
    UploadFileEvent event,
    Emitter<MessagerState> emit,
  ) async {
    emit(UploadInProgress(0));

    try {
      await apiService.uploadFile(
        file: event.file,
        onProgress: (p) => emit(UploadInProgress(p)),
        onSuccess: (data) async {
          emit(UploadSuccess(data));
print("datasssss $data");
          String? workspaceID = await UserPreferences.getDefaultWorkspace();
          final roomId =
              socketService.generateRoomId(event.senderId, event.receiverId);

          final msgId = ObjectId().toString();

          socketService.sendMessage(
            isGroupMessage: event.isGroupMessage,
            groupMessageId: event.groupMesageId,
            messageId: msgId,
            conversationId: event.convoId,
            senderId: event.senderId,
            receiverId: event.receiverId,
            message: event.message,
            roomId: roomId,
            workspaceId: workspaceID!,
            isGroupChat: false,
            contentType: data["ContentType"],
            mimeType: data["mimetype"],
            fileWithText: data["file_with_text"] != "",
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

  // =====================================================
  // SEND MESSAGE
  // =====================================================
  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<MessagerState> emit,
  ) async {
    try {
      String? workspaceID = await UserPreferences.getDefaultWorkspace();
      final roomId =
          socketService.generateRoomId(event.senderId, event.receiverId);
      final msgId = ObjectId().toString();

      socketService.sendMessage(
        isGroupMessage: false,
        messageId: msgId,
        conversationId: event.convoId,
        senderId: event.senderId,
        receiverId: event.receiverId,
        message: event.message,
        roomId: roomId,
        workspaceId: workspaceID!,
        isGroupChat: false,
        contentType: event.contentType ?? "text",
        reply: event.replyTo,
      );

      final localMessage = Message(
        senderId: event.senderId,
        receiverId: event.receiverId,
        message: event.message,
        time: DateTime.now(),
        messageId: msgId,
        messageStatus: "sent",
        isGroupMessage: false,
        groupMessageId: null, // ✅ single tick
      );

      emit(MessageSentSuccessfully(localMessage));

      emit(MessageSentSuccessfully(localMessage));
    } catch (e) {
      log("❌ Error sending message: $e");
    }
  }

  // =====================================================
  // LISTEN SOCKET
  // =====================================================
  Future<void> _onListenToMessages(
    ListenToMessages event,
    Emitter<MessagerState> emit,
  ) async {
    socketService.listenToMessages(
      event.senderId,
      event.receiverId,
      (data) => add(NewMessageReceived(data)),
    );
  }

  void _onNewMessageReceived(
    NewMessageReceived event,
    Emitter<MessagerState> emit,
  ) {
    emit(NewMessageReceivedState(event.message));
  }
}

// =====================================================
// GROUPING MESSAGES (LOCAL ONLY)
// =====================================================
List<MessageGroup> _convertFlatToGroups(List<Datum> messages) {
  final map = <String, List<Datum>>{};

  for (var msg in messages) {
    final date = _extractDateLabel(msg.time);
    map.putIfAbsent(date, () => []);
    map[date]!.add(msg);
  }

  return map.entries
      .map((e) => MessageGroup(label: e.key, messages: e.value))
      .toList();
}

String _normalizeMessageIdForApi(String messageId) {
  if (messageId.isEmpty) return messageId;

  // For forwarded messages like: forward_<realId>_<timestamp>
  if (messageId.startsWith('forward_')) {
    final parts = messageId.split('_');
    if (parts.length >= 3) {
      return parts[1]; // the realId in the middle
    }
  }

  return messageId;
}

String _extractDateLabel(DateTime? time) {
  if (time == null) return "Unknown";

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final msgDay = DateTime(time.year, time.month, time.day);

  if (msgDay == today) return "Today";
  if (msgDay == today.subtract(Duration(days: 1))) return "Yesterday";

  return "${time.year}-${time.month}-${time.day}";
}

/// Merge local cached reactions into fresh server messages
List<Map<String, dynamic>> _mergeLocalReactionsIntoServerJson({
  required String convoId,
  required List<Map<String, dynamic>> serverJsonList,
}) {
  // 1) Load whatever we last saved locally
  final localRaw = LocalChatStorage.loadMessages(convoId) ?? [];

  // Map: messageId -> List<reaction>
  final Map<String, List<Map<String, dynamic>>> localReactionsById = {};

  for (final raw in localRaw) {
    if (raw is! Map) continue;
    final msg = Map<String, dynamic>.from(raw);

    final id = (msg['message_id'] ?? msg['_id'] ?? msg['id'])?.toString();
    if (id == null || id.isEmpty) continue;

    final reactions = (msg['reactions'] as List?)
            ?.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        [];

    if (reactions.isNotEmpty) {
      localReactionsById[id] = reactions;
    }
  }

  // 2) For each server message, if server has no reactions but local had, copy them
  return serverJsonList.map((json) {
    final j = Map<String, dynamic>.from(json);
    final id = (j['message_id'] ?? j['_id'] ?? j['id'])?.toString();

    if (id != null && id.isNotEmpty && localReactionsById.containsKey(id)) {
      final existing =
          (j['reactions'] as List?)?.whereType<Map>().toList() ?? [];

      if (existing.isEmpty) {
        j['reactions'] = localReactionsById[id]!
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }

    return j;
  }).toList();
}
