import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';
import 'local_notification_service.dart';



Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  print("🔥 BACKGROUND FCM: ${message.data}");

  await LocalNotificationService.initialize();
  await LocalNotificationService.show(message);
}
