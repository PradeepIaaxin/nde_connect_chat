import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/widgets.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // ================= INIT =================
  static Future<void> initialize() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidInit);
    await _plugin.initialize(settings);

    const channel = AndroidNotificationChannel(
      'chat_channel',
      'Chat Messages',
      description: 'Chat notifications',
      importance: Importance.max,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    print("✅ Local Notification Initialized");
  }

  // ================= DOWNLOAD IMAGE ONLY (SAFE FOR BG) =================
  static Future<String?> _downloadImage(String url) async {
    try {
      final response = await Dio().get(
        url,
        options: Options(responseType: ResponseType.bytes),
      );

      final dir = await getTemporaryDirectory();
      final file = File(
          "${dir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg");
      await file.writeAsBytes(response.data);

      return file.path;
    } catch (e) {
      print("❌ Image download failed: $e");
      return null;
    }
  }

  // ================= DOWNLOAD + CIRCLE (FOREGROUND ONLY) =================
  static Future<String?> _downloadAndMakeCircle(String url) async {
    try {
      final response = await Dio().get(
        url,
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = response.data;
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final paint = ui.Paint();

      final size = image.width.toDouble();
      final rect = ui.Rect.fromLTWH(0, 0, size, size);
      final rrect = ui.RRect.fromRectAndRadius(rect, ui.Radius.circular(size));

      canvas.clipRRect(rrect);
      canvas.drawImage(image, ui.Offset.zero, paint);

      final picture = recorder.endRecording();
      final img = await picture.toImage(size.toInt(), size.toInt());
      final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);

      final dir = await getTemporaryDirectory();
      final file = File(
          "${dir.path}/profile_circle_${DateTime.now().millisecondsSinceEpoch}.png");
      await file.writeAsBytes(pngBytes!.buffer.asUint8List());

      return file.path;
    } catch (e) {
      print("❌ Circle avatar failed: $e");
      return null;
    }
  }

  // ================= SHOW NOTIFICATION =================
  static Future<void> show(RemoteMessage message) async {
    print("🔥 FCM RECEIVED: ${message.data}");

    final title = message.notification?.title ??
        message.data["senderName"] ??
        "New Message";

    final body = message.notification?.body ??
        message.data["message"] ??
        "New chat message";

    final chatId = message.data["conversationId"] ?? "global_chat";
    final profileUrl = message.data["profilePic"];

    String? avatarPath;

    // Check app lifecycle (foreground or background)
    final lifecycle = WidgetsBinding.instance.lifecycleState;

    if (profileUrl != null && profileUrl.isNotEmpty) {
      if (lifecycle == AppLifecycleState.resumed) {
        // Foreground → make circle
        avatarPath = await _downloadAndMakeCircle(profileUrl);
      } else {
        // Background → simple download (NO UI ENGINE)
        avatarPath = await _downloadImage(profileUrl);
      }
    }

    final androidDetails = AndroidNotificationDetails(
      'chat_channel',
      'Chat Messages',
      channelDescription: 'Chat notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,

      // App icon fallback
      icon: '@mipmap/ic_launcher',

      // Group chat notifications
      groupKey: "chat_$chatId",

      // Profile avatar
      largeIcon: avatarPath != null ? FilePathAndroidBitmap(avatarPath) : null,

      // WhatsApp chat style
      styleInformation: MessagingStyleInformation(
        Person(name: title),
        messages: [
          Message(body, DateTime.now(), Person(name: title)),
        ],
      ),
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(android: androidDetails),
    );

    print("✅ Notification shown");
  }
}
