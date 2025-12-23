import 'dart:convert';
import 'package:nde_email/bridge_generated.dart/api.dart';
import 'package:nde_email/data/respiratory.dart';
import 'package:nde_email/presantation/chat/chat_list/chat_session_storage/chat_session.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'package:nde_email/presantation/chat/chat_list/chat_response_model.dart';
import 'package:nde_email/presantation/chat/model/emoj_model.dart';
import 'package:nde_email/utils/reusbale/common_import.dart';

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
  String? _lastSocketId;

  // Stream controllers (kept same)
  final StreamController<Map<String, dynamic>> _typingController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get typingStream => _typingController.stream;

  // final StreamController<String> _typingController =
  //     StreamController<String>.broadcast();
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

  // Stream getters (kept same)
  // Stream<String> get typingStream => _typingController.stream;
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

// 🔥 NEW — Fast UI notifier for online/offline
  final ValueNotifier<Map<String, dynamic>> userStatusNotifier =
      ValueNotifier({});

  bool get isConnected => socket?.connected ?? false;
  static final Set<String> processedMessageIds = <String>{};

  bool _isConnecting = false;
  final Completer<void> _connectionCompleter = Completer<void>();

  Function(List<Datu>)? _onChatListUpdatedCallback;
  void setChatListUpdateCallback(Function(List<Datu>) callback) {
    _onChatListUpdatedCallback = callback;
  }

  // Debug logging wrapper (quiet in release)
  void _slog(String msg) {
    if (!kReleaseMode) {
      // ignore: avoid_print
      print(msg.toString());
    }
  }

  // ------------------------
  // Public lifecycle helpers
  // ------------------------
  Future<void> ensureConnected() async {
    _slog("ensureConnected()");
    if (isConnected) return;
    if (_isConnecting) return _connectionCompleter.future;
    _isConnecting = true;
    try {
      final uid = await UserPreferences.getUserId() ?? '';
      await connectPrivateRoom(uid, uid, (_) {}, false);
      if (!_connectionCompleter.isCompleted) _connectionCompleter.complete();
    } catch (e) {
      if (!_connectionCompleter.isCompleted) {
        _connectionCompleter.completeError(e);
      }
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
      _slog('🔍 Attempting to connect to private chat WebSocket...');

      final userId = await UserPreferences.getUserId();
      final accessToken = await UserPreferences.getAccessToken();
      final defaultWorkspace = await UserPreferences.getDefaultWorkspace();
      _currentUserId = userId;
      currentWorkspaceId = defaultWorkspace;

      _slog(
          "➡ senderId: $senderId, receiverId: $receiverId, userId: $userId, workspace: $defaultWorkspace, isGroupchat: $isGroupchat");

      if (userId == null || accessToken == null || defaultWorkspace == null) {
        _slog('Missing user/session details; cannot connect.');
        throw Exception('Missing required user details');
      }

      await _createSocket(
        token: accessToken,
        clientId: userId,
        workspaceId: defaultWorkspace,
        senderId: senderId,
        receiverId: receiverId,
        onMessageReceived: onMessageReceived,
        isGroupchat: isGroupchat,
      );
    } catch (e) {
      _slog('❗ Error connecting to WebSocket: $e');
      rethrow;
    }
  }

  final Set<String> _registeredEvents = {};
  // ------------------------
  // Core socket creation
  // ------------------------
  Future<void> _createSocket({
    required String token,
    required String clientId,
    required String workspaceId,
    required String senderId,
    required String receiverId,
    required Function(Map<String, dynamic>) onMessageReceived,
    required bool isGroupchat,
    int maxRetries = 30,
    int reconnectDelayMs = 400,
  }) async {
    _socketCreationCount++;
    _slog('🔄 Socket creation attempt #$_socketCreationCount');
    _slog('📊 Previous socket ID: $_lastSocketId');
    const String socketUrl =
        //'https://api.nowdigitaleasy.com/wschat';
        "https://945067be4009.ngrok-free.app/wschat";

    // clean old socket
    try {
      socket?.disconnect();
    } catch (_) {}
    socket = null;

    socket = IO.io(
      socketUrl,
      IO.OptionBuilder()
          // /wschat
          .setPath('/socket.io')
          .setQuery({
            'token': 'Bearer $token',
            'userId': clientId,
            'workspaceId': workspaceId,
          })
          .setTransports(['websocket', 'polling'])
          .setReconnectionAttempts(maxRetries)
          .setReconnectionDelay(reconnectDelayMs)
          .setTimeout(10000)
          .build(),
    );

    socket!.onAny((event, data) {
      print("🔥 RAW USER PRESENCE EVENT → $event : $data");
    });

    // remove any generic onAny logging (was heavy)
    // setup handlers once
    _registerHandlers(senderId, receiverId, onMessageReceived, isGroupchat);

    // socket!.onConnect((_) {
    //   _slog('Socket connected successfully id=${socket!.id}');
    //   _joinWorkspace(workspaceId, clientId);
    // });
    socket!.onConnect((_) {
      _lastSocketId = socket!.id;
      _slog('✅ Socket connected successfully id=${socket!.id}');
      _slog('📊 Total sockets created: $_socketCreationCount');
      _joinWorkspace(workspaceId, clientId);
    });

    socket!.onConnectError((error) {
      _slog('Socket connection error: $error');
      _onlineStatusController.add(false);
    });

    socket!.onDisconnect((_) {
      _slog('Socket disconnected');
      _onlineStatusController.add(false);
    });

    socket!.onError((error) {
      _slog('Socket error: $error');
      _onlineStatusController.add(false);
    });

    // finally connect
    socket!.connect();
  }

  // ------------------------
  // Register all handlers once
  // ------------------------
  void _registerHandlers(
    String senderId,
    String receiverId,
    Function(Map<String, dynamic>) onMessageReceived,
    bool? isGroupchat,
  ) {
    if (socket == null) return;
    // final Set<String> _registeredEvents = {};

    // Ensure no duplicate handlers
    void reg(String event, Function(dynamic payload) handler) {
      if (socket == null) return;

      // Prevent duplicate listener registrations
      if (_registeredEvents.contains(event)) {
        socket!.off(event);
      }

      _registeredEvents.add(event);

      socket!.on(event, (payload) {
        handler(payload);
      });
    }

    // Connection join logic (kept original behavior)

    socket!.onConnect((_) {
      _slog('Socket connected successfully id=${socket!.id}');
      final wsId = currentWorkspaceId;
      final uid = _currentUserId;

      // 1️⃣ VERY IMPORTANT: Join workspace first
      if (wsId == null || uid == null) {
        _slog("❌ Missing workspaceId or userId in onConnect");
        return;
      }
      print(socket!.id);
      _slog("join_workspace -> {workspaceId: $wsId, userId: $uid}");
      // 1️⃣ Join workspace FIRST
      socket!.emit('join_workspace', {
        'workspaceId': wsId,
        'userId': uid,
      });
      _slog("join_workspace -> {workspaceId: $wsId, userId: $uid}");

      // 2️⃣ THEN join the actual chat room
      Future.delayed(const Duration(milliseconds: 150), () {
        if (isGroupchat == true) {
          final joinDataGrp = {"groupId": receiverId};
          socket!.emit("join_group_room", joinDataGrp);
          _slog("join_group_room -> $joinDataGrp");
        } else {
          final joinData = {"senderId": senderId, "receiverId": receiverId};
          socket!.emit("join_private_room", joinData);
          _slog("join_private_room -> $joinData");
        }
      });
    });

    //messageListUpdate

    // Room events
    reg(
        'roomJoined',
        (response) => scheduleMicrotask(() {
              _slog('roomJoined -> $response');
              _onlineStatusController.add(true);
              if (response is Map && response.containsKey('roomId')) {
                roommId = response['roomId']?.toString();
                saveRoomId(roommId!);
                _slog('Saved roomId $roommId');
              }
            }));

    reg(
        'workspaceRoomJoined',
        (response) => scheduleMicrotask(() {
              _slog('workspaceRoomJoined -> $response');
              if (response is Map) _onlineStatusController.add(true);
            }));

    // system message
    reg(
        'system_message',
        (data) => scheduleMicrotask(() {
              _slog('system_message -> $data');
              if (data is Map<String, dynamic>) {
                _systemMessageController.add(data);
              }
            }));

    // typing (single unified)
    reg(
      'get_typing',
      (response) => scheduleMicrotask(() {
        _slog('🔥 get_typing -> $response');

        final map = _firstMapFromPossibleList(response);
        if (map == null) return;

        // Ignore self typing
        if (map['userId'] == _currentUserId) return;

        final convoId = map['convoId'];
        final message = map['message'];

        if (convoId == null || message == null) return;

        _typingController.add({
          "convoId": convoId,
          "message": message,
        });

        _typingTimeout?.cancel();
        _typingTimeout = Timer(const Duration(seconds: 2), () {
          _typingController.add({});
        });
      }),
    );

    // reg(
    //       'get_typing',
    //       (response) => scheduleMicrotask(() {
    //             _slog('🔥 RAW get_typing received: $response');

    //             // Filter out self-typing
    //             if (response is List && response.isNotEmpty) {
    //               final first = response.first;
    //               if (first is Map && first['userId'] == _currentUserId) return;
    //             } else if (response is Map &&
    //                 response['userId'] == _currentUserId) {
    //               return;
    //             }

    //             final msg = _extractTypingMessage(response);
    //             _slog('🔥 Extracted typing msg: $msg');

    //             if (msg != null && msg.trim().isNotEmpty) {
    //               _typingController.add(msg.toString());
    //               _typingTimeout?.cancel();
    //               _typingTimeout = Timer(const Duration(seconds: 2), () {
    //                 _typingController.add('');
    //               });
    //             } else {
    //               _typingController.add('');
    //               _typingTimeout?.cancel();
    //             }
    //           }));

    // messagesRead
    reg(
        'messagesRead',
        (data) => scheduleMicrotask(() {
              _slog('messagesRead -> $data');
              final map = _firstMapFromPossibleList(data);
              if (map == null) return;
              final ids = (map['messageIds'] as List?)
                      ?.map((e) => e.toString())
                      .toList() ??
                  [];
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
            }));

    // updated_reaction (two shapes previously handled all ways)
    reg(
        'updated_reaction',
        (data) => scheduleMicrotask(() {
              _slog('updated_reaction -> $data');
              try {
                final raw = _extractFirstMap(data);
                if (raw == null) return;
                final reaction =
                    MessageReaction.fromMap(Map<String, dynamic>.from(raw));
                _reactionController.add(reaction);
              } catch (e) {
                _slog('updated_reaction parse error: $e');
              }
            }));

    // remove_reaction
    reg(
        'remove_reaction',
        (data) => scheduleMicrotask(() {
              _slog('remove_reaction -> $data');
              try {
                final raw = _extractFirstMap(data);
                if (raw == null) return;
                final reaction =
                    MessageReaction.fromMap(Map<String, dynamic>.from(raw));
                reaction.isRemoval = true;
                _reactionController.add(reaction);
              } catch (e) {
                _slog('remove_reaction parse error: $e');
              }
            }));

    // update_delivered
    reg(
        'update_delivered',
        (data) => scheduleMicrotask(() {
              _slog('update_delivered -> $data');

              // Handle both List and single Map
              final List listData = (data is List) ? data : [data];

              for (final item in listData) {
                if (item is! Map) continue;
                final ids = (item['messageIds'] as List?)
                        ?.map((e) => e.toString())
                        .toList() ??
                    [];

                // Fallback: if 'messageIds' is missing but 'messageId' exists
                if (ids.isEmpty && item['messageId'] != null) {
                  ids.add(item['messageId'].toString());
                }

                if (ids.isEmpty) continue;
                final rawStatus =
                    (item['messageStatus'] ?? item['status'] ?? 'delivered')
                        .toString();
                _statusUpdateController.add({
                  "status": rawStatus,
                  "messageStatus": rawStatus,
                  "roomId": item['roomId'],
                  "messageIds": ids,
                  "singleMessageId": ids.first,
                  "userId": item['userId'],
                  "time": item['time'],
                });
              }
            }));

    // message_delivered
    reg(
        'message_delivered',
        (data) => scheduleMicrotask(() {
              _slog('message_delivered -> $data');

              // Handle both List and single Map
              final List listData = (data is List) ? data : [data];

              for (final item in listData) {
                if (item is! Map<String, dynamic>) continue;
                if (!item.containsKey('messageId')) continue;
                final id = item['messageId'].toString();
                _statusUpdateController.add({
                  "status": "delivered",
                  "messageIds": [id],
                  "messageId": id,
                  ...item,
                });
              }
            }));

    // message_delivered_when_online
    reg(
        'message_delivered_when_online',
        (data) => scheduleMicrotask(() {
              _slog('message_delivered_when_online -> $data');
              try {
                if (data is List && data.isNotEmpty) {
                  final firstPayload = data.first;
                  if (firstPayload is Map && firstPayload['data'] is Map) {
                    final innerData = firstPayload['data'];
                    final messageId = innerData['messageId'];
                    final roomId = innerData['roomId'];
                    final convoId = innerData['convoId'];
                    if (messageId != null &&
                        roomId != null &&
                        convoId != null) {
                      _sendMessageDelivered(
                        messageIds: [messageId.toString()],
                        roomId: roomId.toString(),
                        convoId: convoId.toString(),
                      );
                    }
                  }
                }
              } catch (e) {
                _slog('message_delivered_when_online parse error: $e');
              }
            }));

    // forward_message -> delegate to provided callback (keeps same structure)
    reg(
        'forward_message',
        (payload) => scheduleMicrotask(() {
              _slog('forward_message -> $payload');
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
                _slog(
                    'forward_message unexpected payload ${payload.runtimeType}');
              }
            }));

    // update_message_read
    reg(
        'update_message_read',
        (data) => scheduleMicrotask(() {
              _slog('update_message_read -> $data');
              if (data is! List) return;
              for (final item in data) {
                if (item is! Map<String, dynamic>) continue;
                final msgId = item['messageId']?.toString() ??
                    item['message_id']?.toString();
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
            }));

    // user_online / user_offline
    reg(
        'user_online',
        (data) => scheduleMicrotask(() {
              _slog('user_online -> $data');
              _handleUserPresence(data, online: true);
            }));
    reg(
        'user_offline',
        (data) => scheduleMicrotask(() {
              _slog('user_offline -> $data');
              _handleUserPresence(data, online: false);
            }));

    // chatlistUpdate (binary/base64 preserved, Rust import unchanged)
    // reg(
    //   'chatlistUpdate',
    //   (payload) => scheduleMicrotask(() async {
    //     _slog('💥 chatlistUpdate received');

    //     try {
    //       final bytes = _decodeToBytes(payload);
    //       if (bytes == null) {
    //         _slog('chatlistUpdate: could not decode payload');
    //         return;
    //       }

    //       final jsonString = await importChatUpdate(updateBytes: bytes);
    //       final decoded = jsonDecode(jsonString);

    //       final chatList = decoded["chatDataList"] ?? [];
    //       final datuList =
    //           (chatList as List).map<Datu>((e) => Datu.fromJson(e)).toList();

    //       _onChatListUpdatedCallback?.call(datuList);
    //     } catch (e, st) {
    //       _slog('chatlistUpdate error: $e\n$st');
    //     }
    //   }),
    // );

    reg(
      'messageListUpdate',
      (payload) => scheduleMicrotask(() async {
        _slog('🔥 messageListUpdate received → $payload');

        try {
          // Payload usually comes as a list
          if (payload is! List || payload.isEmpty) return;

          final first = payload.first;
          if (first is! Map) return;

          final convoId = first['conversationId']?.toString();
          final rawUpdate = first['update'];

          if (convoId == null || rawUpdate == null) {
            _slog('❌ messageListUpdate missing data');
            return;
          }

          // 🔥 Convert update array → Uint8List
          final bytes = _bytesFromIntList(rawUpdate);
          if (bytes == null || bytes.isEmpty) {
            _slog('❌ messageListUpdate empty bytes');
            return;
          }

          // 🔥 Apply Loro update (DO NOT RESET DOC)
          final jsonString = await importChatUpdate(updateBytes: bytes);
          final decoded = jsonDecode(jsonString);

          final List list = decoded['chatDataList'] ?? [];
          if (list.isEmpty) {
            _slog('⚠️ messageListUpdate produced empty list – skipping');
            return;
          }

          final datuList = list.map<Datu>((e) => Datu.fromJson(e)).toList();

          // 🔥 SAVE incrementally
          ChatSessionStorage.saveChatList(datuList);

          // 🔥 Notify UI / BLoC
          _onChatListUpdatedCallback?.call(datuList);

          _slog(
            '✅ messageListUpdate applied → convo=$convoId, items=${datuList.length}',
          );
        } catch (e, st) {
          _slog('❌ messageListUpdate error: $e\n$st');
        }
      }),
    );

    reg(
      'chatlistUpdate',
      (payload) => scheduleMicrotask(() async {
        _slog('💥 chatlistUpdate received');

        try {
          final bytes = _decodeToBytes(payload);
          if (bytes == null || bytes.isEmpty) {
            _slog('❌ chatlistUpdate: empty payload');
            return;
          }

          // 🔥 APPLY INCREMENTAL UPDATE (DO NOT RESET DOC)
          final jsonString = await importChatUpdate(updateBytes: bytes);

          final decoded = jsonDecode(jsonString);
          final List list = decoded["chatDataList"] ?? [];

          // ⚠️ IMPORTANT: ignore empty CRDT updates
          if (list.isEmpty) {
            _slog('⚠️ chatlistUpdate produced empty list – skipping');
            return;
          }

          final datuList = list.map<Datu>((e) => Datu.fromJson(e)).toList();

          // 🔥 SAVE — DO NOT CLEAR
          ChatSessionStorage.saveChatList(datuList);

          // 🔥 NOTIFY UI / BLOC
          _onChatListUpdatedCallback?.call(datuList);

          _slog('✅ chatlistUpdate applied → ${datuList.length} chats');
        } catch (e, st) {
          _slog('❌ chatlistUpdate error: $e\n$st');
        }
      }),
    );

    // message_deleted
    reg(
        'message_deleted',
        (data) => scheduleMicrotask(() {
              _slog('message_deleted -> $data');
              if (data is Map<String, dynamic> &&
                  data.containsKey('messageId')) {
                _messageDeletedController.add(data['messageId'].toString());
              }
            }));

    // favorite_updated
    reg(
        'favorite_updated',
        (data) => scheduleMicrotask(() {
              _slog('favorite_updated -> $data');
              if (data is Map) {
                _favoriteUpdateController.add(Map<String, dynamic>.from(data));
              }
            }));

    // group_updated
    reg(
        'group_updated',
        (data) => scheduleMicrotask(() {
              _slog('group_updated -> $data');
              if (data is Map) {
                _groupUpdateController.add(Map<String, dynamic>.from(data));
              }
            }));

    // Incoming message events: listen to many possible names for compatibility with your backend
    final messageEventNames = [
      'receive_message'
          //'receiveMessage',
          'new_message',
      'message',
      'newMessage',
      'message_created',
      'send_message', // server echo
      'receive_group_message',
      'group_message',
    ];
    for (final ev in messageEventNames) {
      reg(
          ev,
          (payload) => scheduleMicrotask(() {
                _handleIncomingMessage(payload);
              }));
    }
  }

  Uint8List? _bytesFromIntList(dynamic raw) {
    try {
      if (raw is Uint8List) return raw;

      if (raw is List) {
        final ints = raw.whereType<int>().toList();
        if (ints.isEmpty) return null;
        return Uint8List.fromList(ints);
      }
    } catch (_) {}
    return null;
  }

  // ------------------------
  // Helper parsers & decoders
  // ------------------------
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

  String? _extractTypingMessage(dynamic payload) {
    if (payload == null) return null;
    if (payload is List && payload.isNotEmpty) {
      final first = payload.first;
      if (first is Map) {
        if (first.containsKey('userName')) {
          return "${first['userName']} is typing...";
        }
        if (first.containsKey('message')) {
          return first['message']?.toString();
        }
      }
      if (first is String) return first;
    } else if (payload is Map) {
      if (payload.containsKey('userName')) {
        return "${payload['userName']} is typing...";
      }
      if (payload.containsKey('message')) {
        return payload['message']?.toString();
      }
    } else if (payload is String) {
      return payload;
    }
    return null;
  }

  Uint8List? _decodeToBytes(dynamic payload) {
    if (payload == null) return null;
    if (payload is Uint8List) return payload;
    if (payload is String) {
      try {
        return base64Decode(payload);
      } catch (_) {
        return null;
      }
    }
    if (payload is List) {
      final binaryChunks = payload.whereType<Uint8List>().toList();
      final stringChunks = payload.whereType<String>().toList();
      if (binaryChunks.isNotEmpty) {
        final total = binaryChunks.fold<int>(0, (p, e) => p + e.length);
        final buffer = Uint8List(total);
        int offset = 0;
        for (final c in binaryChunks) {
          final next = offset + c.length;
          buffer.setRange(offset, next, c);
          offset = next;
        }
        return buffer;
      } else if (stringChunks.isNotEmpty) {
        try {
          return base64Decode(stringChunks.join());
        } catch (_) {
          return null;
        }
      }
    }
    return null;
  }

