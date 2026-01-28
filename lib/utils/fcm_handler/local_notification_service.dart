import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// 🔥 MUST BE TOP LEVEL (Android background isolate requirement)
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  print("🔥 BG ACTION: ${response.actionId}");
  print("🔥 BG INPUT: ${response.input}");
  print("🔥 BG PAYLOAD: ${response.payload}");
}

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static String? _lastAvatar;
  static String? _lastTitle;
  static String? _lastBody;

  /// ✅ Duplicate prevention
  static final Set<String> _handledMessages = {};

  static void _log(String tag, dynamic value) {
    print("🟢 [$tag] => $value");
  }

  // ================= INIT =================
  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(
      settings: initSettings, // ✅ REQUIRED in v18+
      onDidReceiveNotificationResponse: _handleNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Android 13+ permission
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

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

    _log("INIT", "Notification System READY");
  }

  // ================= ACTION HANDLER =================
  @pragma('vm:entry-point')
  static void _handleNotificationResponse(NotificationResponse res) {
    _log("ACTION_ID", res.actionId);
    _log("INPUT", res.input);
    _log("PAYLOAD", res.payload);

    if (res.actionId == 'REPLY_ACTION') {
      _log("REPLY_TEXT", res.input);

      // Optional: re-show notification
      if (_lastTitle != null && _lastBody != null) {
        _showInternal(
          _lastTitle!,
          _lastBody!,
          _lastAvatar,
          DateTime.now().millisecondsSinceEpoch.toString(),
        );
      }
    }
  }

  // ================= AVATAR DOWNLOAD =================
  static Future<String?> _downloadAvatar(String? url) async {
    if (url == null || url.isEmpty) return null;

    try {
      final res = await Dio().get(
        url,
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = Uint8List.fromList(res.data);
      if (bytes.length < 3000) return null;

      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      final resized = img.copyResize(decoded, width: 128, height: 128);

      final dir = await getTemporaryDirectory();
      final file = File("${dir.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.png");

      await file.writeAsBytes(img.encodePng(resized));
      return file.path;
    } catch (e) {
      _log("AVATAR_ERROR", e);
      return null;
    }
  }

  // ================= FCM SHOW =================
  static Future<void> show(RemoteMessage msg) async {
    _log("FCM_DATA", msg.data);

    /// ✅ Prefer backend message_id
    final String messageId =
        msg.data['message_id']?.toString() ??
        msg.messageId ??
        msg.data.hashCode.toString();

    /// ✅ Prevent duplicates
    if (_handledMessages.contains(messageId)) {
      _log("DUPLICATE", messageId);
      return;
    }
    _handledMessages.add(messageId);

    if (_handledMessages.length > 200) _handledMessages.clear();

    final title = msg.data['senderName'] ??
        msg.notification?.title ??
        "New Message";

    final body = msg.data['message'] ??
        msg.notification?.body ??
        "Message";

    final avatarUrl = msg.data['profilePic'];

    final avatarPath = await _downloadAvatar(avatarUrl);

    _lastTitle = title;
    _lastBody = body;
    _lastAvatar = avatarPath;

    await _showInternal(title, body, avatarPath, messageId);
  }

  // ================= INTERNAL SHOW =================
  static Future<void> _showInternal(
    String title,
    String body,
    String? avatarPath,
    String messageId,
  ) async {
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
        showsUserInterface: true,
        allowGeneratedReplies: true,
      ),
      const AndroidNotificationAction('MARK_READ', 'Mark Read'),
      const AndroidNotificationAction('MUTE_CHAT', 'Mute'),
    ];

    final style = MessagingStyleInformation(
      person,
      groupConversation: false,
      messages: [Message(body, DateTime.now(), person)],
    );

    final androidDetails = AndroidNotificationDetails(
      'chat_messages',
      'Chat Messages',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.message,
      largeIcon: avatarPath != null ? FilePathAndroidBitmap(avatarPath) : null,
      styleInformation: style,
      actions: actions,
      showWhen: true,
      when: DateTime.now().millisecondsSinceEpoch,
    );

    /// ✅ Stable notification ID (no overwrite)
    final int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _plugin.show(
      id: notificationId,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(android: androidDetails),
      payload: messageId,
    );

    _log("NOTIFICATION", "SHOWN ID=$notificationId");
  }
}
