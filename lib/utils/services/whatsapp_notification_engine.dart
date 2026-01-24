
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'avatar_cache_service.dart';

// class WhatsAppNotificationEngine {
//   static final _plugin = FlutterLocalNotificationsPlugin();
//   static bool _init = false;

//   static final Map<String, List<Message>> _chatHistory = {};

//   @pragma('vm:entry-point')
//   static void backgroundAction(NotificationResponse r) {
//     print("BG ACTION ${r.actionId}");
//   }

//   static Future<void> init() async {
//     if (_init) return;
//     _init = true;

//     const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

//     await _plugin.initialize(
//       const InitializationSettings(android: androidInit),
//       onDidReceiveNotificationResponse: _onAction,
//       onDidReceiveBackgroundNotificationResponse: backgroundAction,
//     );

//     const channel = AndroidNotificationChannel(
//       'chat_messages',
//       'Chat Messages',
//       importance: Importance.max,
//     );

//     await _plugin
//         .resolvePlatformSpecificImplementation<
//             AndroidFlutterLocalNotificationsPlugin>()
//         ?.createNotificationChannel(channel);
//   }

//   @pragma('vm:entry-point')
//   static void _onAction(NotificationResponse r) {
//     if (r.actionId == "REPLY") {
//       print("INLINE REPLY = ${r.input}");

//     }
//   }

//   // MAIN SHOW METHOD
//   static Future<void> show(RemoteMessage msg) async {
//     final data = msg.data;

//     final chatId = data["conversationId"];
//     final sender = data["senderName"] ?? "User";
//     final text = data["message"] ?? "";
//     final isImage = data["type"] == "image";
//     final avatarUserId = data["senderId"];
//     final avatarUrl = data["profilePic"];

//     // cache avatar earlier in app (WhatsApp does this)
//     final avatarPath =
//         await AvatarCacheService.getCachedAvatar(avatarUserId) ??
//             await AvatarCacheService.cacheAvatar(avatarUserId, avatarUrl);

//     final person = Person(name: sender);

//     // Store history
//     _chatHistory.putIfAbsent(chatId, () => []);
//     _chatHistory[chatId]!.add(Message(text, DateTime.now(), person));
//     if (_chatHistory[chatId]!.length > 5) {
//       _chatHistory[chatId]!.removeAt(0);
//     }

//     final actions = [
//       AndroidNotificationAction(
//         "REPLY",
//         "Reply",
//         inputs: [
//           AndroidNotificationActionInput(
//               label: "Reply...", allowFreeFormInput: true)
//         ],
//         showsUserInterface: true,
//       ),
//       const AndroidNotificationAction("MARK_READ", "Mark Read"),
//       const AndroidNotificationAction("MUTE", "Mute"),
//     ];

//     final style = isImage
//         ? BigPictureStyleInformation(
//             FilePathAndroidBitmap(data["imageUrl"]),
//             largeIcon:
//                 avatarPath != null ? FilePathAndroidBitmap(avatarPath) : null,
//           )
//         : MessagingStyleInformation(
//             person,
//             groupConversation: true,
//             messages: _chatHistory[chatId]!,
//           );

//     final details = AndroidNotificationDetails(
//       "chat_messages",
//       "Chat Messages",
//       importance: Importance.max,
//       priority: Priority.high,
//       category: AndroidNotificationCategory.message,
//       groupKey: "chat_$chatId",
//       largeIcon: avatarPath != null ? FilePathAndroidBitmap(avatarPath) : null,
//       styleInformation: style,
//       actions: actions,
//     );

//     await _plugin.show(
//       chatId.hashCode,
//       sender,
//       text,
//       NotificationDetails(android: details),
//     );
//   }
// }



 import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'avatar_cache_service.dart';

class WhatsAppNotificationEngine {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _init = false;

  static final Map<String, List<Message>> _chatHistory = {};

  // ================= BACKGROUND ACTION =================
  @pragma('vm:entry-point')
  static void backgroundAction(NotificationResponse r) {
    print("BG ACTION ${r.actionId}");
  }

  // ================= INIT =================
  static Future<void> init() async {
    if (_init) return;
    _init = true;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    await _plugin.initialize(
      const InitializationSettings(android: androidInit),
      onDidReceiveNotificationResponse: _onAction,
      onDidReceiveBackgroundNotificationResponse: backgroundAction,
    );

    const channel = AndroidNotificationChannel(
      'chat_messages',
      'Chat Messages',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // ================= ACTION HANDLER =================
  @pragma('vm:entry-point')
  static void _onAction(NotificationResponse r) {
    if (r.actionId == "REPLY") {
      print("INLINE REPLY = ${r.input}");
      // TODO: send reply to socket/API
    }
  }

  // ================= SHOW NOTIFICATION =================
  static Future<void> show(RemoteMessage msg) async {
    final data = msg.data;

    final chatId = data["conversationId"] ?? "default_chat";
    final sender = data["senderName"] ?? "User";
    final text = data["message"] ?? "";
    final avatarUserId = data["senderId"] ?? sender;
    final avatarUrl = data["profilePic"];

    // Avatar cache (disk)
    final avatarPath =
        await AvatarCacheService.getCachedAvatar(avatarUserId) ??
            await AvatarCacheService.cacheAvatar(avatarUserId, avatarUrl);

    final person = Person(name: sender);

    // Chat history (stack like WhatsApp)
    _chatHistory.putIfAbsent(chatId, () => []);
    _chatHistory[chatId]!.add(Message(text, DateTime.now(), person));
    if (_chatHistory[chatId]!.length > 5) {
      _chatHistory[chatId]!.removeAt(0);
    }

    final actions = [
      AndroidNotificationAction(
        "REPLY",
        "Reply",
        inputs: [
          AndroidNotificationActionInput(
            label: "Reply...",
            allowFreeFormInput: true,
          )
        ],
        showsUserInterface: true,
      ),
      const AndroidNotificationAction("MARK_READ", "Mark Read"),
      const AndroidNotificationAction("MUTE", "Mute"),
    ];

    // ✅ FORCE CHAT TEXT STYLE ONLY (NO BIG IMAGE)
    final style = MessagingStyleInformation(
      person,
      groupConversation: true,
      messages: _chatHistory[chatId]!,
    );

    final details = AndroidNotificationDetails(
      "chat_messages",
      "Chat Messages",
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.message,
      groupKey: "chat_$chatId",

      // Small avatar only
      largeIcon: avatarPath != null ? FilePathAndroidBitmap(avatarPath) : null,

      styleInformation: style,
      actions: actions,
    );

    await _plugin.show(
      chatId.hashCode,
      sender,
      text,
      NotificationDetails(android: details),
    );
  }
}
