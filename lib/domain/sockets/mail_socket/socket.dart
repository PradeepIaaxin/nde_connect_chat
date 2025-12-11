import 'dart:async';
import 'dart:convert';
import 'dart:developer';
// ignore: library_prefixes
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:nde_email/data/respiratory.dart';
import 'package:nde_email/domain/sockets/mail_socket/nottification.dart';
import 'package:intl/intl.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;

  WebSocketService._internal();

  IO.Socket? socket;
  final StreamController<String> _messageController =
      StreamController<String>.broadcast();
  Stream<String> get messages => _messageController.stream;

  bool get isConnected => socket?.connected ?? false;

  Future<void> connect() async {
    try {
      String? userId = await UserPreferences.getUserId();
      String? accessToken = await UserPreferences.getAccessToken();
      String? defaultWorkspace = await UserPreferences.getDefaultWorkspace();

      if (userId != null && accessToken != null && defaultWorkspace != null) {
        await connectSocket(accessToken, userId, defaultWorkspace);
      } else {}
    } catch (e) {
      log(e.toString());
    }
  }

  Future<void> connectSocket(
      String token, String clientId, String workspaceId) async {
    if (socket != null && socket!.connected) {
      return;
    }

    socket?.disconnect();
    socket = null;

    final String socketUrl = 'https://api.nowdigitaleasy.com/notify'
        '?token=Bearer $token&userId=$clientId&workspaceId=$workspaceId';

    socket = IO.io(
      socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setPath('/notify/socket.io')
          .setReconnectionAttempts(3)
          .setReconnectionDelay(2000)
          .setReconnectionDelayMax(5000)
          .setTimeout(20000)
          .disableAutoConnect()
          .build(),
    );

    socket!.connect();

    socket!.onConnect((_) {
      String room = '${clientId}_$workspaceId';
      socket!.emit('joinRoom', room);
    });
    socket!.on('user_online', (data) {
      log("🟢 USER ONLINE EVENT RECEIVED → $data");
    });
    socket!.on('nde_notifications', (data) async {
      try {
        if (data is List) {
          for (var item in data) {
            if (item is Map<String, dynamic>) {
              _handleNotification(item);
            } else if (item is String) {
              _tryParseAndHandleStringNotification(item);
            }
          }
        } else if (data is Map<String, dynamic>) {
          _handleNotification(data);
        } else if (data is String) {
          _tryParseAndHandleStringNotification(data);
        } else {}

        _messageController.add(json.encode(data));
      } catch (e) {
        log(e.toString());
      }
    });

    socket!.onConnectError((data) => log(' Connect Error: $data'));
    socket!.onError((error) => log(' Socket error: $error'));
  }

  void _handleNotification(Map<String, dynamic> message) {
    try {
      var payload = message['message'];

      if (payload is Map<String, dynamic>) {
        _showEmailNotification(payload);
      } else if (payload is List) {
        for (var item in payload) {
          if (item is Map<String, dynamic>) {
            _showEmailNotification(item);
          }
        }
      } else {}
    } catch (e) {
      log(e.toString());
    }
  }

  void _tryParseAndHandleStringNotification(String data) {
    try {
      if (!_isValidJson(data)) {
        return;
      }

      final Map<String, dynamic> jsonData = json.decode(data);
      _handleNotification(jsonData);
    } catch (e) {
      log(e.toString());
    }
  }

  bool _isValidJson(String str) {
    try {
      json.decode(str);
      return true;
    } catch (_) {
      return false;
    }
  }

  void _showEmailNotification(Map<String, dynamic> payload) {
    String fromName = payload['fromName'] ?? 'Unknown Sender';
    String fromAddress = payload['fromAddress'] ?? 'Unknown';
    String subject = payload['subject'] ?? 'No Subject';
    String message = payload['message'] ?? 'No message content';
    log(subject);

    // Validate and parse time field properly
    String time = payload.containsKey('time') && payload['time'] != null
        ? payload['time']
        : DateTime.now().toIso8601String();

    String formattedTime = _formatTime(time);

    // Notification Title and Body
    String title = fromAddress;
    String body = '$fromName\n$message\nTime: $formattedTime';

    NotificationService.showNotification(title: title, body: body);
  }

  void dispose() {
    _messageController.close();
    socket?.disconnect();
    socket = null;
  }

  String _formatTime(String time) {
    try {
      // Normalize the time string format
      DateTime emailTime;

      if (time.contains('T')) {
        // ISO8601 format: "2025-03-31T10:15:30Z"
        emailTime = DateTime.parse(time).toLocal();
      } else {
        // Fallback for other formats
        emailTime =
            DateFormat('yyyy-MM-dd HH:mm:ss').parse(time, true).toLocal();
      }

      DateTime now = DateTime.now();
      Duration difference = now.difference(emailTime);

      if (difference.inSeconds < 60) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} min ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hr ago';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else {
        return DateFormat('MMM dd, yyyy').format(emailTime);
      }
    } catch (e) {
      return 'Unknown Time';
    }
  }
}
