import 'dart:developer';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

/// 🔥 REQUIRED for Android background actions
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  log("BG ACTION: ${response.actionId}");
  log("BG INPUT: ${response.input}");
}

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

    await _plugin.initialize(
      settings: settings,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    const channel = AndroidNotificationChannel(
      'chat_channel',
      'Chat Messages',
      description: 'Chat notifications',
      importance: Importance.max,
      playSound: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

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
      log("❌ Avatar crop failed: $e");
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
      String? avatarPath;
      if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
        avatarPath = await _downloadAndMakeCircle(profileImageUrl);
      }

      /// ✅ Reply input
      const replyInput = AndroidNotificationActionInput(
        label: "Reply...",
        allowFreeFormInput: true,
      );

      /// ✅ Action buttons
      final actions = [
        AndroidNotificationAction(
          'REPLY_ACTION',
          'Reply',
          inputs: [replyInput],
          showsUserInterface: true,
        ),
        const AndroidNotificationAction('MARK_READ', 'Mark Read'),
      ];

      /// ✅ DUMMY PERSON (NO RIGHT IMAGE)
      const dummyPerson = Person(name: " ");

      final androidDetails = AndroidNotificationDetails(
        'chat_channel',
        'Chat Messages',
        channelDescription: 'Chat notifications',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableLights: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',

        groupKey: "chat_${chatId ?? "global"}",

        /// ✅ ONLY LEFT AVATAR
        largeIcon:
            avatarPath != null ? FilePathAndroidBitmap(avatarPath) : null,

        /// ❌ REMOVE RIGHT AVATAR (dummy person)
        styleInformation: MessagingStyleInformation(
          dummyPerson,
          groupConversation: false,
          messages: [
            Message(
              body,
              DateTime.now(),
              dummyPerson,
            ),
          ],
        ),

        actions: actions,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final int id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails:
            NotificationDetails(android: androidDetails, iOS: iosDetails),
      );

      log("✅ Notification shown ID=$id");
    } catch (e) {
      log("❌ Notification error: $e");
    }
  }
}
