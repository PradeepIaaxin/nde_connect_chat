import 'package:hive/hive.dart';

class LocalChatStorage {
  static const String boxName = 'chatBox';

  /// Save messages list to local storage by convoId
  static Future<void> saveMessages(
      String convoId, List<Map<String, dynamic>> messages) async {
    final box = Hive.box(boxName);

     await box.put('chat_messages_$convoId', messages);
  }

  /// Load messages list from local storage by convoId
  static List<Map<String, dynamic>> loadMessages(String convoId) {
    final box = Hive.box(boxName);
    final stored = box.get('chat_messages_$convoId', defaultValue: []);

    return (stored as List).map((e) {
      if (e is Map) {
        return Map<String, dynamic>.from(e.map(
          (key, value) => MapEntry(key.toString(), value),
        ));
      } else {
        return <String, dynamic>{};
      }
    }).toList();
  }

  /// Save draft message for a conversation
  static Future<void> saveDraftMessage(String convoId, String message) async {
    final box = Hive.box(boxName);
    await box.put('draft_message_$convoId', message);
  }

  /// Get draft message for a conversation
  static String? getDraftMessage(String convoId) {
    final box = Hive.box(boxName);
    return box.get('draft_message_$convoId');
  }

  /// Clear draft message for a conversation
  static Future<void> clearDraftMessage(String convoId) async {
    final box = Hive.box(boxName);
    await box.delete('draft_message_$convoId');
  }
}
