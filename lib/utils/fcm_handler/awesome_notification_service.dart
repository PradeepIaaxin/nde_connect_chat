// import 'dart:developer';
// import 'package:awesome_notifications/awesome_notifications.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:nde_email/data/respiratory.dart';
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
//   }

//   // ================= ACTION HANDLER =================
//   @pragma('vm:entry-point')
//   static Future<void> onAction(ReceivedAction action) async {
//     log("🔥 ACTION = ${action.buttonKeyPressed ?? 'EMPTY'}");
//     log("🔥 LIFE = ${action.actionLifeCycle}");
//     log("🔥 PAYLOAD = ${action.payload}");

//     final payload = action.payload;
//     if (payload == null) return;

//     final buttonKey = action.buttonKeyPressed;

//     // CASE 1: Inline REPLY (this is the only change you needed!)
//     if (buttonKey == "REPLY") {
//       final replyText = action.buttonKeyInput.trim();
//       final convoId = payload["convoId"];
//       final otherUserId = payload["senderId"];
//       final myUserId = payload["receiverId"];

//       if (replyText == null ||
//           replyText.isEmpty ||
//           convoId == null ||
//           myUserId == null ||
//           otherUserId == null) {
//         log("❌ Missing reply data");
//         return;
//       }

//       try {
//         await ChatApiService().init();
//         await ChatApiService().sendMessage(
//           conversationId: convoId,
//           senderId: myUserId,
//           receiverId: otherUserId,
//           content: replyText,
//         );
//         log("✅ Background reply sent: '$replyText'");

//         // Optional: Remove notification after reply
//         if (action.id != null) {
//           await AwesomeNotifications().dismiss(action.id!);
//         }
//       } catch (e) {
//         log("❌ Background reply failed: $e");
//       }

//       // VERY IMPORTANT: Do NOT open chat and do NOT process any further
//       return;
//     }

//     // CASE 2: User tapped the notification body (normal tap)
//     if (buttonKey == null || buttonKey.isEmpty) {
//       final convoId = payload["convoId"];
//       if (convoId == null || convoId.isEmpty) {
//         log("❌ Cannot open chat — missing convoId");
//         return;
//       }

//       openChatFromPayload(payload);
//       return;
//     }

//     // CASE 3: Other buttons (Mark Read, Mute) - you can add logic later
//     log("Unhandled action button: $buttonKey");
//   }

//   // ================= OPEN CHAT SCREEN =================
//   static void openChatFromPayload(Map<String, String?>? payload) {
//     if (payload == null) return;

//     final convoId = payload["convoId"];
//     final senderId = payload["senderId"];
//     final userName = payload["userName"];
//     final avatar = payload["avatar"];

//     if (convoId == null) return;

//     Future.delayed(const Duration(milliseconds: 1200), () {
//       final navigatorState = MyRouter.navigatorKey.currentState;
//       if (navigatorState == null) {
//         log("⚠️ Navigator not ready");
//         return;
//       }

//       navigatorState.push(
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
//     final userId = await UserPreferences.getUserId();

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

//     if (senderId != null && senderId == userId) {
//       log("🚫 Skipping notification for self-sent message");
//       return;
//     }

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
//           "convoId": convoId ?? "",
//           "senderId": senderId ?? "",
//           "receiverId": receiverId ?? "",
//           "userName": sender,
//           "avatar": avatar ?? "",
//         },
//       ),
//       actionButtons: [
//         NotificationActionButton(
//           key: 'REPLY',
//           label: 'Reply',
//           requireInputText: true,
//           actionType: ActionType.SilentBackgroundAction,
//           autoDismissible: true,
//           enabled: true,
//         ),
//         NotificationActionButton(key: 'MARK_READ', label: 'Mark Read'),
//         NotificationActionButton(key: 'MUTE', label: 'Mute'),
//       ],
//     );

//     log("✅ Notification shown: $messageId");
//   }
// }

