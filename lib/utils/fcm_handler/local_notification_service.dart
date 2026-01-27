

// import 'dart:io';
// import 'dart:typed_data';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:dio/dio.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:image/image.dart' as img;

// class LocalNotificationService {
//   static final FlutterLocalNotificationsPlugin _plugin =
//       FlutterLocalNotificationsPlugin();

//   static bool _initialized = false;

//   static String? _lastAvatar;
//   static String? _lastTitle;
//   static String? _lastBody;

//   // ✅ DUPLICATE FILTER
//   static final Set<String> _handledMessages = {};

//   // ================= BACKGROUND ACTION HANDLER =================
//   @pragma('vm:entry-point')
//   static void notificationTapBackground(NotificationResponse response) {
//     print("🔥 BG ACTION: ${response.actionId}");
//   }

//   // ================= INIT =================
//   static Future<void> initialize() async {
//     if (_initialized) return;
//     _initialized = true;

//     const androidSettings =
//         AndroidInitializationSettings('@mipmap/ic_launcher');

//     await _plugin.initialize(
//       const InitializationSettings(android: androidSettings),
//       onDidReceiveNotificationResponse: _handleNotificationResponse,
//       onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
//     );

//     const channel = AndroidNotificationChannel(
//       'chat_messages',
//       'Chat Messages',
//       description: 'Chat Notifications',
//       importance: Importance.max,
//       playSound: true,
//       enableVibration: true,
//       showBadge: true,
//     );

//     await _plugin
//         .resolvePlatformSpecificImplementation<
//             AndroidFlutterLocalNotificationsPlugin>()
//         ?.createNotificationChannel(channel);

//     print("🔥 Notification System Ready");
//   }

//   // ================= HANDLE ACTIONS =================
//   @pragma('vm:entry-point')
//   static void _handleNotificationResponse(NotificationResponse res) {
//     print("🔥 ACTION CLICKED: ${res.actionId}");

//     if (res.actionId == 'REPLY_ACTION') {
//       print("🔥 Reply Text = ${res.input}");

//       if (_lastTitle != null) {
//         Future.delayed(const Duration(milliseconds: 300), () {
//           _showInternal(_lastTitle!, _lastBody!, _lastAvatar);
//         });
//       }
//     }
//   }

//   // ================= AVATAR DOWNLOAD =================
//   static Future<String?> _downloadAvatar(String? url) async {
//     if (url == null || url.isEmpty) return null;

//     try {
//       final res = await Dio().get(
//         url,
//         options: Options(
//           responseType: ResponseType.bytes,
//           sendTimeout: const Duration(seconds: 4),
//           receiveTimeout: const Duration(seconds: 4),
//         ),
//       );

//       final bytes = Uint8List.fromList(res.data);
//       if (bytes.length < 3000) return null;

//       final decoded = img.decodeImage(bytes);
//       if (decoded == null) return null;

//       final resized = img.copyResize(decoded, width: 128, height: 128);

//       final dir = await getTemporaryDirectory();
//       final file = File(
//           "${dir.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.png");

//       await file.writeAsBytes(img.encodePng(resized));
//       return file.path;
//     } catch (e) {
//       print("❌ Avatar download failed: $e");
//       return null;
//     }
//   }

//   // ================= MAIN SHOW =================
//   static Future<void> show(RemoteMessage msg) async {
//     // ✅ Prevent duplicate notifications
//     final id = msg.messageId ?? msg.data['id'] ?? msg.data.hashCode.toString();
//     if (_handledMessages.contains(id)) {
//       print("⚠️ Duplicate ignored: $id");
//       return;
//     }
//     _handledMessages.add(id);

//     // final title = msg.data['senderName'] ?? "New Message";
//     // final body = msg.data['message'] ?? "Message";
//     final title = msg.data['senderName'] ??
//         msg.data['title'] ??
//         msg.notification?.title ??
//         "New Message";

//     final body = msg.data['message'] ??
//         msg.data['body'] ??
//         msg.notification?.body ??
//         "Message";
//     final avatarUrl = msg.data['profilePic']?.toString();
//     final messid = msg.data['message_id']?.toString();

