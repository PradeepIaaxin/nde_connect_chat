// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:nde_email/presantation/chat/chat_api_service/service/chat_api_service.dart';
// import 'awesome_notification_service.dart';

// @pragma('vm:entry-point')
// Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp();
//   await ChatApiService().init();
//   await AwesomeNotificationService.init();

//   await AwesomeNotificationService.show(message);
// }



import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:nde_email/presantation/chat/chat_api_service/service/chat_api_service.dart';
import 'awesome_notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await ChatApiService().init();
  await AwesomeNotificationService.init();
  await AwesomeNotificationService.show(message);
}
