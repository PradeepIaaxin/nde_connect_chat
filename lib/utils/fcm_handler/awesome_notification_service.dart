// import 'dart:developer';
// import 'package:awesome_notifications/awesome_notifications.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';

// class AwesomeNotificationService {
//   static final Set<String> _handledMessages = {};

//   static Future<void> init() async {
//     await AwesomeNotifications().initialize(
//       null,
//       [
//         NotificationChannel(
//           channelKey: 'chat_channel',
//           channelName: 'Chat Messages',
//           channelDescription: 'Chat notifications',
//           importance: NotificationImportance.Max,
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

//   static Future<void> _onAction(ReceivedAction action) async {
//     log("🔥 ACTION: ${action.buttonKeyPressed}");
//     log("🔥 INPUT: ${action.buttonKeyInput}");
//     log("🔥 PAYLOAD: ${action.payload}");
//   }

//   // ================= SHOW NOTIFICATION =================
//   static Future<void> show(RemoteMessage msg) async {
//     final String messageId = msg.data['message_id']?.toString() ??
//         msg.messageId ??
//         msg.data.hashCode.toString();

//     // ✅ DUPLICATE PREVENTION
//     if (_handledMessages.contains(messageId)) {
//       log("❌ DUPLICATE NOTIFICATION: $messageId");
//       return;
//     }
//     _handledMessages.add(messageId);

//     if (_handledMessages.length > 200) _handledMessages.clear();

//     final sender = msg.data['senderName'] ?? "User";
//     final body = msg.data['message'] ?? "Message";
//     final avatar = msg.data['profilePic'];
//     final chatId = msg.data['chatId'] ?? "global";

//     // IMPORTANT: convert messageId to int for notification id
//     final int notificationId = messageId.hashCode;

//     await AwesomeNotifications().createNotification(
//       content: NotificationContent(
//         id: notificationId,
//         channelKey: 'chat_channel',
//         title: sender,
//         body: body,
//         largeIcon: avatar,
//         notificationLayout: NotificationLayout.Inbox,
//         groupKey: chatId,
//         category: NotificationCategory.Message,
//         payload: {"chatId": chatId, "messageId": messageId},
//       ),
//       actionButtons: [
//         NotificationActionButton(
//           key: 'REPLY',
//           label: 'Reply',
//           requireInputText: true,
//         ),
//         NotificationActionButton(
//           key: 'MARK_READ',
//           label: 'Mark Read',
//         ),
//         NotificationActionButton(
//           key: 'MUTE_CHAT',
//           label: 'Mute',
//         ),
//       ],
//     );

//     log("✅ Notification shown messageId=$messageId");
//   }
// }




import 'dart:developer';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
        ),
      ],
    );

    bool allowed = await AwesomeNotifications().isNotificationAllowed();
    if (!allowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }

    AwesomeNotifications().setListeners(
      onActionReceivedMethod: _onAction,
    );
  }

  // ================= CLICK HANDLER =================
  static Future<void> _onAction(ReceivedAction action) async {
    log("🔥 NOTIFICATION CLICKED PAYLOAD = ${action.payload}");
    openChatFromPayload(action.payload);
  }

  // ================= OPEN CHAT =================
  static void openChatFromPayload(Map<String, String?>? payload) {
    if (payload == null) return;

    final convoId = payload["convoId"];
    final senderId = payload["senderId"];
    final userName = payload["userName"];
    final avatar = payload["avatar"];

    if (convoId == null) return;

    Future.delayed(const Duration(milliseconds: 500), () {
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
    final String messageId =
        msg.data['message_id']?.toString() ??
        msg.messageId ??
        msg.data.hashCode.toString();

    // DUPLICATE FILTER
    if (_handledMessages.contains(messageId)) return;
    _handledMessages.add(messageId);
    if (_handledMessages.length > 200) _handledMessages.clear();

    final sender = msg.data['senderName'] ?? "User";
    final body = msg.data['message'] ?? "Message";
    final avatar = msg.data['profilePic'];
    final convoId = msg.data['conversationId'];
    final senderId = msg.data['senderId'];

    final int notificationId = messageId.hashCode & 0x7fffffff; // FIX 32bit crash

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: notificationId,
        channelKey: 'chat_channel',
        title: sender,
        body: body,
        largeIcon: avatar,
        notificationLayout: NotificationLayout.Inbox,
        category: NotificationCategory.Message,
        payload: {
          "convoId": convoId,
          "senderId": senderId,
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
        NotificationActionButton(key: 'MUTE_CHAT', label: 'Mute'),
      ],
    );

    log("✅ Notification shown: $messageId");
  }
}
