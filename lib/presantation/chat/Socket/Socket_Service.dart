import 'dart:convert';

import 'package:nde_email/data/respiratory.dart';
import 'package:nde_email/presantation/chat/chat_list/chat_response_model.dart';
import 'package:nde_email/presantation/chat/model/emoj_model.dart';
import 'package:nde_email/rust/api.dart/api.dart';
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

  // Stream controllers
  final StreamController<String> _typingController =
      StreamController<String>.broadcast();
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
  final StreamController<Map<String, dynamic>> _favoriteUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _groupUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Stream getters
  Stream<String> get typingStream => _typingController.stream;
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

  bool get isConnected => socket?.connected ?? false;
  static Set<String> processedMessageIds = {};

  bool _isConnecting = false;
  final Completer<void> _connectionCompleter = Completer<void>();

  Function(List<Datu>)? _onChatListUpdatedCallback;

  void setChatListUpdateCallback(Function(List<Datu>) callback) {
    _onChatListUpdatedCallback = callback;
  }

  // void _setupChatRefreshListener() {
  //   if (socket == null) return;

  //   socket!.on("refetch_chat_list", (response) {
  //     try {
  //       final chats = (response as List).map((e) => Datu.fromJson(e)).toList();
  //       _onChatListUpdatedCallback?.call(chats);
  //     } catch (e) {
  //       log("❌ Error parsing chat list from socket: $e");
  //     }
  //   });
  // }

  // void listenForGlobalEvents() {
  //   _setupChatRefreshListener();
  // }

  // void onSocketConnected() {
  //   log("⚡ Socket Connected! Ready to handle chats...");
  //   listenForGlobalEvents();
  // }

  Future<void> ensureConnected() async {
    log("connctiog.....");
    log(socket.toString());
    if (isConnected) {
      return;
    }
    if (_isConnecting) {
      return _connectionCompleter.future;
    }

    _isConnecting = true;
    try {
      await connectPrivateRoom(
        await UserPreferences.getUserId() ?? '',
        await UserPreferences.getUserId() ?? '',
        (_) {},
        false,
      );
      _connectionCompleter.complete();
    } catch (e) {
      _connectionCompleter.completeError(e);
      rethrow;
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> connectPrivateRoom(
    String senderId,
    String receiverId,
    Function(Map<String, dynamic>) onMessageReceived,
    bool isGroupchat,
  ) async {
    try {
      log('🔍 Attempting to connect to private chat WebSocket...');

      final userId = await UserPreferences.getUserId();
      final accessToken = await UserPreferences.getAccessToken();
      final defaultWorkspace = await UserPreferences.getDefaultWorkspace();
      _currentUserId = await UserPreferences.getUserId();
      currentWorkspaceId = defaultWorkspace;

      log("$userId..............");
      log("➡ senderId       : $senderId");
      log("➡ receiverId     : $receiverId");
      log("➡ userId         : $userId");
      log("➡ accessToken    : $accessToken");
      log("➡ workspace      : $defaultWorkspace");
      log("➡ currentUserId  : $_currentUserId");
      log("➡ isGroupchat    : $isGroupchat");

      if (userId == null || accessToken == null || defaultWorkspace == null) {
        log('  Missing user details: Cannot connect to WebSocket.');
        throw Exception('Missing required user details');
      }

      await grpCreatSocket(
        accessToken,
        userId,
        defaultWorkspace,
        senderId,
        receiverId,
        onMessageReceived,
        isGroupchat,
      );
    } catch (e) {
      log('❗ Error connecting to WebSocket: $e');
      rethrow;
    }
  }

  Future<void> grpCreatSocket(
    String token,
    String clientId,
    String workspaceId,
    String senderId,
    String receiverId,
    Function(Map<String, dynamic>) onMessageReceived,
    bool? isGroupchat, {
    int maxRetries = 3,
    int retryDelay = 2000,
  }) async {
    const String socketUrl = 'https://api.nowdigitaleasy.com/wschat';
    //"https://86b66c8cd7bd.ngrok-free.app/wschat";
    // 'https://api.nowdigitaleasy.com/wschat';
    int attempt = 0;

    Future<void> connectSocket() async {
      attempt++;
      log('Socket connection attempt $attempt');

      socket = IO.io(
        socketUrl,
        IO.OptionBuilder()

            ///wschat
            .setPath('/wschat/socket.io')
            .setQuery({
              'token': 'Bearer $token',
              'userId': clientId,
              'workspaceId': workspaceId,
            })
            .setTransports(['websocket', 'polling'])
            // .setTransports(['websocket'])
            .setReconnectionAttempts(5)
            .setReconnectionDelay(2000)
            .setReconnectionAttempts(30)
            .setReconnectionDelay(400)
            .setReconnectionDelayMax(3000)
            // .disableAutoConnect()
            .setTimeout(10000)
            //    .enableForceNew()
            //   .enableAutoConnect()
            .build(),
      );

      socket!.onAny((event, data) {
        print("📡 CLIENT EVENT RECEIVED → $event : $data");
      });

      _setupSocketListeners(
          senderId, receiverId, onMessageReceived, isGroupchat);

      socket!.onConnect((_) {
        log('Socket connected successfully');
        log(socket!.id.toString());
        // onSocketConnected();
        log("socket id : ${socket!.id.toString()}");
        attempt = 0;
        _joinWorkspace(workspaceId, clientId);
      });

      socket!.onConnectError((error) {
        log('Socket connection error: $error');
        if (attempt < maxRetries) {
          Future.delayed(Duration(milliseconds: retryDelay), connectSocket);
        } else {
          log('Max retry attempts ($maxRetries) reached');
        }
      });

      socket!.onDisconnect((_) => log('Socket disconnected'));
      socket!.connect();
    }

    await connectSocket();
  }

  void _joinWorkspace(String workspaceId, String currentId) {
    if (socket == null || !isConnected) return;

    log('Joining workspace: $workspaceId');
    socket!.emit('join_workspace', {
      'workspaceId': workspaceId,
      'userId': currentId,
    });
  }

  Future<void> saveRoomId(String roomId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('roomId', roomId);
    } catch (e) {
      log('Error saving roomId: $e');
    }
  }

  void sendTyping({
    required String roomId,
    required String userName,
    // required String userID,
  }) {
    if (socket == null || !isConnected) {
      log("⚠ Cannot send typing: Socket not connected");
      return;
    }

    final typingData = {
      "roomId": roomId,
      "userName": userName,
      // 'userId': userID,
    };

    log("⌨ Emitting typing: $typingData");
    socket!.emit('typing', typingData);
  }

  void _setupSocketListeners(
    String senderId,
    String receiverId,
    Function(Map<String, dynamic>) onMessageReceived,
    bool? isGroupchat,
  ) {
    if (socket == null) return;

    // Connection handlers
    socket!.onConnect((_) {
      log('Connected to private chat socket');
      log('Socket connected: ${socket!.connected}');

      Future.delayed(Duration(milliseconds: 200), () {
        final joinData = {"senderId": senderId, "receiverId": receiverId};
        final joinDataGrp = {"groupId": receiverId};

        log('📤 Emitting join_private_room: $joinData');
        log('📤 Emitting join_group_room : $joinDataGrp');

        if (isGroupchat == true) {
          socket!.emit("join_group_room", joinDataGrp);
          log("socket is entering a chat $joinDataGrp");
          log("currentUserId  $receiverId");
        } else {
          socket!.emit('join_private_room', joinData);
          log("socket is connecting a private room ");
        }
      });
    });

    // Room events
    socket!.on('roomJoined', (response) {
      log('🏠 Room joined with response: $response');
      _onlineStatusController.add(true);

      if (response is Map && response.containsKey('roomId')) {
        roommId = response['roomId'];
        final roomId = response['roomId'];
        saveRoomId(roomId);
        log('Received Room ID: $roommId');
      }
    });

    socket!.on('workspaceRoomJoined', (response) {
      log('🏢 Workspace room joined: $response');
      if (response is Map) {
        _onlineStatusController.add(true);
      }
    });

    // Chat events

    socket!.on('system_message', (data) {
      log('🖥 System message received: $data');
      if (data is Map<String, dynamic>) {
        _systemMessageController.add(data);
      }
    });

    socket!.on('get_typing', (response) {
      log(": get_typing -> $response");

      if (response is List && response.isNotEmpty) {
        final typingData = response.first;
        if (typingData is Map && typingData.containsKey('message')) {
          final message = typingData['message'];

          if (message != null && message.toString().trim().isNotEmpty) {
            _typingController.add('typing...');
            _typingTimeout?.cancel();
            _typingTimeout = Timer(Duration(seconds: 2), () {
              _typingController.add('');
            });
          } else {
            _typingController.add('');
            _typingTimeout?.cancel();
          }
        }
      }
    });

// Avoid registering the same listener twice
    // socket!.off('messagesRead');

    socket!.on('messagesRead', (data) {
      log("📘 messagesRead raw -> $data (${data.runtimeType})");

      Map<String, dynamic>? map;

      // Case 1: server sends a single Map
      if (data is Map) {
        map = Map<String, dynamic>.from(data);
      }
      // Case 2: server sends [ { ... }, "17647..." ]
      else if (data is List && data.isNotEmpty) {
        final firstMap = data.firstWhere(
          (e) => e is Map,
          orElse: () => null,
        );
        if (firstMap == null) {
          log("⚠️ messagesRead: list but no Map element");
          return;
        }
        map = Map<String, dynamic>.from(firstMap as Map);
      } else {
        log("⚠️ messagesRead: unknown payload shape");
        return;
      }

      // ✅ server sends messageIds: [...]
      final ids =
          (map['messageIds'] as List?)?.map((e) => e.toString()).toList() ?? [];

      if (ids.isEmpty) {
        log("ℹ️ messagesRead: empty messageIds, nothing to update");
        return;
      }

      final update = {
        "status": "read",
        "messageStatus": "read",
        "conversationId": map['conversationId'],
        "roomId": map['roomId'],
        "messageIds": ids, // 👈 list of ids
        "singleMessageId": ids.first,
        "userId": map['userId'],
      };

      log("📘 messagesRead → pushing: $update");
      _statusUpdateController.add(update);
    });

    // Reaction events
    socket!.on('updated_reaction', (data) {
      try {
        debugPrint('🔧 Raw reaction data: $data');

        // Handle both array and single object formats
        final reactionData = data is List ? data.first : data;

        if (reactionData is Map) {
          final messageReaction = MessageReaction(
            messageId: reactionData['messageId']?.toString() ?? '',
            conversationId: reactionData['conversationId']?.toString() ?? '',
            emoji: reactionData['emoji']?.toString() ?? '',
            isRemoval: false,
            user: User(
              id: reactionData['user']?['_id']?.toString() ?? '',
              firstName: reactionData['user']?['first_name']?.toString() ?? '',
              lastName: reactionData['user']?['last_name']?.toString() ?? '',
            ),
            reactedAt: DateTime.parse(reactionData['reacted_at']?.toString() ??
                DateTime.now().toIso8601String()),
          );

          _reactionController.add(messageReaction);
        }
      } catch (e, stackTrace) {
        debugPrint('❌ Error processing reaction update: $e');
        debugPrint(stackTrace.toString());
      }
    });

    socket!.on('update_delivered', (data) {
      log("📨 update_delivered raw -> $data");

      if (data is! List) return;

      for (var item in data) {
        if (item is! Map) continue;
        if (!item.containsKey('messageIds') || !item.containsKey('roomId'))
          continue;

        final ids =
            (item['messageIds'] as List?)?.map((e) => e.toString()).toList() ??
                [];
        if (ids.isEmpty) continue;

        // 👇 TAKE status FROM SERVER IF PRESENT
        final rawStatus =
            (item['messageStatus'] ?? item['status'] ?? 'delivered').toString();

        _statusUpdateController.add({
          "status": rawStatus, // ✅ could be "delivered" or "read"
          "messageStatus": rawStatus, // ✅ for compatibility with old code
          "roomId": item['roomId'],
          "messageIds": ids,
          "singleMessageId": ids.first,
          "userId": item['userId'],
          "time": item['time'],
        });

        log("📌 update Messages -> ${ids.join(', ')} in Room: ${item['roomId']} with status=$rawStatus");
      }
    });
    socket!.on('remove_reaction', (data) {
      try {
        debugPrint('🔧 Raw removal data: $data');

        final reactionData = data is List ? data.first : data;

        if (reactionData is Map) {
          final messageReaction = MessageReaction(
            messageId: reactionData['messageId']?.toString() ?? '',
            conversationId: reactionData['conversationId']?.toString() ?? '',
            emoji: reactionData['emoji']?.toString() ?? '',
            isRemoval: true,
            user: User(
              id: reactionData['userId']?.toString() ?? '',
              firstName: '',
              lastName: '',
            ),
            reactedAt: DateTime.now(),
          );

          _reactionController.add(messageReaction);
        }
      } catch (e, stackTrace) {
        debugPrint('❌ Error processing reaction removal: $e');
        debugPrint(stackTrace.toString());
      }
    });
    // Typing indicator
    socket!.on('get_typing', (response) {
      log(": get_typing -> $response");

      if (response is List && response.isNotEmpty) {
        final typingData = response.first;
        if (typingData is Map && typingData.containsKey('message')) {
          final message = typingData['message'];

          if (message != null && message.toString().trim().isNotEmpty) {
            _typingController.add('typing...');
            _typingTimeout?.cancel();
            _typingTimeout = Timer(Duration(seconds: 2), () {
              _typingController.add('');
            });
          } else {
            _typingController.add('');
            _typingTimeout?.cancel();
          }
        }
      }
    });

    // Message status events
    socket!.on('message_delivered', (data) {
      log("message_delivered: message_delivered -> $data");

      if (data is! List) return;

      for (var item in data) {
        if (item is! Map<String, dynamic>) continue;
        if (!item.containsKey('messageId')) continue;

        final id = item['messageId'].toString();

        _statusUpdateController.add({
          "status": "delivered", // ✅ unify name
          "messageIds": [id], // ✅ always a list
          "messageId": id,
          ...item, // keep any extra fields
        });
      }
    });

    socket!.on('message_delivered_when_online', (data) {
      print(" Event : message_delivered_when_online -> $data");

      try {
        // Check if the response is a list
        if (data is List && data.isNotEmpty) {
          final firstPayload = data.first;

          // Check if first element contains a 'data' map
          if (firstPayload is Map && firstPayload['data'] is Map) {
            final innerData = firstPayload['data'];

            final messageId = innerData['messageId'];
            final roomId = innerData['roomId'];
            final convoId = innerData['convoId'];

            log("🕒 Delivery info: roomId=$roomId, convoId=$convoId, messageId=$messageId");

            if (messageId != null && roomId != null && convoId != null) {
              _sendMessageDelivered(
                messageIds: [messageId.toString()],
                roomId: roomId,
                convoId: convoId,
              );
            } else {
              log("⚠️ Missing required fields in message_delivered_when_online payload.");
            }
          } else {
            log("⚠️ message_delivered_when_online: Missing 'data' map in payload.");
          }
        } else {
          log("⚠️ message_delivered_when_online: Expected List but got ${data.runtimeType}");
        }
      } catch (e) {
        log("❌ Error parsing message_delivered_when_online: $e");
      }
    });
    socket!.on('forward_message', (payload) {
      log('📥 forward_message: $payload');

      if (payload is Map) {
        onMessageReceived({
          'event': 'forward_message',
          'data': Map<String, dynamic>.from(payload),
        });
      } else if (payload is List &&
          payload.isNotEmpty &&
          payload.first is Map) {
        onMessageReceived({
          'event': 'forward_message',
          'data': Map<String, dynamic>.from(payload.first),
        });
      } else {
        log("⚠️ forward_message: unexpected payload type: ${payload.runtimeType}");
      }
    });

    // Reaction events
    socket!.on('updated_reaction', (data) {
      log("🔁 Reaction updated: $data");

      try {
        if (data is List && data.isNotEmpty) {
          final raw = data[0];
          if (raw is Map) {
            final reactionData = Map<String, dynamic>.from(raw);
            final reaction = MessageReaction.fromMap(reactionData);
            _reactionController.add(reaction);
            log("✅ Processed reaction: ${reaction.emoji} on message ${reaction.messageId}");
          }
        }
      } catch (e) {
        log("❌ Error processing updated reaction: $e");
      }
    });

    socket!.on('remove_reaction', (data) {
      log("🗑️ Reaction removed: $data");

      try {
        if (data is List && data.isNotEmpty) {
          final raw = data[0];
          if (raw is Map) {
            final reactionData = Map<String, dynamic>.from(raw);
            final reaction = MessageReaction.fromMap(reactionData);
            reaction.isRemoval = true;
            _reactionController.add(reaction);
            log("✅ Processed reaction removal: ${reaction.emoji} from message ${reaction.messageId}");
          }
        }
      } catch (e) {
        log("❌ Error processing reaction removal: $e");
      }
    });

    socket!.on('update_message_read', (data) {
      log("update_message_read -> $data");

      if (data is! List) {
        log("⚠️ update_message_read: expected List but got ${data.runtimeType}");
        return;
      }

      for (var item in data) {
        if (item is! Map<String, dynamic>) continue;
        if (!item.containsKey('messageId')) continue;

        final msgId =
            item['messageId']?.toString() ?? item['message_id']?.toString();
        if (msgId == null || msgId.isEmpty) continue;

        final update = {
          // 🔹 what PrivateChatScreen expects:
          "status": "read",
          "messageStatus": "read",

          // 🔹 IDs (your listener can handle List or String):
          "messageId": msgId,
          "messageIds": [msgId],

          // 🔹 forward other info if you like:
          "roomId": item['roomId'],
          "convoId": item['convoId'],
          "userId": item['userId'],
          "time": item['time'],
        };

        log("📘 update_message_read → pushing: $update");
        _statusUpdateController.add(update);
      }
    });

    // User status events
    // User status events

    // User status events
    // User status events
    socket!.on('user_online', (data) {
      log("🔵 user_online raw: $data");

      void handleOneUserId(dynamic rawId) {
        if (rawId == null) return;
        final userId = rawId.toString().trim();
        if (userId.isEmpty) return;

        if (!onlineUsers.contains(userId)) {
          onlineUsers.add(userId);
        }

        _userStatusController.add({
          "userId": userId,
          "status": "online",
        });

        log("✅ Marked user ONLINE: $userId | onlineUsers=$onlineUsers");
      }

      if (data is List && data.isNotEmpty) {
        // Case 1: single user → [userId, "1763963969809-0"]
        if (data[0] is! List) {
          handleOneUserId(data[0]);
        }
        // Case 2: multiple users → [[userId1, ...], [userId2, ...], ...]
        else {
          for (final item in data) {
            if (item is List && item.isNotEmpty) {
              handleOneUserId(item[0]);
            }
          }
        }
      } else {
        log("⚠️ user_online: unexpected payload -> ${data.runtimeType}");
      }
    });
    socket!.on('user_offline', (data) {
      log("🔴 user_offline raw: $data");

      void handleOneUserId(dynamic rawId) {
        if (rawId == null) return;
        final userId = rawId.toString().trim();
        if (userId.isEmpty) return;

        onlineUsers.remove(userId);

        _userStatusController.add({
          "userId": userId,
          "status": "offline",
        });

        log("✅ Marked user OFFLINE: $userId | onlineUsers=$onlineUsers");
      }

      if (data is List && data.isNotEmpty) {
        // Case 1: single user → [userId, "1763963969809-0"]
        if (data[0] is! List) {
          handleOneUserId(data[0]);
        }
        // Case 2: multiple users → [[userId1, ...], [userId2, ...], ...]
        else {
          for (final item in data) {
            if (item is List && item.isNotEmpty) {
              handleOneUserId(item[0]);
            }
          }
        }
      } else {
        log("⚠️ user_offline: unexpected payload -> ${data.runtimeType}");
      }
    });

    socket!.on("chatlistUpdate", (payload) async {
      print("💥 chatlistUpdate received");
      socket!.off("chatlistUpdate");

      try {
        Uint8List bytes;

        // CASE A: payload is Base64 STRING alone
        if (payload is String) {
          print("🔍 Base64 string received");
          bytes = base64Decode(payload);
        }

        // CASE B: payload is a List (mixed or not)
        else if (payload is List) {
          print("🔍 chatlistUpdate: List received → analyzing...");

          // Extract binary chunks only
          final binaryChunks = payload.whereType<Uint8List>().toList();

          // Extract string chunks (for base64)
          final stringChunks = payload.whereType<String>().toList();

          // CASE B1: Base64 inside list (no binary)
          if (binaryChunks.isEmpty && stringChunks.isNotEmpty) {
            print("🔍 Base64 inside List<String> received");
            final combined = stringChunks.join("");
            bytes = base64Decode(combined);
          }

          // CASE B2: Mixed list but we only use real Uint8List
          else if (binaryChunks.isNotEmpty) {
            print("🔍 Using ${binaryChunks.length} Uint8List chunks");

            final totalLength =
                binaryChunks.fold<int>(0, (sum, c) => sum + c.length);

            final buffer = Uint8List(totalLength);

            int offset = 0;
            for (final c in binaryChunks) {
              final nextOffset = offset + c.length;
              buffer.setRange(offset, nextOffset, c);
              offset = nextOffset;
            }

            bytes = buffer;
          } else {
            print("❌ Unsupported list format");
            return;
          }
        }

        // CASE C: direct binary
        else if (payload is Uint8List) {
          bytes = payload;
        } else {
          print("❌ Unsupported chatlistUpdate type: ${payload.runtimeType}");
          return;
        }

        print("✅ chatlistUpdate → decoded bytes: ${bytes.length} bytes");

        // Send to Rust
        final jsonString = await importChatUpdate(updateBytes: bytes);
        final decoded = jsonDecode(jsonString);

        final chatList = decoded["chatDataList"] ?? [];
        final datuList = chatList.map<Datu>((e) => Datu.fromJson(e)).toList();

        _onChatListUpdatedCallback?.call(datuList);
      } catch (e, st) {
        print("❌ chatlistUpdate error: $e\n$st");
      }
    });

    // Message deletion event
    socket!.on('message_deleted', (data) {
      log("🗑 Message deleted: $data");
      if (data is Map<String, dynamic> && data.containsKey('messageId')) {
        _messageDeletedController.add(data['messageId']);
      }
    });

    // Favorite update event
    socket!.on('favorite_updated', (data) {
      log("⭐ Favorite updated: $data");
      if (data is Map<String, dynamic>) {
        _favoriteUpdateController.add(data);
      }
    });

    // Group update event
    socket!.on('group_updated', (data) {
      log("🔄 Group updated: $data");
      if (data is Map<String, dynamic>) {
        _groupUpdateController.add(data);
      }
    });

    // Message events
    //socket!.onAny((event, data) => log("🔄 Event received: $event -> $data"));

    socket!.onAny((event, data) {
      if (event == 'updated_reaction' || event == 'remove_reaction') {
        debugPrint(
            '🔧 Raw socket data for $event: $data (${data.runtimeType})');
      }
    });

    listenToMessages(senderId, receiverId, onMessageReceived);

    // Connection status events
    // socket!.onDisconnect((_) {
    //   log("🔌 Socket disconnected");
    //   _onlineStatusController.add(false);
    // });

    socket!.onConnectError((data) {
      log('  Connect Error: $data');
      _onlineStatusController.add(false);
    });

    socket!.onError((error) {
      log('⚠ Socket error: $error');
      _onlineStatusController.add(false);
    });
  }

  void setUserOffline(String userId, String workspaceId) {
    // if (socket == null || !isConnected) {
    //   log("⚠ Cannot emit offline, socket not connected");
    //   return;
    // }

    final payload = {
      "userId": userId,
      "workspaceId": workspaceId,
    };

    print("📴 Emitting user_offline: $payload");
    socket!.emit("user_offline", payload);
  }

  // Message delivery methods
  void _sendMessageDelivered({
    required List<String> messageIds,
    required String roomId,
    required String convoId,
  }) {
    if (socket == null || !isConnected) return;

    final time = DateTime.now().toIso8601String();
    socket!.emit('message_delivered', {
      'messageIds': messageIds,
      'time': time,
      'roomId': roomId,
      'convoId': convoId,
    });

    log("📤 Sent message_delivered -> messageIds=$messageIds, time=$time, roomId=$roomId, convoId=$convoId");
  }

  void makeDelivered({
    required List<String> messageIds,
    required String roomId,
  }) {
    if (socket == null || !isConnected) return;

    socket!.emit('make_delivered', {
      'messageIds': messageIds,
      'roomId': roomId,
    });

    log("📤 Sent make_delivered for messages: $messageIds in room: $roomId");
  }

  // Message operations
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
        socket == null ||
        !isConnected) {
      log("⚠️ Missing required fields or socket not connected. Not emitting forward_message.");
      return receiverIds
          .map((r) => {
                'receiverId': r,
                'success': false,
                'error': 'Socket not connected or missing fields'
              })
          .toList();
    }

    try {
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
              "UserData": {
                "first_name": currentUserInfo['name'] ?? "",
              }
            }
          ],
          "messageIds": [
            {
              "messageId": originalMessageId,
              "forwardUserId": receiverId,
            }
          ],
          "isForwarded": true,
          "isOwnConvo": true,
          "contentType": contentType,
          "fileName": fileName,
          "image": image,
        };

        // We'll wait for ACK or timeout
        final completer = Completer<Map<String, dynamic>>();
        var completed = false;

        // Setup a timeout guard
        final timer = Timer(ackTimeout, () {
          if (!completed) {
            completed = true;
            completer.complete({
              'receiverId': receiverId,
              'success': false,
              'error': 'ACK timeout',
            });
          }
        });

        try {
          socket!.emitWithAck('forward_message', forwardPayload,
              ack: (ackResponse) {
            if (completed) return;
            completed = true;
            timer.cancel();

            try {
              final Map<String, dynamic> entry = {
                'receiverId': receiverId,
                'success': false,
                'response': ackResponse,
              };

              // Try to extract server message id from ACKRESP in a few common shapes
              String? serverMessageId;

              if (ackResponse is Map) {
                // Case: ackResponse may contain data -> messageId
                if (ackResponse['data'] is Map) {
                  serverMessageId =
                      ackResponse['data']['messageId']?.toString() ??
                          ackResponse['data']['message_id']?.toString();
                }
                // or top-level fields
                serverMessageId = serverMessageId ??
                    ackResponse['messageId']?.toString() ??
                    ackResponse['message_id']?.toString() ??
                    ackResponse['id']?.toString();
              }

              // success flag detection
              final successFlag = (ackResponse is Map &&
                  (ackResponse['success'] == true ||
                      ackResponse['status'] == 'success'));

              entry['success'] = successFlag;
              if (serverMessageId != null && serverMessageId.isNotEmpty) {
                entry['serverMessageId'] = serverMessageId;
              }

              completer.complete(entry);
            } catch (e) {
              completer.complete({
                'receiverId': receiverId,
                'success': false,
                'error': 'Exception parsing ack: $e',
                'response': ackResponse,
              });
            }
          });

          // Wait for the ack or timeout
          final result = await completer.future;
          results.add(Map<String, dynamic>.from(result));
        } catch (e) {
          timer.cancel();
          results.add({
            'receiverId': receiverId,
            'success': false,
            'error': 'Emit error: $e',
          });
        }

        // small throttle to avoid bursts
        await Future.delayed(const Duration(milliseconds: 40));
      }

      return results;
    } catch (e) {
      log("❌ forwardMessage exception: $e");
      return [
        {
          'receiverId': '',
          'success': false,
          'error': 'forwardMessage exception: $e',
        }
      ];
    }
  }

  void listenToMessages(
    String senderId,
    String receiverId,
    Function(Map<String, dynamic>) onMessageReceived,
  ) {
    if (socket == null) return;

    final roomId = generateRoomId(senderId, receiverId);
    log("📡 Listening in room: $roomId");

    // socket!.on('receive_message', (response) {
    //   log("📥 receive_message: ${response.runtimeType}  for room=$roomId");

    //   final messageIds = <String>[];
    //   bool hasValidMessage = false;

    //   void processMessage(Map<String, dynamic> message) {
    //     try {
    //       final data = message['data'] as Map<String, dynamic>?;
    //       if (data == null) return;

    //       final messageId = data['message_id']?.toString();
    //       if (messageId == null || messageId.isEmpty) return;

    //       // ✅ NO roomId filtering here. Let the screen filter by conversationId.
    //       onMessageReceived({
    //         'event': 'receive_message',
    //         'data': data,
    //       });

    //       // 🔥 Broadcast update via Stream (Unify receive_message)
    //       _messageController.add(data);

    //       messageIds.add(messageId);
    //       hasValidMessage = true;

    //       log("✅ Delivered socket message $messageId to UI listener");
    //     } catch (e) {
    //       log("❌ Error processing message: $e");
    //     }
    //   }

    //   if (response is List) {
    //     for (final item in response) {
    //       if (item is Map<String, dynamic>) processMessage(item);
    //     }
    //   } else if (response is Map<String, dynamic>) {
    //     processMessage(response);
    //   }

    //   if (hasValidMessage && messageIds.isNotEmpty) {
    //     final readPayload = {
    //       'messageIds': messageIds,
    //       'roomId': roomId,
    //       'timestamp': DateTime.now().toIso8601String(),
    //     };
    //     log("📤 Emitting read_message: $readPayload");
    //     socket!.emit('read_message', readPayload);
    //   }
    // });

    // socket!.on('update_message_read', (data) {
    //   log("🟢 Read receipt update: $data");
    //   if (data is List) {
    //     for (final item in data) {
    //       if (item is Map<String, dynamic>) {
    //         _statusUpdateController.add(item);
    //       }
    //     }
    //   } else if (data is Map<String, dynamic>) {
    //     _statusUpdateController.add(data);
    //   }
    // });

    socket!.onError((err) => log("❌ Socket error: $err"));
  }

  void sendReadReceipts({
    required List<String> messageIds,
    required String conversationId,
    required String roomId,
  }) {
    log("📤 Emitting read_messages: $messageIds");

    if (socket == null || !socket!.connected) {
      log("⚠ Socket not connected, cannot send read receipts");
      return;
    }

    final payload = {
      "conversationId": conversationId,
      "roomId": roomId,
      "userId": _currentUserId,
      "messageIds": messageIds, // 👈 IMPORTANT
    };

    log("📤 Emitting read_messagesss: $payload");
    socket!.emit('read_messages', payload);
  }

  void deleteMessage({
    required String messageId,
    required String conversationId,
  }) {
    if (socket == null || !isConnected) {
      log('⚠ Cannot delete message: Socket not connected');
      return;
    }

    log('Socket message delete requested...');
    log('Socket: $socket');
    log('Is connected: $isConnected');

    socket!.emit('delete_message', {
      "messageId": messageId,
      "conversationId": conversationId,
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
    if (socket == null || !isConnected) {
      log("⚠ Cannot send reaction: Socket not connected");
      return;
    }

    try {
      final roomId = generateRoomId(userId, receiverId); // ✅ correct room
      print("receiva room $receiverId,roomId ${userId}");
      final reactionObject = {
        "conversationId": conversationId,
        "messageId": messageId,
        "emoji": emoji,
        "roomId": roomId,
        "user": {
          // ✅ so server can broadcast user data
          "_id": userId,
          "first_name": firstName,
          "last_name": lastName,
        },
      };

      final reactionPayload = [reactionObject];

      log("📤 sending updated_reaction payload: $reactionPayload");
      socket!.emit('updated_reaction', reactionPayload);

      log('✅ Reaction emitted for message $messageId');
    } catch (e, stackTrace) {
      log('❌ Failed to send reaction: $e');
      log('Stack trace: $stackTrace');
    }
  }

  void removeReaction({
    required String messageId,
    required String conversationId,
    required String emoji,
    required String userId,
    required String firstName,
    required String lastName,
  }) {
    if (socket == null || !isConnected) {
      log('⚠ Cannot remove reaction: Socket not connected');
      return;
    }

    final reactionPayload = {
      "messageId": messageId,
      "conversationId": conversationId,
      "emoji": emoji,
      "userId": userId,
    };

    log('📤 Removing reaction: $reactionPayload');
    socket!.emit('remove_reaction', reactionPayload);
  }

  // New methods for favorite and group updates
  Future<void> toggleFavorite({
    required String targetId,
    required bool isCurrentlyFavorite,
  }) async {
    if (socket == null || !isConnected) {
      log('⚠ Cannot toggle favorite: Socket not connected');
      return;
    }

    try {
      final payload = {
        'targetId': targetId,
        'isFavourite': !isCurrentlyFavorite,
      };

      log('⭐ Toggling favorite for $targetId');
      socket!.emitWithAck('toggle_favorite', payload, ack: (response) {
        if (response is Map && response['success'] == true) {
          log('✅ Favorite toggled successfully');
          Messenger.alertWithSvgImage(
              msg: isCurrentlyFavorite
                  ? "Group Removed From Favorites"
                  : "Group Added To Favorites");
        } else {
          log('❌ Failed to toggle favorite: ${response['message']}');
          Messenger.alertWithSvgImage(
              msg: response['message'] ?? "Error updating favorites");
        }
      });
    } catch (e) {
      log('❌ Error toggling favorite: $e');
      Messenger.alertWithSvgImage(msg: "Error updating favorites");
    }
  }

  Future<void> updateGroupInfo({
    required String groupId,
    String? groupName,
    String? description,
    required String updateKey,
  }) async {
    if (socket == null || !isConnected) {
      log('⚠ Cannot update group: Socket not connected');
      return;
    }

    try {
      final payload = {
        'groupId': groupId,
        updateKey: groupName ?? description,
      };

      log('🔄 Updating group $groupId: $updateKey=${groupName ?? description}');
      socket!.emitWithAck('update_group', payload, ack: (response) {
        if (response is Map && response['success'] == true) {
          log('✅ Group updated successfully');
          Messenger.alertWithSvgImage(msg: "Group Updated Successfully");
        } else {
          log('❌ Failed to update group: ${response['message']}');
          Messenger.alertWithSvgImage(
              msg: response['message'] ?? "Failed to update group");
        }
      });
    } catch (e) {
      log('❌ Error updating group: $e');
      Messenger.alertWithSvgImage(msg: "Error updating group");
    }
  }

  // void sendMessage({
  //   required String messageId,
  //   required String conversationId,
  //   required String senderId,
  //   required String receiverId,
  //   required String message,
  //   required String roomId,
  //   required String workspaceId,
  //   required bool isGroupChat,
  //   String? mimeType,
  //   String? contentType,
  //   String? fileName,
  //   String? thumbnailKey,
  //   String? originalKey,
  //   String? thumbnailUrl,
  //   String? originalUrl,
  //   int? size,
  //   bool fileWithText = false,
  //   bool isReplyMessage = false,
  //   Map<String, dynamic>? reply,
  //   Function(Map<String, dynamic>)? ackCallback,
  //   Function(Map<String, dynamic>)? onPendingMessage,
  //   String userName = "Pavi",
  // }) {
  //   if (socket == null || !isConnected) {
  //     log('⚠ Cannot send message: Socket not connected');
  //     return;
  //   }

  //   log(reply.toString());

  //   final messagePayload = {
  //     "messageId": messageId,
  //     "conversationId": conversationId,
  //     "sender": senderId,
  //     "receiver": receiverId,
  //     "message": message,
  //     "roomId": roomId,
  //     "workspaceId": workspaceId,
  //     "isGroupChat": isGroupChat,
  //     "groupId": isGroupChat ? receiverId : "",
  //     "userName": userName,
  //     "ContentType": contentType ?? "file",
  //     "mimeType": mimeType,
  //     "file_with_text": fileWithText,
  //     "fileWithText": fileWithText,
  //     "fileName": fileName,
  //     "size": size,
  //     "thumbnailkey": thumbnailKey,
  //     "originalKey": originalKey,
  //     "thumbnailUrl": thumbnailUrl,
  //     "originalUrl": originalUrl,
  //     "timestamp": DateTime.now().toIso8601String(),
  //     "messageType": "sent",
  //     "isReplyMessage": reply == null ? isReplyMessage : true,
  //     if (reply != null)
  //       "reply": {
  //         "userId": reply["sender"]?["_id"],
  //         "id": reply["message_id"],
  //         "mimeType": reply["mimeType"],
  //         "ContentType": reply["ContentType"],
  //         "replyContent": reply["content"],
  //         "replyToUSer": reply["sender"]?["_id"],
  //         "fileName": reply["fileName"] ?? "",
  //         "first_name": reply["sender"]?["first_name"],
  //         "last_name": reply["sender"]?["last_name"],
  //       },
  //   };

  //   log('📤 Sending message: ${messagePayload.toString()}');

  //   socket!.emitWithAck(
  //     'send_message',
  //     messagePayload,
  //     ack: (data) {
  //       log(' Acknowledgment received: $data');
  //       if (ackCallback != null && data is Map<String, dynamic>) {
  //         ackCallback(data);
  //       }
  //     },
  //   );

  //   log('📤 EmitWithAck called');
  // }

  void sendMessage(
      {required String messageId,
      required String conversationId,
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
      String? groupMessageId}) {
    if (socket == null || !isConnected) {
      log('⚠ Cannot send message: Socket not connected');
      return;
    }

    log(reply.toString());
    print("hiiiiieee");
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
      "is_group_message": isGroupMessage,
      "group_message_id": groupMessageId,
      "isReplyMessage": reply == null ? isReplyMessage : true,
      if (reply != null)
        "reply": {
          "userId": reply["sender"]?["_id"],
          "id": reply["message_id"],
          "mimeType": reply["mimeType"],
          "ContentType": reply["ContentType"],
          "replyContent": reply["content"],
          "replyToUSer": reply["sender"]?["_id"],
          "fileName": reply["fileName"] ?? "",
          "first_name": reply["sender"]?["first_name"],
          "last_name": reply["sender"]?["last_name"],
        },
    };

    print('📤 Sending message: ${messagePayload.toString()}');

    socket!.emitWithAck(
      'send_message',
      messagePayload,
      ack: (data) {
        log(' Acknowledgment received: $data');
        if (ackCallback != null && data is Map<String, dynamic>) {
          ackCallback(data);
        }
      },
    );

    print('📤 EmitWithAck called');
  }

  String generateRoomId(String senderId, String receiverId) {
    final ids = [senderId, receiverId];
    ids.sort();
    return ids.join('_');
  }

  void dispose() {
    _typingController.close();
    _onlineStatusController.close();
    _statusUpdateController.close();
    _chatListRefreshController.close();
    _systemMessageController.close();
    _userStatusController.close();
    _reactionController.close();
    _messageDeletedController.close();
    _favoriteUpdateController.close();
    _groupUpdateController.close();
    _typingTimeout?.cancel();

    if (socket != null) {
      socket!.off('connect');
      socket!.off('roomJoined');
      socket!.off('workspaceRoomJoined');
      socket!.off('receiveMessage');
      socket!.off('forward_message');
      socket!.off('send_message');
      socket!.off('join_private_room');
      socket!.off('join_workspace');
      socket!.off('connect_error');
      socket!.off('error');
      socket!.disconnect();
      socket = null;
    }
  }

  void disconnect() {
    _typingTimeout?.cancel();

    if (socket != null) {
      socket!.off('connect');
      socket!.off('roomJoined');
      socket!.off('workspaceRoomJoined');
      socket!.off('receiveMessage');
      socket!.off('send_message');
      socket!.off('join_private_room');
      socket!.off('join_workspace');
      socket!.off('connect_error');
      socket!.off('error');
      // socket!.disconnect();
      // socket = null;
    }
    log('getting back  from private chat ');
  }
}