import 'dart:developer';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:nde_email/data/respiratory.dart';
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
          importance: NotificationImportance
              .High, // Changed to High (less aggressive sound)
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
    log("🔥 ACTION = ${action.buttonKeyPressed ?? 'EMPTY'}");
    log("🔥 LIFE = ${action.actionLifeCycle}");
    log("🔥 PAYLOAD = ${action.payload}");

    final payload = action.payload;
    if (payload == null) return;

    final buttonKey = action.buttonKeyPressed;

    if (buttonKey == "REPLY") {
      final replyText = action.buttonKeyInput?.trim() ?? '';
      final convoId = payload["convoId"];
      final otherUserId = payload["senderId"];
      final myUserId = payload["receiverId"];
      final groupid = payload["groupId"];
      final isGroup = payload["type"] == "GROUP_CHAT_MESSAGE";

      if (replyText.isEmpty ||
          convoId == null ||
          myUserId == null ||
          otherUserId == null) {
        log("❌ Missing reply data");
        return;
      }

      try {
        await ChatApiService().init();
        await ChatApiService().sendMessage(
            conversationId: convoId,
            senderId: myUserId,
            receiverId: otherUserId,
            content: replyText,
            grpId: isGroup ? groupid : null ,
            isGrpchat: isGroup);
        log("✅ Background reply sent: '$replyText'");
        log("✅ Background reply sent: '$convoId'");

        if (action.id != null) {
          await AwesomeNotifications().dismiss(action.id!);
        }
      } catch (e) {
        log("❌ Background reply failed: $e");
      }

      return;
    }

    // Body tap → open chat
    if (buttonKey == null || buttonKey.isEmpty) {
      final convoId = payload["convoId"];
      if (convoId == null || convoId.isEmpty) {
        log("❌ Cannot open chat — missing convoId");
        return;
      }
      openChatFromPayload(payload);
      return;
    }

    log("Unhandled action button: $buttonKey");
  }

  // ================= OPEN CHAT SCREEN =================
  static void openChatFromPayload(Map<String, String?>? payload) {
    if (payload == null) return;

    final convoId = payload["convoId"];
    final senderId = payload["senderId"];
    final userName = payload["userName"];
    final avatar = payload["avatar"];
    final type = payload["type"] ?? "";
    final groupName = payload["groupName"];
    final groupId = payload["groupId"];

    if (convoId == null) return;

    final isGroup =
        type == "GROUP_CHAT_MESSAGE" || groupId != null && groupId.isNotEmpty;

    Future.delayed(const Duration(milliseconds: 1200), () {
      final navigatorState = MyRouter.navigatorKey.currentState;
      if (navigatorState == null) {
        log("⚠️ Navigator not ready");
        return;
      }

      navigatorState.push(
        MaterialPageRoute(
          builder: (_) => PrivateChatScreen(
            convoId: convoId,
            profileAvatarUrl: avatar ?? "",
            userName: isGroup ? (groupName ?? "Group") : (userName ?? "User"),
            lastSeen: "online",
            receiverId: isGroup ? null : senderId,
            datumId: senderId,
            firstname: isGroup ? (groupName ?? "Group") : userName,
            lastname: "",
            grpChat: isGroup,
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

    final userId = await UserPreferences.getUserId();

    if (_handledMessages.contains(messageId)) return;
    _handledMessages.add(messageId);
    if (_handledMessages.length > 200) _handledMessages.clear();

    // Extract all possible fields
    final type = msg.data['type'] ?? '';
    final sender = msg.data['senderName'] ?? "User";
    final body = msg.data['message'] ?? "Message";
    final avatar = msg.data['profilePic'] ?? msg.data['groupAvatar'];
    final senderId = msg.data['senderId'];
    final receiverId = msg.data['receiverId'];
    final convoId =
        msg.data['conversationId'] ?? msg.data['roomId'] ?? msg.data['groupId'];
    final groupName = msg.data['groupName'];
    final groupId = msg.data['groupId'];

    // Skip self-sent messages
    if (senderId != null && senderId == userId) {
      log("🚫 Skipping notification for self-sent message");
      return;
    }

    // Decide title & body based on chat type
    String title;
    String displayBody = body;

    if (type == 'GROUP_CHAT_MESSAGE' &&
        groupName != null &&
        groupName.isNotEmpty) {
      title = groupName;

      // Body: sender name on line 1, message on line 2
      displayBody = "$sender\n$body";
    } else {
      // Private chat: keep simple
      title = sender;
      displayBody = body;
    }

    final int notificationId = messageId.hashCode & 0x7fffffff;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: notificationId,
        channelKey: 'chat_channel',
        title: title,
        body: displayBody,
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
          "groupName": groupName ?? "",
          "groupId": groupId ?? "",
          "type": type,
        },
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'REPLY',
          label: 'Reply',
          requireInputText: true,
          actionType: ActionType.SilentBackgroundAction,
          autoDismissible: false, // Helps avoid extra sound on dismiss
        ),
        NotificationActionButton(key: 'MARK_READ', label: 'Mark Read'),
        NotificationActionButton(key: 'MUTE', label: 'Mute'),
      ],
    );

    log("✅ Notification shown: $messageId | Type: $type | Title: $title");
  }
}
