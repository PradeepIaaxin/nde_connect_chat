import 'dart:developer';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // ================= INIT =================
  static Future<void> init() async {
    tz.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

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

    log("✅ Notification initialized");
  }

  // ================= PERMISSION =================
  static Future<void> requestPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        await Permission.notification.request();
      }
    }
  }

  // ================= DOWNLOAD + MAKE ROUND IMAGE =================
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
          "${dir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.png");
      await file.writeAsBytes(pngBytes!.buffer.asUint8List());

      return file.path;
    } catch (e) {
      log("❌ Avatar download/crop failed: $e");
      return null;
    }
  }

  // ================= SHOW NOTIFICATION =================
  static Future<void> showNotification({
    required String title,
    required String body,
    String? senderName,
    String? chatId,
    String? profileImageUrl,
  }) async {
    try {
      log("🔔 SHOW NOTIFICATION");
      log("TITLE: $title");
      log("BODY: $body");
      log("PROFILE: $profileImageUrl");

      // Download profile image
      String? avatarPath;
      if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
        avatarPath = await _downloadAndMakeCircle(profileImageUrl);
      }

      final androidDetails = AndroidNotificationDetails(
        'chat_channel',
        'Chat Messages',
        channelDescription: 'Chat notifications',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableLights: true,
        enableVibration: true,

        // App icon fallback
        icon: '@mipmap/ic_launcher',

        // Group messages
        groupKey: "chat_${chatId ?? "global"}",

        // Profile avatar
        largeIcon:
            avatarPath != null ? FilePathAndroidBitmap(avatarPath) : null,

        // WhatsApp chat style
        styleInformation: MessagingStyleInformation(
          Person(name: senderName ?? "User"),
          messages: [
            Message(
              body,
              DateTime.now(),
              Person(name: senderName ?? "User"),
            ),
          ],
        ),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      await _plugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        NotificationDetails(android: androidDetails, iOS: iosDetails),
      );

      log("✅ Notification shown");
    } catch (e) {
      log("❌ Notification error: $e");
    }
  }
}
