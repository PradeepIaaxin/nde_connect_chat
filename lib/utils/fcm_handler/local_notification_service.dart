

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

  // ✅ DUPLICATE FILTER
  static final Set<String> _handledMessages = {};

  // ================= BACKGROUND ACTION HANDLER =================
  @pragma('vm:entry-point')
  static void notificationTapBackground(NotificationResponse response) {
    print("🔥 BG ACTION: ${response.actionId}");
  }

  // ================= INIT =================
  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings),
      onDidReceiveNotificationResponse: _handleNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
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

    print("🔥 Notification System Ready");
  }

  // ================= HANDLE ACTIONS =================
  @pragma('vm:entry-point')
  static void _handleNotificationResponse(NotificationResponse res) {
    print("🔥 ACTION CLICKED: ${res.actionId}");

    if (res.actionId == 'REPLY_ACTION') {
      print("🔥 Reply Text = ${res.input}");

      if (_lastTitle != null) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _showInternal(_lastTitle!, _lastBody!, _lastAvatar);
        });
      }
    }
  }

  // ================= AVATAR DOWNLOAD =================
  static Future<String?> _downloadAvatar(String? url) async {
    if (url == null || url.isEmpty) return null;

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
      if (bytes.length < 3000) return null;

      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      final resized = img.copyResize(decoded, width: 128, height: 128);

      final dir = await getTemporaryDirectory();
      final file = File(
          "${dir.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.png");

      await file.writeAsBytes(img.encodePng(resized));
      return file.path;
    } catch (e) {
      print("❌ Avatar download failed: $e");
      return null;
    }
  }

  // ================= MAIN SHOW =================
  static Future<void> show(RemoteMessage msg) async {
    // ✅ Prevent duplicate notifications
    final id = msg.messageId ?? msg.data['id'] ?? msg.data.hashCode.toString();
    if (_handledMessages.contains(id)) {
      print("⚠️ Duplicate ignored: $id");
      return;
    }
    _handledMessages.add(id);

    // final title = msg.data['senderName'] ?? "New Message";
    // final body = msg.data['message'] ?? "Message";
    final title = msg.data['senderName'] ??
        msg.data['title'] ??
        msg.notification?.title ??
        "New Message";

    final body = msg.data['message'] ??
        msg.data['body'] ??
        msg.notification?.body ??
        "Message";
    final avatarUrl = msg.data['profilePic']?.toString();
    final messid = msg.data['MessageId']?.toString();

    final avatarPath = await _downloadAvatar(avatarUrl);

    _lastTitle = title;
    _lastBody = body;
    _lastAvatar = avatarPath;

    await _showInternal(title, body, avatarPath);
  }

  // ================= INTERNAL SHOW =================
  static Future<void> _showInternal(
      String title, String body, String? avatarPath) async {
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
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(android: androidDetails),
    );
  }
}