//get_typing -> [{message: Praveen is typing..., userId: 690044bd475feb6296eb1b14, convoId: 6943c3f06fce033b7d4253c5}, 1766049231277-2]
  void _handleUserPresence(dynamic data, {required bool online}) {
    try {
      // Extract raw userId from multiple possible message formats
      final rawId = (data is List && data.isNotEmpty) ? data[0] : data;
      if (rawId == null) return;

      final String userId = rawId.toString().trim();
      if (userId.isEmpty) return;

      // Update internal list
      if (online) {
        if (!onlineUsers.contains(userId)) {
          onlineUsers.add(userId);
        }
      } else {
        onlineUsers.remove(userId);
      }

      // 🚀 Instantly notify UI
      final statusMap = {
        "userId": userId,
        "status": online ? "online" : "offline",
      };
      userStatusNotifier.value = statusMap;
      _userStatusController.add(statusMap);

      _slog("Presence update: $userId → ${online ? 'online' : 'offline'}");
    } catch (e) {
      _slog("❌ Presence handler error: $e");
    }
  }

  // ------------------------
  // Incoming message handling (keeps original behavior)
  // ------------------------
  void _handleIncomingMessage(dynamic payload) {
    try {
      final map = _firstMapFromPossibleList(payload);
      if (map == null) {
        _slog('incoming message: payload not map -> ${payload.runtimeType}');
        return;
      }

      // keep duplicates prevention (cache limited)
      final msgId =
          (map['messageId'] ?? map['message_id'] ?? map['id'])?.toString();
      if (msgId != null && msgId.isNotEmpty) {
        if (processedMessageIds.contains(msgId)) {
          _slog('Skipping duplicate message $msgId');
          return;
        }
        processedMessageIds.add(msgId);
        if (processedMessageIds.length > 2000) {
          // trim cache
          final toRemove = processedMessageIds.length - 1000;
          final iter = processedMessageIds.toList().take(toRemove).toList();
          iter.forEach(processedMessageIds.remove);
        }
      }

      // preserve original behavior: emit raw map to message stream
      _messageController.add(Map<String, dynamic>.from(map));
    } catch (e, st) {
      _slog('incoming message error: $e $st');
    }
  }

  // ------------------------
  // Outgoing helpers (kept names/signatures)
  // ------------------------
  void _joinWorkspace(String workspaceId, String currentId) {
    if (socket == null || !isConnected) return;
    socket!.emit(
        'join_workspace', {'workspaceId': workspaceId, 'userId': currentId});
  }

  Future<void> saveRoomId(String rId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('roomId', rId);
    } catch (e) {
      _slog('saveRoomId error: $e');
    }
  }

  void sendTyping({required String roomId, required String userName}) {
    if (socket == null || !isConnected) {
      _slog('sendTyping aborted: socket not connected');
      return;
    }
    final typingData = {"roomId": roomId, "userName": userName};
    _slog('🚀 Sending typing event: $typingData');
    socket!.emit('get_typing', typingData);
    socket!.emit('typing', typingData);
  }

  void setUserOffline(String userId, String workspaceId) {
    if (socket == null || !isConnected) {
      _slog('setUserOffline aborted: socket not connected');
      return;
    }
    final payload = {"userId": userId, "workspaceId": workspaceId};
    socket!.emit("user_offline", payload);
  }

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
    _slog('message_delivered emitted: ${messageIds.length} ids');
  }

  void makeDelivered(
      {required List<String> messageIds, required String roomId}) {
    if (socket == null || !isConnected) return;
    socket!
        .emit('make_delivered', {'messageIds': messageIds, 'roomId': roomId});
    _slog('make_delivered emitted');
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
        socket == null ||
        !isConnected) {
      _slog('forwardMessage aborted: missing fields or socket not connected');
      return receiverIds
          .map((r) => {
                'receiverId': r,
                'success': false,
                'error': 'Socket not connected or missing fields'
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

      final completer = Completer<Map<String, dynamic>>();
      var completed = false;
      final timer = Timer(ackTimeout, () {
        if (!completed) {
          completed = true;
          completer.complete({
            'receiverId': receiverId,
            'success': false,
            'error': 'ACK timeout'
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
              'response': ackResponse
            };
            String? serverMessageId;
            if (ackResponse is Map) {
              if (ackResponse['data'] is Map) {
                serverMessageId =
                    ackResponse['data']['messageId']?.toString() ??
                        ackResponse['data']['message_id']?.toString();
              }
              serverMessageId = serverMessageId ??
                  ackResponse['messageId']?.toString() ??
                  ackResponse['message_id']?.toString() ??
                  ackResponse['id']?.toString();
              final successFlag = (ackResponse['success'] == true ||
                  ackResponse['status'] == 'success');
              entry['success'] = successFlag;
              if (serverMessageId != null) {
                entry['serverMessageId'] = serverMessageId;
              }
            }
            completer.complete(entry);
          } catch (e) {
            completer.complete({
              'receiverId': receiverId,
              'success': false,
              'error': 'Exception parsing ack: $e',
              'response': ackResponse
            });
          }
        });

        final result = await completer.future;
        results.add(Map<String, dynamic>.from(result));
      } catch (e) {
        timer.cancel();
        results.add({
          'receiverId': receiverId,
          'success': false,
          'error': 'Emit error: $e'
        });
      }

      await Future.delayed(const Duration(milliseconds: 40));
    }

    return results;
  }

  void sendReadReceipts({
    required List<String> messageIds,
    required String conversationId,
    required String roomId,
  }) {
    // _slog('sendReadReceipts -> $messageIds');
    if (socket == null || !socket!.connected) {
      _slog('sendReadReceipts aborted: socket not connected');
      return;
    }
    final payload = {
      "conversationId": conversationId,
      "roomId": roomId,
      "userId": _currentUserId,
      "messageIds": messageIds,
    };
    socket!.emit('read_messages', payload);
    //  _slog('read_messages emitted');
  }

  void deleteMessage({
    required String messageId,
    required String conversationId,
  }) {
    if (socket == null || !isConnected) {
      _slog('deleteMessage aborted: socket not connected');
      return;
    }
    socket!.emit('delete_message', {
      "messageId": messageId,
      "conversationId": conversationId,
    });
    _slog('delete_message emitted for $messageId');
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
      _slog('reactToMessage aborted: socket not connected');
      return;
    }
    try {
      final rid = generateRoomId(userId, receiverId);
      final reactionObject = {
        "conversationId": conversationId,
        "messageId": messageId,
        "emoji": emoji,
        "roomId": rid,
        "user": {"_id": userId, "first_name": firstName, "last_name": lastName},
      };
      final reactionPayload = [reactionObject];
      socket!.emit('updated_reaction', reactionPayload);
      _slog('updated_reaction emitted');
    } catch (e, st) {
      _slog('reactToMessage error: $e $st');
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
      _slog('removeReaction aborted: socket not connected');
      return;
    }
    final reactionPayload = {
      "messageId": messageId,
      "conversationId": conversationId,
      "emoji": emoji,
      "userId": userId,
    };
    socket!.emit('remove_reaction', reactionPayload);
    _slog('remove_reaction emitted');
  }

  Future<void> toggleFavorite({
    required String targetId,
    required bool isCurrentlyFavorite,
  }) async {
    if (socket == null || !isConnected) {
      _slog('toggleFavorite aborted: socket not connected');
      return;
    }
    try {
      final payload = {
        'targetId': targetId,
        'isFavourite': !isCurrentlyFavorite
      };
      socket!.emitWithAck('toggle_favorite', payload, ack: (response) {
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
    } catch (e) {
      _slog('toggleFavorite error: $e');
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
      _slog('updateGroupInfo aborted: socket not connected');
      return;
    }
    try {
      final payload = {'groupId': groupId, updateKey: groupName ?? description};
      socket!.emitWithAck('update_group', payload, ack: (response) {
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
    } catch (e) {
      _slog('updateGroupInfo error: $e');
      Messenger.alertWithSvgImage(msg: "Error updating group");
    }
  }

  // sendMessage kept same signature & behavior
  void sendMessage({
    required String messageId,
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
    String? groupMessageId,
  }) {
    if (socket == null || !isConnected) {
      _slog('sendMessage aborted: socket not connected');
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
          "isGroupedMessageId": reply["group_message_id"],
          "isGroupedMessage": reply["is_grouped_message"] == true,
        },
    };
    log("groupMessageId in socket $groupMessageId");
  

    socket!.emitWithAck('send_message', messagePayload, ack: (data) {
      try {
        if (ackCallback != null && data is Map<String, dynamic>) {
          ackCallback(data);
          log(data.toString());
        }
      } catch (e) {
        _slog('sendMessage ack parse error: $e');
      }
    });
    log("groupMessageId in socket $messagePayload");
  }

  String generateRoomId(String a, String b) {
    final ids = [a, b]..sort();
    return ids.join('_');
  }

  // ------------------------
  // Cleanup / disconnect
  // ------------------------
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
    _messageController.close();
    _typingTimeout?.cancel();

    if (socket != null) {
      // remove handlers that other code might reference
      try {
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
      } catch (e) {
        _slog('dispose off error: $e');
      }

      try {
        socket!.disconnect();
      } catch (_) {}
      socket = null;
    }
  }

  void disconnect() {
    _typingTimeout?.cancel();
    if (socket != null) {
      try {
        socket!.off('connect');
        socket!.off('roomJoined');
        socket!.off('workspaceRoomJoined');
        socket!.off('receiveMessage');
        socket!.off('send_message');
        socket!.off('join_private_room');
        socket!.off('join_workspace');
        socket!.off('connect_error');
        socket!.off('error');
      } catch (e) {
        _slog('disconnect off error: $e');
      }
    }
    _slog('SocketService.disconnect called');
  }
}
