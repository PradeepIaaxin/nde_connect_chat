import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:nde_email/bridge_generated.dart/api.dart';
import 'package:nde_email/convo_list_crdt.dart';
import 'dart:typed_data';
import 'package:nde_email/data/respiratory.dart';
import 'package:nde_email/presantation/chat/chat_list/chat_response_model.dart';
import 'package:nde_email/presantation/chat/model/emoj_model.dart';
import 'package:nde_email/utils/device/device_keys.dart';
import 'package:nde_email/utils/reusbale/common_import.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? socket;
  Timer? _typingTimeout;

  String? roommId;
  String? currentWorkspaceId;
  String? _currentUserId;

  final List<String> onlineUsers = [];
  int _socketCreationCount = 0;

  final StreamController<Map<String, dynamic>> _typingController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get typingStream => _typingController.stream;

  final StreamController<MessageReaction> _reactionController =
      StreamController<MessageReaction>.broadcast();

  final StreamController<bool> _onlineStatusController =
      StreamController<bool>.broadcast();

  final StreamController<Map<String, dynamic>> _statusUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();

  final StreamController<void> _chatListRefreshController =
      StreamController<void>.broadcast();

  final StreamController<Map<String, dynamic>> _systemMessageController =
      StreamController<Map<String, dynamic>>.broadcast();

  final StreamController<Map<String, dynamic>> _userStatusController =
      StreamController<Map<String, dynamic>>.broadcast();

  final StreamController<String> _messageDeletedController =
      StreamController<String>.broadcast();

  final ValueNotifier<Set<String>> onlineUsersNotifier =
      ValueNotifier<Set<String>>({});

  final StreamController<Map<String, dynamic>> _favoriteUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();

  final StreamController<Map<String, dynamic>> _groupUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();

  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();

  final StreamController<Map<String, dynamic>> _crdtMessageController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get crdtMessageStream =>
      _crdtMessageController.stream;

  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<MessageReaction> get reactionStream => _reactionController.stream;
  Stream<bool> get onlineStatusStream => _onlineStatusController.stream;
  Stream<Map<String, dynamic>> get statusUpdateStream =>
      _statusUpdateController.stream;
  Stream<void> get chatListRefreshStream => _chatListRefreshController.stream;
  Stream<Map<String, dynamic>> get systemMessageStream =>
      _systemMessageController.stream;
  Stream<Map<String, dynamic>> get userStatusStream =>
      _userStatusController.stream;
  Stream<String> get messageDeletedStream => _messageDeletedController.stream;
  Stream<Map<String, dynamic>> get favoriteUpdateStream =>
      _favoriteUpdateController.stream;
  Stream<Map<String, dynamic>> get groupUpdateStream =>
      _groupUpdateController.stream;

  // Fast UI notifier for online/offline
  final ValueNotifier<Map<String, dynamic>> userStatusNotifier =
      ValueNotifier({});

  bool get isConnected => socket?.connected ?? false;

  static final Set<String> processedMessageIds = <String>{};

  bool _isConnecting = false;
  bool _isInitialized = false;

  final Set<String> _joinedRooms = <String>{};

  Function(List<Datu>)? _onChatListUpdatedCallback;
  void setChatListUpdateCallback(Function(List<Datu>) callback) {
    _onChatListUpdatedCallback = callback;
  }

  void _slog(String msg) {
    if (!kReleaseMode) {
      // ignore: avoid_print
      print(msg);
    }
  }

  String? _activeConversationId;
  void setActiveConversation(String convoId) {
    _activeConversationId = convoId;
  }

  void clearActiveConversation() {
    _activeConversationId = null;
  }

  // ========================
  // INITIALIZE – Call once at app start
  // ========================
  Future<void> initialize() async {
    if (_isInitialized || _isConnecting) return;

    _isConnecting = true;
    try {
      final userId = await UserPreferences.getUserId();
      final token = await UserPreferences.getAccessToken();
      final workspace = await UserPreferences.getDefaultWorkspace();

      if (userId == null || token == null || workspace == null) {
        _slog('Missing credentials – cannot initialize socket');
        return;
      }

      _currentUserId = userId;
      currentWorkspaceId = workspace;

      await _createPersistentSocket(
        token: token,
        userId: userId,
        workspaceId: workspace,
      );

      _isInitialized = true;
    } finally {
      _isConnecting = false;
    }
  }

  Completer<void>? _connectCompleter;

  Future<void> waitUntilConnected() {
    if (socket?.connected == true) {
      return Future.value();
    }
    _connectCompleter ??= Completer<void>();
    return _connectCompleter!.future;
  }

  // ========================
  // PERSISTENT SOCKET (single instance)
  // ========================
  Future<void> _createPersistentSocket({
    required String token,
    required String userId,
    required String workspaceId,
  }) async {
    // Clean any existing socket
    socket?.clearListeners();
    socket?.disconnect();
    socket?.dispose();
    socket = null;
    print("socket creating....");

    const String socketUrl = 'https://api.nowdigitaleasy.com/wschat';

    socket = IO.io(
      socketUrl,
      IO.OptionBuilder()
          .setPath('/wschat/socket.io')
          .setQuery({
            'token': 'Bearer $token',
            'userId': userId,
            'workspaceId': workspaceId,
            'deviceId': await UserPreferences.getDeviceId(),
          })
          .setTransports(['websocket']) // Faster, skip polling
          .enableAutoConnect()
          .setReconnectionAttempts(999999)
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .setTimeout(10000)
          .build(),
    );

    //  socket!.clearListeners();
    _registerGlobalHandlers();

    socket!.connect();
    _slog('Persistent socket connecting...');
  }

  // ========================
  // Global handlers (registered once)
  // ========================
  void _registerGlobalHandlers() {
    socket!.onConnect((_) {
      _socketCreationCount++;
      _slog('✅ Socket connected: ${socket!.id} (total: $_socketCreationCount)');
      if (_connectCompleter != null && !_connectCompleter!.isCompleted) {
        _connectCompleter!.complete();
      }

      print("current workspace : $currentWorkspaceId");
      print("mine userId : $_currentUserId");

      Future.microtask(() async {
        try {
          final deviceId = await UserPreferences.getDeviceId();
          log("device_id : $deviceId");
          final keys = await getOrCreateDeviceKeys();

          socket!.emit('register_device', {
            'deviceId': deviceId,
            'userId': _currentUserId,
            'publicKey': bytesToHex(keys.publicKey),
          });

          _slog('[SOCKET] register_device emitted');
        } catch (e) {
          _slog('❌ register_device error: $e');
        }
      });

      _registerAllEventHandlers();
      // Re-join workspace on every connect/reconnect
      Future.delayed(const Duration(milliseconds: 150), () {
        if (currentWorkspaceId != null && _currentUserId != null) {
          socket!.emitWithAck(
            'join_workspace',
            {
              'workspaceId': currentWorkspaceId!,
              'userId': _currentUserId!,
            },
            ack: (response) {
              _slog('🟢 join_workspace ACK: $response');

              if (response is Map && response['success'] == true) {
                // _onlineStatusController.add(true);
              } else {
                _slog('🔴 join_workspace rejected');
              }
            },
          );

          syncConvoList();

          _slog('join_workspace emitted');
        }
      });

      if (!_onlineStatusController.isClosed) {
        // _onlineStatusController.add(true);
      }

      print("soxket id : ${socket!.id}");
      print("socket : ${socket!.connected}");
      socket!.onAny((event, data) {
        print("🔥 RAW USER PRESENCE EVENT → $event : $data");
      });
    });

    // ========================
    // DEVICE AUTH EVENTS (ADD ONCE)
    // ========================

    socket!.off('device_challenge');
    socket!.on('device_challenge', (data) async {
      try {
        print('🔐 device_challenge');

        final payload = (data is List && data.isNotEmpty) ? data.first : data;
        if (payload is! Map) return;

        final nonce = payload['nonce']?.toString();
        if (nonce == null) return;

        final keys = await getOrCreateDeviceKeys();

        final signature = await signWithPrivateKey(
          keys.privateKey,
          nonce,
        );

        print('🖊 signature generated, length=${signature.length}');

        socket!.emit('verify_device', {
          'signature': signature,
        });

        print('✅ verify_device emitted');
      } catch (e, st) {
        print('❌ device_challenge error: $e');
        print(st);
      }
    });

    socket!.off('device_authenticated');
    socket!.on('device_authenticated', (_) {
      print('🎉 Device authenticated');
    });

    socket!.onDisconnect((_) {
      _slog('Socket disconnected');
      _onlineStatusController.add(false);
      _joinedRooms.clear();
      _connectCompleter = null;
    });

    socket!.onConnectError((err) {
      _slog('Connect error: $err');
      _onlineStatusController.add(false);
    });

    socket!.onError((err) {
      _slog('Socket error: $err');
      _onlineStatusController.add(false);
    });
  }

  void _registerAllEventHandlers() {
    final Map<String, Function(dynamic)> events = {
      'roomJoined': _handleRoomJoined,
      'workspaceRoomJoined': _handleRoomJoined,
      'system_message': (data) => _systemMessageController.add(data),
      'get_typing': _handleTyping,
      'messagesRead': _handleMessagesRead,
      'updated_reaction': (data) => _handleReaction(data, isRemoval: false),
      'remove_reaction': (data) => _handleReaction(data, isRemoval: true),
      'update_delivered': _handleDeliveredUpdate,
      'message_delivered': _handleDeliveredUpdate,
      'message_delivered_when_online': _handleMessageDeliveredWhenOnline,
      'forward_message': _handleForwardMessage,
      'update_message_read': _handleUpdateMessageRead,
      'user_online': (data) => _handleUserPresence(data, online: true),
      'user_offline': (data) => _handleUserPresence(data, online: false),
      'messageListUpdate': _handleMessageListUpdate,
      'chatlistUpdate': _handleChatListUpdate,
      'message_deleted': _handleMessageDeleted,
      'favorite_updated': (data) => _favoriteUpdateController.add(data),
      'group_updated': (data) => _groupUpdateController.add(data),
    };

    final messageEvents = [
      // 'receive_message',
      // 'new_message',
      // 'message',
      // 'newMessage',
      // 'message_created',
      'send_message',
      // 'receive_group_message',
      // 'group_message',
    ];

    // Register all
    events.forEach((event, handler) {
      socket!.off(event);
      socket!.on(event, handler);
    });

    for (final ev in messageEvents) {
      socket!.off(ev);
      socket!.on(ev, _handleIncomingMessage);
    }

    _slog('All event handlers registered once');
  }

  // ========================
  // Room joining – fast & deduplicated
  // ========================
  Future<void> joinChatRoom({
    required String senderId,
    required String receiverId,
    required bool isGroupChat,
    Function(Map<String, dynamic>)? onMessageReceived,
  }) async {
    await initialize();

    if (!isConnected) {
      _slog('Cannot join room – socket not connected');
      return;
    }

    final roomKey = isGroupChat
        ? 'group:$receiverId'
        : generateRoomId(senderId, receiverId);

    if (_joinedRooms.contains(roomKey)) {
      _slog('Already joined: $roomKey');
      return;
    }

    if (isGroupChat) {
      socket!.emit('join_group_room', {'groupId': receiverId});
      _slog('join_group_room → $receiverId');
    } else {
      socket!.emit('join_private_room', {
        'senderId': senderId,
        'receiverId': receiverId,
      });
      _slog('join_private_room → $senderId ↔ $receiverId');
    }

    _joinedRooms.add(roomKey);
  }

  // Legacy wrapper (kept for compatibility)
  Future<void> connectPrivateRoom(
    String senderId,
    String receiverId,
    Function(Map<String, dynamic>) onMessageReceived,
    bool isGroupchat,
  ) async {
    await joinChatRoom(
      senderId: senderId,
      receiverId: receiverId,
      isGroupChat: isGroupchat,
      onMessageReceived: onMessageReceived,
    );
  }

  // ========================
  // Event Handlers (all original logic preserved)
  // ========================
  void _handleRoomJoined(dynamic response) {
    scheduleMicrotask(() {
      _slog('roomJoined -> $response');
      if (response is Map && response.containsKey('roomId')) {
        roommId = response['roomId']?.toString();
        saveRoomId(roommId!);
        _slog('Saved roomId $roommId');
      }
    });
  }

  void _handleTyping(dynamic response) {
    scheduleMicrotask(() {
      _slog('get_typing -> $response');
      final map = _firstMapFromPossibleList(response);
      if (map == null) return;

      if (map['userId'] == _currentUserId) return;

      final convoId = map['convoId'];
      final message = map['message'];
      if (convoId == null || message == null) return;

      _typingController.add({"convoId": convoId, "message": message});

      _typingTimeout?.cancel();
      _typingTimeout = Timer(const Duration(seconds: 2), () {
        _typingController.add({});
      });
    });
  }

  void _handleMessagesRead(dynamic data) {
    scheduleMicrotask(() {
      _slog('messagesRead -> $data');
      final map = _firstMapFromPossibleList(data);
      if (map == null) return;
      final ids =
          (map['messageIds'] as List?)?.map((e) => e.toString()).toList() ?? [];
      if (ids.isEmpty) return;
      final update = {
        "status": "read",
        "messageStatus": "read",
        "conversationId": map['conversationId'],
        "roomId": map['roomId'],
        "messageIds": ids,
        "singleMessageId": ids.first,
        "userId": map['userId'],
      };
      _statusUpdateController.add(update);
    });
  }

  void _handleReaction(dynamic data, {required bool isRemoval}) {
    scheduleMicrotask(() {
      _slog('${isRemoval ? "remove" : "updated"}_reaction -> $data');
      try {
        final raw = _extractFirstMap(data);
        if (raw == null) return;
        final reaction =
            MessageReaction.fromMap(Map<String, dynamic>.from(raw));
        if (isRemoval) reaction.isRemoval = true;
        _reactionController.add(reaction);
      } catch (e) {
        _slog('Reaction parse error: $e');
      }
    });
  }

  void _handleDeliveredUpdate(dynamic data) {
    scheduleMicrotask(() {
      final List listData = (data is List) ? data : [data];
      for (final item in listData) {
        if (item is! Map) continue;
        final ids = (item['messageIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            (item['messageId'] != null ? [item['messageId'].toString()] : []);
        if (ids.isEmpty) continue;
        final status =
            (item['messageStatus'] ?? item['status'] ?? 'delivered').toString();
        _statusUpdateController.add({
          "status": status,
          "messageStatus": status,
          "roomId": item['roomId'],
          "messageIds": ids,
          "singleMessageId": ids.first,
          "userId": item['userId'],
          "time": item['time'],
        });
      }
    });
  }

  void _handleMessageDeliveredWhenOnline(dynamic data) {
    scheduleMicrotask(() {
      _slog('message_delivered_when_online -> $data');
      try {
        if (data is List && data.isNotEmpty) {
          final firstPayload = data.first;
          if (firstPayload is Map && firstPayload['data'] is Map) {
            final innerData = firstPayload['data'];
            final messageId = innerData['messageId'];
            final roomId = innerData['roomId'];
            final convoId = innerData['convoId'];
            if (messageId != null && roomId != null && convoId != null) {
              _sendMessageDelivered(
                messageIds: [messageId.toString()],
                roomId: roomId.toString(),
                convoId: convoId.toString(),
              );
            }
          }
        }
      } catch (e) {
        _slog('message_delivered_when_online error: $e');
      }
    });
  }

  void _handleForwardMessage(dynamic payload) {
    scheduleMicrotask(() {
      _slog('forward_message -> $payload');
      if (payload is Map) {
        _messageController.add({
          'event': 'forward_message',
          'data': Map<String, dynamic>.from(payload),
        });
      } else if (payload is List &&
          payload.isNotEmpty &&
          payload.first is Map) {
        _messageController.add({
          'event': 'forward_message',
          'data': Map<String, dynamic>.from(payload.first),
        });
      }
    });
  }

  void _handleUpdateMessageRead(dynamic data) {
    scheduleMicrotask(() {
      _slog('update_message_read -> $data');
      if (data is! List) return;
      for (final item in data) {
        if (item is! Map<String, dynamic>) continue;
        final msgId =
            item['messageId']?.toString() ?? item['message_id']?.toString();
        if (msgId == null || msgId.isEmpty) continue;
        final update = {
          "status": "read",
          "messageStatus": "read",
          "messageId": msgId,
          "messageIds": [msgId],
          "roomId": item['roomId'],
          "convoId": item['convoId'],
          "userId": item['userId'],
          "time": item['time'],
        };
        _statusUpdateController.add(update);
      }
    });
  }

  void _handleUserPresence(dynamic data, {required bool online}) {
    // ✅ SAFETY: controller may be closed after logout
    if (_userStatusController.isClosed) return;

    String? userId;

    if (data is List && data.isNotEmpty) {
      userId = data.first.toString();
    } else if (data is Map) {
      userId = data['userId']?.toString();
    } else if (data is String) {
      userId = data;
    }

    if (userId == null || userId.isEmpty) return;

    // ✅ Update notifier (safe, not a stream)
    final current = Set<String>.from(onlineUsersNotifier.value);

    if (online) {
      current.add(userId);
    } else {
      current.remove(userId);
    }
    onlineUsersNotifier.value = current;

    // ✅ ADD TO STREAM ONLY IF OPEN
    if (!_userStatusController.isClosed) {
      if (data is Map<String, dynamic>) {
        _userStatusController.add(data);
        log("👤 User status update received: $data");
      } else {
        _userStatusController.add({
          'userId': userId,
          'online': online,
        });
      }
    }

    _slog("Presence: $userId → ${online ? 'online' : 'offline'}");
  }

  void _handleMessageListUpdate(dynamic payload) {
    scheduleMicrotask(() async {
      try {
        if (payload is! List || payload.isEmpty) return;
        final first = payload.first;
        if (first is! Map) return;

        final convoIdFromEvent = first['conversationId']?.toString();
        if (convoIdFromEvent == null) return;

        final rawUpdate = first['update'];
        if (rawUpdate == null) return;

        final bytes = _bytesFromIntList(rawUpdate);
        if (bytes == null || bytes.isEmpty) return;

        final jsonString = await importMessageUpdate(updateBytes: bytes);
        final decoded = jsonDecode(jsonString);
        final Map<String, dynamic> messagesMap =
            Map<String, dynamic>.from(decoded['messages'] ?? {});

        if (messagesMap.isEmpty) return;

        if (_activeConversationId == null ||
            convoIdFromEvent != _activeConversationId) {
          return;
        }

        _crdtMessageController.add({
          'conversationId': convoIdFromEvent,
          'messages': messagesMap,
        });
      } catch (e, st) {
        debugPrint('messageListUpdate error: $e\n$st');
      }
    });
  }

  void _handleChatListUpdate(dynamic payload) {
    scheduleMicrotask(() async {
      try {
        final bytes = _decodeToBytes(payload);
        if (bytes == null || bytes.isEmpty) return;

        final jsonString = await importChatUpdate(updateBytes: bytes);
        final decoded = jsonDecode(jsonString);
        final List list = decoded["chatDataList"] ?? [];

        if (list.isEmpty) return;

        final datuList = list.map<Datu>((e) => Datu.fromJson(e)).toList();

        // 🔥 DEDUPLICATE BY conversationId (THIS FIXES YOUR ISSUE)
        final Map<String, Datu> uniqueMap = {};
        for (final d in datuList) {
          if (d.conversationId != null) {
            uniqueMap[d.conversationId!] = d;
          }
        }

        final uniqueList = uniqueMap.values.toList();

        // 🔥 SAVE CRDT SNAPSHOT + FRONTIERS
        final snapshot = await exportChatSnapshot();
        final frontiers = await exportChatFrontiers();
        final box = await Hive.openBox<ConvoListCrdt>('convo_crdt');
        await box.put(
          _currentUserId!,
          ConvoListCrdt(
            snapshot: snapshot,
            frontiers: frontiers,
            savedAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );

        _onChatListUpdatedCallback?.call(uniqueList);
      } catch (e) {
        _slog('chatlistUpdate error: $e');
      }
    });
  }

  void _handleMessageDeleted(dynamic data) {
    scheduleMicrotask(() {
      _slog('message_deleted -> $data');
      if (data is Map<String, dynamic> && data.containsKey('messageId')) {
        _messageDeletedController.add(data['messageId'].toString());
      }
    });
  }

  void _handleIncomingMessage(dynamic payload) {
    try {
      final map = _firstMapFromPossibleList(payload);
      if (map == null) return;

      final String? convoId =
          map['conversationId']?.toString() ?? map['convoId']?.toString();

      final String? messageId =
          map['message_id']?.toString() ?? map['messageId']?.toString();

      if (convoId == null || messageId == null) return;

      final dedupeKey = '$convoId:$messageId';

      if (processedMessageIds.contains(dedupeKey)) return;
      processedMessageIds.add(dedupeKey);

      // ✅ DO NOTHING ELSE
      // ❌ DO NOT ADD TO MESSAGE LIST
      // CRDT WILL HANDLE IT
    } catch (_) {}
  }

  // void _handleIncomingMessage(dynamic payload) {
  //   try {
  //     final map = _firstMapFromPossibleList(payload);
  //     if (map == null) return;

  //     // 🔑 Normalize conversationId
  //     final String? convoId =
  //         map['conversationId']?.toString() ?? map['convoId']?.toString();

  //     if (convoId == null || convoId.isEmpty) return;

  //     // 🔑 Normalize messageId (DO NOT use `id`)
  //     final String? messageId =
  //         map['message_id']?.toString() ?? map['messageId']?.toString();

  //     if (messageId == null || messageId.isEmpty) return;

  //     // 🔥 STRONG DEDUPE KEY (conversation + message)
  //     final String dedupeKey = '$convoId:$messageId';

  //     if (processedMessageIds.contains(dedupeKey)) {
  //       _slog('⏭ Duplicate message skipped: $dedupeKey');
  //       return;
  //     }

  //     processedMessageIds.add(dedupeKey);

  //     // 🧹 Keep memory small
  //     if (processedMessageIds.length > 3000) {
  //       processedMessageIds.remove(processedMessageIds.first);
  //     }

  //     // 🚫 CRDT is source of truth for active conversation
  //     if (_activeConversationId == convoId) {
  //       return;
  //     }

  //     // ✅ Emit message ONCE
  //     _messageController.add(Map<String, dynamic>.from(map));
  //   } catch (e, st) {
  //     _slog('Incoming message error: $e\n$st');
  //   }
  // }

  // void _handleIncomingMessage(dynamic payload) {
  //   try {
  //     final map = _firstMapFromPossibleList(payload);
  //     if (map == null) {
  //       _slog('Incoming message not map: ${payload.runtimeType}');
  //       return;
  //     }

  //     final msgId =
  //         (map['messageId'] ?? map['message_id'] ?? map['id'])?.toString();
  //     if (msgId != null && msgId.isNotEmpty) {
  //       if (processedMessageIds.contains(msgId)) {
  //         _slog('Duplicate message skipped: $msgId');
  //         return;
  //       }
  //       processedMessageIds.add(msgId);
  //       if (processedMessageIds.length > 2000) {
  //         final toRemove = processedMessageIds.length - 1000;
  //         final iter = processedMessageIds.toList().sublist(0, toRemove);
  //         for (final id in iter) {
  //           processedMessageIds.remove(id);
  //         }
  //       }
  //     }

  //     _messageController.add(Map<String, dynamic>.from(map));
  //   } catch (e, st) {
  //     _slog('Incoming message error: $e $st');
  //   }
  // }

  // ========================
  // Helper parsers
  // ========================
  Map<String, dynamic>? _firstMapFromPossibleList(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is List && data.isNotEmpty) {
      final firstMap = data.firstWhere((e) => e is Map, orElse: () => null);
      if (firstMap != null) return Map<String, dynamic>.from(firstMap as Map);
    }
    return null;
  }

  Map<String, dynamic>? _extractFirstMap(dynamic data) {
    if (data == null) return null;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is List && data.isNotEmpty && data.first is Map) {
      return Map<String, dynamic>.from(data.first as Map);
    }
    return null;
  }

  Uint8List? _bytesFromIntList(dynamic raw) {
    if (raw is Uint8List) return raw;
    if (raw is List) {
      try {
        return Uint8List.fromList(raw.cast<int>());
      } catch (_) {}
    }
    return null;
  }

  Uint8List? _decodeToBytes(dynamic payload) {
    if (payload == null) return null;
    if (payload is Uint8List) return payload;
    if (payload is String) {
      try {
        return base64Decode(payload);
      } catch (_) {}
    }
    if (payload is List) {
      final binaryChunks = payload.whereType<Uint8List>().toList();
      if (binaryChunks.isNotEmpty) {
        final total = binaryChunks.fold(0, (p, e) => p + e.length);
        final buffer = Uint8List(total);
        int offset = 0;
        for (final c in binaryChunks) {
          buffer.setRange(offset, offset + c.length, c);
          offset += c.length;
        }
        return buffer;
      }
      final stringChunks = payload.whereType<String>().toList();
      if (stringChunks.isNotEmpty) {
        try {
          return base64Decode(stringChunks.join());
        } catch (_) {}
      }
    }
    return null;
  }

  // ========================
  // Public methods (all preserved)
  // ========================
  Future<void> saveRoomId(String rId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('roomId', rId);
    } catch (e) {
      _slog('saveRoomId error: $e');
    }
  }

  Future<void> syncConvoList() async {
    if (!isConnected || _currentUserId == null) return;

    final box = await Hive.openBox<ConvoListCrdt>('convo_crdt');
    final local = box.get(_currentUserId!);

    if (local == null) {
      // ❌ No CRDT → snapshot bootstrap
      socket!.emit('convoList:sync', {
        'userId': _currentUserId,
        'mode': 'snapshot',
      });
      return;
    }

    // ✅ Delta sync (NORMAL CASE)
    socket!.emit('convoList:sync', {
      'userId': _currentUserId,
      'frontiers': local.frontiers,
    });
  }

  void sendTyping({
    required String roomId,
    required String convoId,
    required String userName,
  }) {
    if (!isConnected) return;

    final typingData = {
      "roomId": roomId,
      "convoId": convoId,
      "userName": userName,
    };
    print("typing data : $typingData");
    socket!.emit('get_typing', typingData);
  }

  void setUserOffline(String userId, String workspaceId) {
    if (!isConnected) return;
    socket!
        .emit("user_offline", {"userId": userId, "workspaceId": workspaceId});
  }

  void _sendMessageDelivered({
    required List<String> messageIds,
    required String roomId,
    required String convoId,
  }) {
    if (!isConnected) return;
    final time = DateTime.now().toIso8601String();
    socket!.emit('message_delivered', {
      'messageIds': messageIds,
      'time': time,
      'roomId': roomId,
      'convoId': convoId,
    });
  }

  void makeDelivered(
      {required List<String> messageIds, required String roomId}) {
    if (!isConnected) return;
    socket!
        .emit('make_delivered', {'messageIds': messageIds, 'roomId': roomId});
  }

  Future<List<Map<String, dynamic>>> forwardMessage({
    required String senderId,
    required List<String> receiverIds,
    required String originalMessageId,
    required String messageContent,
    required String conversationId,
    required String workspaceId,
    required bool isGroupChat,
    required Map<String, String> currentUserInfo,
    dynamic file,
    String? fileName,
    String? image,
    String contentType = 'text',
    Duration ackTimeout = const Duration(seconds: 8),
  }) async {
    final results = <Map<String, dynamic>>[];

    if (senderId.isEmpty ||
        receiverIds.isEmpty ||
        originalMessageId.isEmpty ||
        workspaceId.isEmpty ||
        !isConnected) {
      log("❌ ForwardMessage failed: Missing fields or socket not connected");
      return receiverIds
          .map((r) => {
                'receiverId': r,
                'success': false,
                'error': 'Missing fields or not connected'
              })
          .toList();
    }

    for (final receiverId in receiverIds) {
      final roomId = generateRoomId(senderId, receiverId);

      final forwardPayload = {
        "forward": [
          {
            "sender": senderId,
            "receiver": receiverId,
            "conversationId": conversationId,
            "workspaceId": workspaceId,
            "roomId": roomId,
            "isGroupChat": isGroupChat,
            "UserData": {"first_name": currentUserInfo['name'] ?? ""}
          }
        ],
        "messageIds": [
          {"messageId": originalMessageId, "forwardUserId": receiverId}
        ],
        "isForwarded": true,
        "isOwnConvo": true,
        "contentType": contentType,
        "fileName": fileName,
        "image": image,
      };

      /// 🔵 LOG → PAYLOAD
      log("📤 FORWARD PAYLOAD → receiver=$receiverId");
      log(forwardPayload.toString());

      final completer = Completer<Map<String, dynamic>>();
      bool completed = false;

      final timer = Timer(ackTimeout, () {
        if (!completed) {
          completed = true;
          log("⏰ ACK TIMEOUT → receiver=$receiverId");
          completer.complete({
            'receiverId': receiverId,
            'success': false,
            'error': 'ACK timeout'
          });
        }
      });

      socket!.emitWithAck(
        'forward_message',
        forwardPayload,
        ack: (ackResponse) {
          if (completed) return;

          completed = true;
          timer.cancel();

          /// 🔵 LOG → RAW ACK
          log("📥 RAW ACK → receiver=$receiverId");
          log(ackResponse.toString());

          try {
            final entry = <String, dynamic>{
              'receiverId': receiverId,
              'success': false,
              'response': ackResponse,
            };

            String? serverMessageId;

            if (ackResponse is Map) {
              if (ackResponse['data'] is Map) {
                serverMessageId =
                    ackResponse['data']['messageId']?.toString() ??
                        ackResponse['data']['message_id']?.toString();
              }

              serverMessageId ??= ackResponse['messageId']?.toString() ??
                  ackResponse['message_id']?.toString() ??
                  ackResponse['id']?.toString();

              entry['success'] = ackResponse['success'] == true ||
                  ackResponse['status'] == 'success';

              if (serverMessageId != null) {
                entry['serverMessageId'] = serverMessageId;
              }
            }

            /// 🟢 LOG → PARSED ACK
            log("✅ PARSED ACK → receiver=$receiverId");
            log(entry.toString());

            completer.complete(entry);
          } catch (e, st) {
            log("❌ ACK PARSE ERROR → receiver=$receiverId");
            log(e.toString());
            log(st.toString());

            completer.complete({
              'receiverId': receiverId,
              'success': false,
              'error': 'Parse error: $e'
            });
          }
        },
      );

      final result = await completer.future;
      results.add(result);

      await Future.delayed(const Duration(milliseconds: 40));
    }

    /// 🧾 FINAL RESULT LOG
    log("📊 FORWARD MESSAGE RESULTS");
    log(results.toString());

    return results;
  }

  void sendReadReceipts({
    required List<String> messageIds,
    required String conversationId,
    required String roomId,
  }) {
    if (!isConnected) return;
    socket!.emit('read_messages', {
      "conversationId": conversationId,
      "roomId": roomId,
      "userId": _currentUserId,
      "messageIds": messageIds,
    });
  }

  void deleteMessage({
    required List<String> messageIds,
    required String conversationId,
    required String roomId,
    required String deleteFor,
  }) {
    if (!isConnected) return;
    socket!.emit('delete_message', {
      "messageIds": messageIds,
      "conversationId": conversationId,
      "roomId": roomId,
      "deleteFor": deleteFor,
    });
  }

  void reactToMessage({
    required String messageId,
    required String conversationId,
    required String emoji,
    required String userId,
    required String firstName,
    required String lastName,
    required String receiverId,
  }) {
    if (!isConnected) return;
    final rid = generateRoomId(userId, receiverId);
    final reactionObject = {
      "conversationId": conversationId,
      "messageId": messageId,
      "emoji": emoji,
      "roomId": rid,
      "user": {"_id": userId, "first_name": firstName, "last_name": lastName},
    };
    socket!.emit('updated_reaction', [reactionObject]);
  }

  void removeReaction({
    required String messageId,
    required String conversationId,
    required String emoji,
    required String userId,
    required String firstName,
    required String lastName,
  }) {
    if (!isConnected) return;
    socket!.emit('remove_reaction', {
      "messageId": messageId,
      "conversationId": conversationId,
      "emoji": emoji,
      "userId": userId,
    });
  }

  Future<void> toggleFavorite({
    required String targetId,
    required bool isCurrentlyFavorite,
  }) async {
    if (!isConnected) return;
    socket!.emitWithAck('toggle_favorite', {
      'targetId': targetId,
      'isFavourite': !isCurrentlyFavorite
    }, ack: (response) {
      try {
        if (response is Map && response['success'] == true) {
          Messenger.alertWithSvgImage(
              msg: isCurrentlyFavorite
                  ? "Group Removed From Favorites"
                  : "Group Added To Favorites");
        } else {
          Messenger.alertWithSvgImage(
              msg: response['message'] ?? "Error updating favorites");
        }
      } catch (e) {
        Messenger.alertWithSvgImage(msg: "Error updating favorites");
      }
    });
  }

  Future<void> updateGroupInfo({
    required String groupId,
    String? groupName,
    String? description,
    required String updateKey,
  }) async {
    if (!isConnected) return;
    socket!.emitWithAck('update_group', {
      'groupId': groupId,
      updateKey: groupName ?? description
    }, ack: (response) {
      try {
        if (response is Map && response['success'] == true) {
          Messenger.alertWithSvgImage(msg: "Group Updated Successfully");
        } else {
          Messenger.alertWithSvgImage(
              msg: response['message'] ?? "Failed to update group");
        }
      } catch (e) {
        Messenger.alertWithSvgImage(msg: "Failed to update group");
      }
    });
  }

  void sendMessage({
    required String messageId,
    String? conversationId,
    required String senderId,
    required String receiverId,
    required String message,
    required String roomId,
    required String workspaceId,
    required bool isGroupChat,
    String? mimeType,
    String? contentType,
    String? fileName,
    String? thumbnailKey,
    String? originalKey,
    String? thumbnailUrl,
    String? originalUrl,
    int? size,
    bool fileWithText = false,
    bool isReplyMessage = false,
    Map<String, dynamic>? reply,
    Function(Map<String, dynamic>)? ackCallback,
    Function(Map<String, dynamic>)? onPendingMessage,
    String? userName,
    required bool isGroupMessage,
    String? groupMessageId,
    String? audioDuration,
  }) {
    if (!isConnected) {
      _slog('sendMessage aborted: not connected');
      return;
    }

    final messagePayload = {
      "messageId": messageId,
      "conversationId": conversationId,
      "sender": senderId,
      "receiver": receiverId,
      "message": message,
      "roomId": roomId,
      "workspaceId": workspaceId,
      "isGroupChat": isGroupChat,
      "groupId": isGroupChat ? receiverId : "",
      "userName": userName,
      "ContentType": contentType ?? "file",
      "mimeType": mimeType,
      "file_with_text": fileWithText,
      "fileWithText": fileWithText,
      "fileName": fileName,
      "size": size,
      "thumbnailkey": thumbnailKey,
      "originalKey": originalKey,
      "thumbnailUrl": thumbnailUrl,
      "originalUrl": originalUrl,
      "timestamp": DateTime.now().toIso8601String(),
      "messageType": "sent",
      "is_grouped_message": isGroupMessage,
      "group_message_id": groupMessageId,
      "duration": audioDuration,
      "isReplyMessage": reply != null || isReplyMessage,
      if (reply != null)
        "reply": {
          "replyToUser": reply["sender"]?["_id"],
          "replyToMessage": reply["message_id"] ?? reply["_id"] ?? reply["id"],
          "replyContent": reply["content"] ?? reply["replyContent"] ?? "",
          "ContentType": reply["ContentType"] ?? "text",
          "fileName": reply["fileName"],
          "first_name": reply["sender"]?["first_name"] ?? "",
          "last_name": reply["sender"]?["last_name"] ?? "",
          "originalUrl": reply["originalUrl"],
          "thumbnailUrl": reply["thumbnailUrl"],
          "isGroupedMessageId": reply["group_message_id"],
          "isGroupedMessage": reply["is_grouped_message"] == true,
        },
    };
    log("sending message payload : $messagePayload");

    socket!.emitWithAck(
      'send_message',
      messagePayload,
      ack: (data) {
        log('🟢 SEND_MESSAGE ACK RECEIVED');
        log('🕒 Time: ${DateTime.now().toIso8601String()}');
        log('📦 ACK Payload: $data');

        if (data is! Map) {
          log('⚠ ACK is not a Map: ${data.runtimeType}');
          return;
        }

        // 🔑 1️⃣ conversation id (MOST IMPORTANT)
        final String? convoId = data['convoId']?.toString();

        // 🔑 2️⃣ message object
        final Map<String, dynamic>? msg =
            data['msg'] is Map ? Map<String, dynamic>.from(data['msg']) : null;

        // 🔑 3️⃣ real message id
        final String? serverMessageId =
            msg?['message_id'] ?? msg?['id'] ?? data['messageId'];

        // 🔑 4️⃣ status
        final String status = msg?['messageStatus'] ?? data['status'] ?? 'sent';

        log('✅ convoId: $convoId');
        log('✅ serverMessageId: $serverMessageId');
        log('✅ status: $status');

        // 🔥 FIRST MESSAGE → SET ACTIVE CONVERSATION
        if (convoId != null && convoId.isNotEmpty) {
          setActiveConversation(convoId);
        }

        // 🔥 SEND CLEAN ACK TO BLoC / UI
        if (ackCallback != null) {
          ackCallback({
            'convoId': convoId,
            'messageId': serverMessageId,
            'status': status,
            'msg': msg,
            'raw': data,
          });
        }
      },
    );
  }

  String generateRoomId(String a, String b) {
    final ids = [a, b]..sort();
    return ids.join('_');
  }

  Future<void> pinUnpinChat({
    required String conversationId,
    required bool nextPinnedState,
  }) async {
    if (!isConnected) return;
    socket!.emit('chat:pin', {
      'action': nextPinnedState,
      'convoIds': [conversationId],
    });
  }

  // ========================
  // Cleanup
  // ========================
  void dispose() {
    _typingTimeout?.cancel();

    // ❌ DO NOT close StreamControllers here
    // They must survive logout/login

    socket?.clearListeners();
    socket?.disconnect();
    socket?.dispose();
    socket = null;

    _joinedRooms.clear();
    _isInitialized = false;
    _isConnecting = false;

    _slog('SocketService disposed (streams preserved)');
  }

  void disconnect() {
    _typingTimeout?.cancel();
    socket?.clearListeners();
    socket?.disconnect();

    _slog('SocketService disconnected');
  }

  /// Call this ONLY on LOGOUT
  void resetForLogout() {
    _activeConversationId = null;
    _joinedRooms.clear();
    processedMessageIds.clear();

    socket?.clearListeners();
    socket?.disconnect();
    socket?.dispose();
    socket = null;

    _isInitialized = false;
    _isConnecting = false;

    _slog('SocketService reset for logout (safe)');
  }
}