//     final avatarPath = await _downloadAvatar(avatarUrl);

//     _lastTitle = title;
//     _lastBody = body;
//     _lastAvatar = avatarPath;

//     await _showInternal(title, body, avatarPath);
//   }

//   // ================= INTERNAL SHOW =================
//   static Future<void> _showInternal(
//       String title, String body, String? avatarPath) async {
//     final person = Person(name: title);

//     const replyInput = AndroidNotificationActionInput(
//       label: "Reply...",
//       allowFreeFormInput: true,
//     );

//     final actions = [
//       AndroidNotificationAction(
//         'REPLY_ACTION',
//         'Reply',
//         inputs: [replyInput],
//         allowGeneratedReplies: true,
//         showsUserInterface: true,
//       ),
//       const AndroidNotificationAction('MARK_READ', 'Mark Read'),
//       const AndroidNotificationAction('MUTE_CHAT', 'Mute'),
//     ];

//     final style = avatarPath != null
//         ? BigPictureStyleInformation(
//             FilePathAndroidBitmap(avatarPath),
//             largeIcon: FilePathAndroidBitmap(avatarPath),
//           )
//         : MessagingStyleInformation(
//             person,
//             groupConversation: false,
//             messages: [Message(body, DateTime.now(), person)],
//           );

//     final androidDetails = AndroidNotificationDetails(
//       'chat_messages',
//       'Chat Messages',
//       importance: Importance.max,
//       priority: Priority.high,
//       category: AndroidNotificationCategory.message,
//       largeIcon: avatarPath != null ? FilePathAndroidBitmap(avatarPath) : null,
//       styleInformation: style,
//       actions: actions,
//     );

//     await _plugin.show(
//       DateTime.now().millisecondsSinceEpoch ~/ 1000,
//       title,
//       body,
//       NotificationDetails(android: androidDetails),
//     );
//   }
// }





