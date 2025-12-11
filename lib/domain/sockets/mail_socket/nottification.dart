import 'dart:developer';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    final bool? initSuccess =
        await _notificationsPlugin.initialize(initializationSettings);

    if (initSuccess != null && initSuccess) {
      log(' Notification service initialized successfully');
    } else {
      log('  Notification service failed to initialize');
    }
  }

  static Future<void> requestPermission() async {
    var status = await Permission.notification.status;

    if (!status.isGranted) {
      final result = await Permission.notification.request();
      if (result.isGranted) {
        log(" Notification permissions granted.");
      } else {
        log("  Notification permissions denied.");
      }
    } else {
      log(" Notification permissions already granted.");
    }
  }

  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'email_channel_id',
        'Email Notifications',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
        playSound: true,
        enableLights: true,
        enableVibration: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      await _notificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        notificationDetails,
      );

      log('🔔 Notification shown: $title - $body');
    } catch (e) {
      log('  Error showing notification: $e');
    }
  }
}
