import 'dart:convert';

import 'package:nde_email/presantation/chat/chat_private_screen/messager_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheHelper {
  static const _messagesKey = 'cached_messages';

  // Save messages to cache
  static Future<void> saveMessages(List<Message> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = messages.map((message) => message.toJson()).toList();
    await prefs.setString(_messagesKey, jsonEncode(messagesJson));
  }

  // Load messages from cache
  static Future<List<Message>> loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = prefs.getString(_messagesKey);

    if (messagesJson == null) return [];

    List<dynamic> decodedMessages = jsonDecode(messagesJson);

    // Map the decoded messages to the Message model
    return decodedMessages.map((e) {
      if (e is Map<String, dynamic>) {
        return Message.fromJson(e);
      } else {
        // If Datum is returned, convert it to Message
        // Assuming Datum has a method toJson or similar
        return Message.fromJson(e as Map<String, dynamic>);
      }
    }).toList();
  }
}
