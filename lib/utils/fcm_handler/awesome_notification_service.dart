// import 'dart:developer';
// import 'package:awesome_notifications/awesome_notifications.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:nde_email/presantation/chat/chat_api_service/service/chat_api_service.dart';
// import 'package:nde_email/utils/reusbale/common_import.dart';
// import '../../presantation/chat/chat_private_screen/Private_Chat_Screen.dart';

// class AwesomeNotificationService {
//   static final Set<String> _handledMessages = {};

//   // ================= INIT =================
//   static Future<void> init() async {
//     await AwesomeNotifications().initialize(
//       null,
//       [
//         NotificationChannel(
//           channelKey: 'chat_channel',
//           channelName: 'Chat Messages',
//           channelDescription: 'Chat notifications',
//           importance: NotificationImportance.Max,
//           playSound: true,
//         ),
//       ],
//     );

//     bool allowed = await AwesomeNotifications().isNotificationAllowed();
//     if (!allowed) {
//       await AwesomeNotifications().requestPermissionToSendNotifications();
//     }

//     AwesomeNotifications().setListeners(
//       onActionReceivedMethod: _onAction,
//     );
//   }

//   // ================= ACTION HANDLER =================

//   @pragma('vm:entry-point')
//   static Future<void> _onAction(ReceivedAction action) async {
//     log("🔥 ACTION = ${action.buttonKeyPressed}");
//     log("🔥 LIFE = ${action.actionLifeCycle}");
//     log("🔥 PAYLOAD = ${action.payload}");

//     // ================= REPLY BUTTON =================
//     if (action.buttonKeyPressed == "REPLY") {
//       final replyText = action.buttonKeyInput;
//       final convoId = action.payload?["convoId"];
//       final otherUserId = action.payload?["senderId"];
//       final myUserId = action.payload?["receiverId"];

//       if (replyText == null ||
//           convoId == null ||
//           myUserId == null ||
//           otherUserId == null) {
//         log("❌ Missing reply data");
//         return;
//       }

//       await ChatApiService().init();

//       await ChatApiService().sendMessage(
//         conversationId: convoId,
//         senderId: myUserId,
//         receiverId: otherUserId,
//         content: replyText,
//       );

//       log("✅ Reply Sent WITHOUT OPENING APP");
//       return; // 🚨 STOP EVERYTHING HERE
//     }

//     // ================= MARK READ / MUTE =================
//     if (action.buttonKeyPressed == "MARK_READ" ||
//         action.buttonKeyPressed == "MUTE_CHAT") {
//       return;
//     }

//     // ================= OPEN CHAT ONLY ON NOTIFICATION TAP =================
//     if (action.buttonKeyPressed.isEmpty &&
//         action.actionLifeCycle == NotificationLifeCycle.Foreground) {
//       openChatFromPayload(action.payload);
//     }

//     if (action.buttonKeyPressed.isEmpty &&
//         action.actionLifeCycle == NotificationLifeCycle.AppKilled) {
//       openChatFromPayload(action.payload);
//     }
//   }

//   // ================= OPEN CHAT SCREEN =================
//   static void openChatFromPayload(Map<String, String?>? payload) {
//     if (payload == null) return;

//     final convoId = payload["convoId"];
//     final senderId = payload["senderId"];
//     final userName = payload["userName"];
//     final avatar = payload["avatar"];

//     if (convoId == null) return;

//     Future.delayed(const Duration(milliseconds: 500), () {
//       MyRouter.navigatorKey.currentState?.push(
//         MaterialPageRoute(
//           builder: (_) => PrivateChatScreen(
//             convoId: convoId,
//             profileAvatarUrl: avatar ?? "",
//             userName: userName ?? "User",
//             lastSeen: "online",
//             receiverId: senderId,
//             datumId: senderId,
//             firstname: userName,
//             lastname: "",
//             grpChat: false,
//             favourite: false,
//             initialMessages: null,
//             sharedFiles: const [],
//           ),
//         ),
//       );
//     });
//   }

//   // ================= SHOW NOTIFICATION =================
//   static Future<void> show(RemoteMessage msg) async {
//     final String messageId = msg.data['message_id']?.toString() ??
//         msg.messageId ??
//         msg.data.hashCode.toString();

//     if (_handledMessages.contains(messageId)) return;
//     _handledMessages.add(messageId);
//     if (_handledMessages.length > 200) _handledMessages.clear();

//     final sender = msg.data['senderName'] ?? "User";
//     final body = msg.data['message'] ?? "Message";
//     final avatar = msg.data['profilePic'];
//     final convoId = msg.data['conversationId'];
//     final senderId = msg.data['senderId'];
//     final receiverId = msg.data['receiverId'];

//     final int notificationId = messageId.hashCode & 0x7fffffff;

