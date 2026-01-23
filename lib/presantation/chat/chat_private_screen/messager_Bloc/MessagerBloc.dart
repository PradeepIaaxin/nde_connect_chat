import 'dart:async';
import 'dart:developer';
import 'dart:io' as io;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nde_email/data/respiratory.dart';
import 'package:nde_email/presantation/chat/chat_private_screen/localstorage/local_storage.dart';
import 'package:objectid/objectid.dart';

import '../../Socket/socket_service.dart';
import '../messager_api_service.dart';
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
    on<SendAudioMessageEvent>(_onSendAudioMessage);
  }

  Future<void> _onFetchMessages(
    FetchMessagesEvent event,
    Emitter<MessagerState> emit,
  ) async {
    // -------- PAGE 1: LOAD LOCAL --------
    if (event.page == 1) {
      final localRaw = LocalChatStorage.loadMessages(event.convoId);

      final localFlat = localRaw
          .whereType<Map<String, dynamic>>()
          .map((e) => Datum.fromJson(e))
          .toList();

      if (localFlat.isNotEmpty) {
        emit(
          MessagerLoaded(
            MessageListResponse(
              data: _convertFlatToGroups(localFlat),
              total: localFlat.length,
              page: 1,
              limit: event.limit,
              hasNextPage: true,
              hasPreviousPage: false,
              onlineParticipants: [],
            ),
          ),
        );
      } else {
        emit(MessagerLoading());
      }
    }

    try {
      // -------- FETCH SERVER --------
      final newFlat = await apiService.fetchMessages(
        convoId: event.convoId,
        page: event.page,
        limit: event.limit,
      );

      // -------- PAGE 1: REPLACE --------
      if (event.page == 1) {
        final serverJsonList = newFlat.map((e) => e.toJson()).toList();

        // Merge local reactions
        final mergedJsonList = _mergeLocalReactionsIntoServerJson(
          convoId: event.convoId,
          serverJsonList: serverJsonList,
        );

        final mergedFlat =
            mergedJsonList.map((j) => Datum.fromJson(j)).toList();

        await LocalChatStorage.saveMessages(
          event.convoId,
          mergedJsonList,
        );

        emit(
          MessagerLoaded(
            MessageListResponse(
              data: _convertFlatToGroups(mergedFlat),
              total: mergedFlat.length,
              page: 1,
              limit: event.limit,
              hasNextPage: newFlat.length >= event.limit,
              hasPreviousPage: false,
              onlineParticipants: [],
            ),
          ),
        );
        return;
      }

      // -------- PAGINATION (page > 1) --------
      final current = state;
      if (current is MessagerLoaded) {
        final oldFlat =
            current.response.data.expand((g) => g.messages).toList();

        final ids = oldFlat.map((m) => m.id).toSet();
        final unique = newFlat.where((m) => !ids.contains(m.id)).toList();

        // Prepend older messages for Oldest -> Newest list
        final combinedFlat = [...unique, ...oldFlat];

        final combinedJsonList = combinedFlat.map((e) => e.toJson()).toList();

        // Merge local reactions for the combined list
        final mergedJsonList = _mergeLocalReactionsIntoServerJson(
          convoId: event.convoId,
          serverJsonList: combinedJsonList,
        );

        final mergedFlat =
            mergedJsonList.map((j) => Datum.fromJson(j)).toList();

        await LocalChatStorage.saveMessages(
          event.convoId,
          mergedJsonList,
        );

        emit(
          MessagerLoaded(
            MessageListResponse(
              data: _convertFlatToGroups(mergedFlat),
              total: mergedFlat.length,
              page: event.page,
              limit: event.limit,
              hasNextPage: unique.length >= event.limit,
              hasPreviousPage: true,
              onlineParticipants: current.response.onlineParticipants,
            ),
          ),
        );
      }
    } catch (e) {
      log("❌ Message fetch error: $e");
      if (state is! MessagerLoaded) {
        emit(MessagerError(e.toString()));
      }
    }
  }

  Future<void> _onSendAudioMessage(
    SendAudioMessageEvent event,
    Emitter<MessagerState> emit,
  ) async {
    // 1. Validate file
    final io.File audioFile = io.File(event.audioPath);
    if (!audioFile.existsSync()) {
      emit(MessagerError("Audio file not found at ${event.audioPath}"));
      return;
    }

// 2. Create optimistic local message for instant UI update
    final tempMessageId = ObjectId().toString();
    final localMessage = {
      'content': '',
      'message_id': tempMessageId,
      'sender': {'_id': event.senderId},
      'receiver': {'_id': event.receiverId},
      'messageStatus': 'sending',
      'time': DateTime.now().toIso8601String(),
      'fileName': audioFile.path.split('/').last,
      'fileType': 'audio/m4a',
      'fileUrl': event.audioPath,
      'isLocal': true,
      'contentType': 'audio',
      'duration': event.duration,
    };

    // 3. Emit the local message for instant UI display
    emit(LocalAudioMessageAdded(localMessage));

    emit(UploadInProgress(0));

    final Completer<void> completer = Completer<void>();

    try {
      // 2. Upload File (Reusable API)
      apiService.uploadFile(
        file: audioFile,
        onProgress: (p) {
          if (!emit.isDone) emit(UploadInProgress(p));
        },
        onSuccess: (data) async {
          if (emit.isDone) {
            if (!completer.isCompleted) completer.complete();
            return;
          }

          emit(UploadSuccess(data));

          final workspaceID = await UserPreferences.getDefaultWorkspace();
          if (workspaceID == null) {
            emit(UploadFailure("Workspace not found"));
            if (!completer.isCompleted) completer.complete();
            return;
          }

          final roomId =
              socketService.generateRoomId(event.senderId, event.receiverId);

          // 3. Send via Socket
          socketService.sendMessage(
            isGroupMessage: false,
            messageId: tempMessageId,
            conversationId: event.convoId,
            senderId: event.senderId,
            receiverId: event.receiverId,
            message: "",
            roomId: roomId,
            workspaceId: workspaceID,
            isGroupChat: false,
            contentType: data["fieldname"] ?? "file",
            mimeType: data["mimetype"],
            fileName: data["fileName"] ?? "audio.m4a",
            size: data["size"] ?? 0,
            fileWithText: false,
            audioDuration: event.duration,
            originalKey: data["originalKey"] ?? "",
            originalUrl: data["originalUrl"] ?? data["location"] ?? "",
            ackCallback: (ack) {
              final tempId = ack['tempId'] ?? tempMessageId;
              final realId = ack['realId'] ??
                  ack['data']?['messageId'] ??
                  ack['message_id'];

              if (realId == null) return;

              emit(
                MessageAckReceived(
                  tempId: tempId.toString(),
                  realId: realId.toString(),
                  status: 'sent',
                ),
              );
            },
          );

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
        conversationId: event.convoId,
        messageIds: event.messageIds,
        roomId: roomId,
        deleteFor: event.deleteFor ?? "",
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
      )
  async {
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
      // if (!isTemp) {
      //   await apiService.reactionUpdated(
      //     conversationId: event.conversationId,
      //     messageId: backendId, // 👈 normalized id
      //     emoji: event.emoji,
      //     userId: event.userId,
      //     receiverId: event.receiverId,
      //
      //   );
      // } else {
      //   log('ℹ️ Skipping HTTP reactionUpdated for temp messageId=$rawId');
      // }
      final roomId = socketService.generateRoomId(event.userId, event.receiverId);
      // 5️⃣ Always send via socket so others see it
      log("rrrrrrrrrrrrr $roomId");
      socketService.emitReaction(
          messageId: backendId, // 👈 normalized id
          conversationId: event.conversationId,
          emoji: event.emoji,
          roomId: roomId,
          userId:event.userId,
          receiverId:event.receiverId
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
      )
  async {
    try {
      log('🔹 _onRemoveReaction called with: rawMessageId=${event.messageId}');

      final String rawId = event.messageId;
      final String backendId = _normalizeMessageIdForApi(rawId);
      final bool isTemp = rawId.startsWith('temp_');

      // if (!isTemp) {
      //   await apiService.reactionRemove(
      //     conversationId: event.conversationId,
      //     messageId: backendId, // 👈 normalized id
      //     userId: event.userId,
      //     receiverId: event.receiverId,
      //   );
      // } else {
      //   log('ℹ️ Skipping HTTP reactionRemove for temp messageId=$rawId');
      // }
      final roomId = socketService.generateRoomId(event.userId, event.receiverId);
      socketService.removeReaction(
        messageId: backendId, // 👈 normalized id
        conversationId: event.conversationId,
        emoji: event.emoji,
        userId:roomId,
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

    final tempMessageId = event.messageId ?? ObjectId().toString();

    try {
      await apiService.uploadFile(
        file: event.file,
        onProgress: (p) => emit(UploadInProgress(p)),
        onSuccess: (data) async {
          emit(UploadSuccess(data));

          final workspaceID = await UserPreferences.getDefaultWorkspace();

          if (workspaceID == null) {
            emit(UploadFailure("Workspace not found"));
            return;
          }

          final roomId = event.isGroupMessage
              ? event.convoId
              : socketService.generateRoomId(
                  event.senderId,
                  event.receiverId,
                );

          socketService.sendMessage(
            isGroupMessage: event.isGroupMessageChat??false,
            groupMessageId: event.groupMesageId,
            messageId: tempMessageId,
            conversationId: event.convoId,
            senderId: event.senderId,
            receiverId: event.receiverId,
            message: event.message,
            roomId: roomId,
            workspaceId: workspaceID,
            isGroupChat: false,
            contentType: event.contentType ?? data["fieldname"] ?? "file",
            mimeType: data["mimetype"],
            fileWithText: data["file_with_text"] != "",
            fileName: data["fileName"] ?? "",
            size: data["size"] ?? 0,
            thumbnailKey: data["thumbnail_key"] ?? "",
            thumbnailUrl: data["thumbnailUrl"] ?? "",
            originalKey: data["originalKey"] ?? "",
            originalUrl: data["originalUrl"] ?? "",
            audioDuration: event.duration,
            ackCallback: (ack) {
              final tempId = ack['tempId'] ?? tempMessageId;
              final realId = ack['realId'] ??
                  ack['data']?['messageId'] ??
                  ack['message_id'];

              if (realId == null) return;

              emit(
                MessageAckReceived(
                  tempId: tempId.toString(),
                  realId: realId.toString(),
                  status: 'sent',
                ),
              );
            },
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
      log("isGroupMessage ${event.replyIsGroupMessage}");
      log("isGroupMessage ${event.replyGroupMessageId}");
      log("replyGroupMessageCount ${event.replyGroupMessageCount}");
      final String? convoId = event.convoId!.isEmpty ? null : event.convoId;
      socketService.sendMessage(
        isGroupMessage: event.replyIsGroupMessage ?? false,
        messageId: msgId,
        conversationId: convoId,
        senderId: event.senderId,
        receiverId: event.receiverId,
        message: event.message,
        roomId: roomId,
        workspaceId: workspaceID!,
        isGroupChat: false,
        contentType: event.contentType,
        reply: event.replyTo,
        groupMessageId: event.replyGroupMessageId,
          replyGroupImageCount:event.replyGroupMessageCount

      );

      final localMessage = Message(
        senderId: event.senderId,
        receiverId: event.receiverId,
        message: event.message,
        time: DateTime.now(),
        messageId: msgId,
        messageStatus: "sent",
        conversationId: event.convoId,
        isGroupMessage: false,
        groupMessageId: null,
      );

      emit(MessageSentSuccessfully(localMessage));
      print("localMessage ${localMessage}");
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
    // socketService.listenToMessages(
    //   event.senderId,
    //   event.receiverId,
    //   (data) => add(NewMessageReceived(data)),
    // );
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
bool _isPresignedExpired(String url) {
  try {
    final u = Uri.parse(url);
    final xDate = u.queryParameters['X-Amz-Date'];
    final expires = int.tryParse(u.queryParameters['X-Amz-Expires'] ?? '') ?? 0;
    if (xDate == null || expires == 0) return false;

    final signedAt = DateTime.utc(
      int.parse(xDate.substring(0, 4)),
      int.parse(xDate.substring(4, 6)),
      int.parse(xDate.substring(6, 8)),
      int.parse(xDate.substring(9, 11)),
      int.parse(xDate.substring(11, 13)),
      int.parse(xDate.substring(13, 15)),
    );

    return DateTime.now().toUtc()
        .isAfter(signedAt.add(Duration(seconds: expires)));
  } catch (_) {
    return false;
  }
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
  final localRaw = LocalChatStorage.loadMessages(convoId);

  // Map: messageId -> List<reaction>
  final Map<String, List<Map<String, dynamic>>> localReactionsById = {};

  for (final raw in localRaw) {
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