import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static String? _lastAvatar;
  static String? _lastTitle;
  static String? _lastBody;

  /// ✅ Duplicate filter using message_id
  static final Set<String> _handledMessages = {};

  /// ================= LOGGER =================
  static void _log(String tag, dynamic value) {
    print("🟢 [$tag] => $value");
  }

  /// ================= BACKGROUND ACTION HANDLER =================
  @pragma('vm:entry-point')
  static void notificationTapBackground(NotificationResponse response) {
    _log("BG_ACTION_ID", response.actionId);
    _log("BG_INPUT", response.input);
    _log("BG_PAYLOAD", response.payload);
  }

  /// ================= INIT =================
  static Future<void> initialize() async {
    _log("INIT", "called");

    if (_initialized) {
      _log("INIT", "already initialized");
      return;
    }
    _initialized = true;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings),
      onDidReceiveNotificationResponse: _handleNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          notificationTapBackground,
    );

    const channel = AndroidNotificationChannel(
      'chat_messages',
      'Chat Messages',
      description: 'Chat Notifications',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _log("INIT", "Notification system READY");
  }

  /// ================= HANDLE ACTIONS =================
  @pragma('vm:entry-point')
  static void _handleNotificationResponse(NotificationResponse res) {
    _log("ACTION_CLICKED", res.actionId);
    _log("ACTION_INPUT", res.input);
    _log("ACTION_PAYLOAD", res.payload);

    if (res.actionId == 'REPLY_ACTION') {
      _log("REPLY_TEXT", res.input);

      if (_lastTitle != null && _lastBody != null) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _log("REPLY", "Re-showing notification");
          _showInternal(
            _lastTitle!,
            _lastBody!,
            _lastAvatar,
            DateTime.now().millisecondsSinceEpoch.toString(),
          );
        });
      }
    }
  }

  /// ================= AVATAR DOWNLOAD =================
  static Future<String?> _downloadAvatar(String? url) async {
    _log("AVATAR_URL", url);

    if (url == null || url.isEmpty) {
      _log("AVATAR", "No URL");
      return null;
    }

    try {
      final res = await Dio().get(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          sendTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
        ),
      );

      final bytes = Uint8List.fromList(res.data);
      _log("AVATAR_BYTES", bytes.length);

      if (bytes.length < 3000) {
        _log("AVATAR", "Too small, ignored");
        return null;
      }

      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        _log("AVATAR", "Decode failed");
        return null;
      }

      final resized = img.copyResize(decoded, width: 128, height: 128);

      final dir = await getTemporaryDirectory();
      final file = File(
          "${dir.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.png");

      await file.writeAsBytes(img.encodePng(resized));

      _log("AVATAR_SAVED", file.path);
      return file.path;
    } catch (e) {
      _log("AVATAR_ERROR", e);
      return null;
    }
  }

  /// ================= MAIN SHOW =================
  static Future<void> show(RemoteMessage msg) async {
    _log("FCM_RECEIVED", "-------------------------");

    _log("MSG_ID", msg.messageId);
    _log("MSG_DATA", msg.data);
    _log("MSG_NOTIFICATION", {
      "title": msg.notification?.title,
      "body": msg.notification?.body,
    });

    final String messageId =
        msg.data['message_id']?.toString() ??
        msg.messageId ??
        msg.data.hashCode.toString();

    _log("FINAL_MESSAGE_ID", messageId);

    if (_handledMessages.contains(messageId)) {
      _log("DUPLICATE", "Ignored => $messageId");
      return;
    }

    _handledMessages.add(messageId);
    _log("HANDLED_SET_SIZE", _handledMessages.length);

    if (_handledMessages.length > 200) {
      _handledMessages.clear();
      _log("HANDLED_SET", "Cleared");
    }

    final title = msg.data['senderName'] ??
        msg.data['title'] ??
        msg.notification?.title ??
        "New Message";

    final body = msg.data['message'] ??
        msg.data['body'] ??
        msg.notification?.body ??
        "Message";

    final avatarUrl = msg.data['profilePic']?.toString();

    _log("TITLE", title);
    _log("BODY", body);

    final avatarPath = await _downloadAvatar(avatarUrl);

    _lastTitle = title;
    _lastBody = body;
    _lastAvatar = avatarPath;

    await _showInternal(title, body, avatarPath, messageId);
  }

  /// ================= INTERNAL SHOW =================
  static Future<void> _showInternal(
    String title,
    String body,
    String? avatarPath,
    String messageId,
  ) async {
    _log("SHOW_INTERNAL", {
      "title": title,
      "body": body,
      "avatar": avatarPath,
      "messageId": messageId,
    });

    final person = Person(name: title);

    const replyInput = AndroidNotificationActionInput(
      label: "Reply...",
      allowFreeFormInput: true,
    );

    final actions = [
      AndroidNotificationAction(
        'REPLY_ACTION',
        'Reply',
        inputs: [replyInput],
        allowGeneratedReplies: true,
        showsUserInterface: true,
      ),
      const AndroidNotificationAction('MARK_READ', 'Mark Read'),
      const AndroidNotificationAction('MUTE_CHAT', 'Mute'),
    ];

    final style = avatarPath != null
        ? BigPictureStyleInformation(
            FilePathAndroidBitmap(avatarPath),
            largeIcon: FilePathAndroidBitmap(avatarPath),
          )
        : MessagingStyleInformation(
            person,
            groupConversation: false,
            messages: [
              Message(body, DateTime.now(), person),
            ],
          );

    final androidDetails = AndroidNotificationDetails(
      'chat_messages',
      'Chat Messages',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.message,
      largeIcon:
          avatarPath != null ? FilePathAndroidBitmap(avatarPath) : null,
      styleInformation: style,
      actions: actions,
    );

    final int notificationId = messageId.hashCode;

    _log("ANDROID_NOTIFY_ID", notificationId);

    await _plugin.show(
      notificationId,
      title,
      body,
      NotificationDetails(android: androidDetails),
    );

    _log("NOTIFICATION_SHOWN", "SUCCESS");
  }
}