//     await AwesomeNotifications().createNotification(
//       content: NotificationContent(
//         id: notificationId,
//         channelKey: 'chat_channel',
//         title: sender,
//         body: body,
//         largeIcon: avatar,
//         category: NotificationCategory.Message,
//         displayOnForeground: true,
//         displayOnBackground: true,
//         payload: {
//           "convoId": convoId,
//           "senderId": senderId,
//           "receiverId": receiverId,
//           "userName": sender,
//           "avatar": avatar ?? "",
//         },
//       ),
//       actionButtons: [
//         NotificationActionButton(
//           key: 'REPLY',
//           label: 'Reply',
//           requireInputText: true,
//         ),
//         NotificationActionButton(key: 'MARK_READ', label: 'Mark Read'),
//         NotificationActionButton(key: 'MUTE_CHAT', label: 'Mute'),
//       ],
//     );

//     log("✅ Notification shown: $messageId");
//   }
// }

import 'dart:developer';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:nde_email/presantation/chat/chat_api_service/service/chat_api_service.dart';
import 'package:nde_email/utils/reusbale/common_import.dart';
import '../../presantation/chat/chat_private_screen/Private_Chat_Screen.dart';

class AwesomeNotificationService {
  static final Set<String> _handledMessages = {};

  // ================= INIT =================
  static Future<void> init() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'chat_channel',
          channelName: 'Chat Messages',
          channelDescription: 'Chat notifications',
          importance: NotificationImportance.Max,
          playSound: true,
        ),
      ],
    );

    bool allowed = await AwesomeNotifications().isNotificationAllowed();
    if (!allowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  // ================= ACTION HANDLER =================
  @pragma('vm:entry-point')
  static Future<void> onAction(ReceivedAction action) async {
    log("🔥 ACTION = ${action.buttonKeyPressed}");
    log("🔥 LIFE = ${action.actionLifeCycle}");
    log("🔥 PAYLOAD = ${action.payload}");

    // ===== REPLY BUTTON =====
    if (action.buttonKeyPressed == "REPLY") {
      final replyText = action.buttonKeyInput;
      final convoId = action.payload?["convoId"];
      final otherUserId = action.payload?["senderId"];
      final myUserId = action.payload?["receiverId"];

      if (replyText == null ||
          convoId == null ||
          myUserId == null ||
          otherUserId == null) {
        log("❌ Missing reply data");
        return;
      }

      await ChatApiService().init();

      await ChatApiService().sendMessage(
        conversationId: convoId,
        senderId: myUserId,
        receiverId: otherUserId,
        content: replyText,
      );

      log("✅ Reply Sent WITHOUT OPENING APP");
      return;
    }

    // ===== OPEN CHAT WHEN TAP NOTIFICATION =====
    // if (action.buttonKeyPressed.isEmpty) {
    //   openChatFromPayload(action.payload);
    // }
  }

  // ================= OPEN CHAT SCREEN =================
  static void openChatFromPayload(Map<String, String?>? payload) {
    if (payload == null) return;

    final convoId = payload["convoId"];
    final senderId = payload["senderId"];
    final userName = payload["userName"];
    final avatar = payload["avatar"];

    if (convoId == null) return;

    Future.delayed(const Duration(seconds: 1), () {
      MyRouter.navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => PrivateChatScreen(
            convoId: convoId,
            profileAvatarUrl: avatar ?? "",
            userName: userName ?? "User",
            lastSeen: "online",
            receiverId: senderId,
            datumId: senderId,
            firstname: userName,
            lastname: "",
            grpChat: false,
            favourite: false,
            initialMessages: null,
            sharedFiles: const [],
          ),
        ),
      );
    });
  }

  // ================= SHOW NOTIFICATION =================
  static Future<void> show(RemoteMessage msg) async {
    final String messageId = msg.data['message_id']?.toString() ??
        msg.messageId ??
        msg.data.hashCode.toString();

    if (_handledMessages.contains(messageId)) return;
    _handledMessages.add(messageId);
    if (_handledMessages.length > 200) _handledMessages.clear();

    final sender = msg.data['senderName'] ?? "User";
    final body = msg.data['message'] ?? "Message";
    final avatar = msg.data['profilePic'];
    final convoId = msg.data['conversationId'];
    final senderId = msg.data['senderId'];
    final receiverId = msg.data['receiverId'];

    final int notificationId = messageId.hashCode & 0x7fffffff;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: notificationId,
        channelKey: 'chat_channel',
        title: sender,
        body: body,
        largeIcon: avatar,
        category: NotificationCategory.Message,
        displayOnForeground: true,
        displayOnBackground: true,
        payload: {
          "convoId": convoId ?? "",
          "senderId": senderId ?? "",
          "receiverId": receiverId ?? "",
          "userName": sender,
          "avatar": avatar ?? "",
        },
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'REPLY',
          label: 'Reply',
          requireInputText: true,
        ),
        NotificationActionButton(key: 'MARK_READ', label: 'Mark Read'),
        NotificationActionButton(key: 'MUTE', label: 'Mute'),
      ],
    );

    log("✅ Notification shown: $messageId");
  }
}
