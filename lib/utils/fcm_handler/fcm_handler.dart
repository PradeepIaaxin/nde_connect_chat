// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'local_notification_service.dart';

// Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   print("🔥 BACKGROUND FCM: ${message.data}");
//   await LocalNotificationService.initialize();
//   await LocalNotificationService.show(message);
// }



import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:nde_email/utils/services/whatsapp_notification_engine.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("🔥 BACKGROUND FCM: ${message.data}");
  
  await WhatsAppNotificationEngine.init();
  await WhatsAppNotificationEngine.show(message);
}
