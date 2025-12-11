import 'package:hive/hive.dart';

class GrpLocalChatStorage {
  static const String boxName = 'chatBox';

  /// Save messages list to local storage by convoId
  static Future<void> saveMessages(
    String convoId,
    List<Map<String, dynamic>> messages,
  ) async {
    final box = Hive.box(boxName);
    await box.put('chat_messages_$convoId', messages);
  }

  static List<Map<String, dynamic>> loadMessages(String convoId) {
    final box = Hive.box(boxName);
    final stored = box.get('chat_messages_$convoId', defaultValue: <Map>[]);

    if (stored is! List) return [];

    return stored.whereType<Map>().map((e) {
      return e.map((key, value) => MapEntry(key.toString(), value));
    }).toList();
  }


  /// Save draft message for a group conversation
  static Future<void> saveDraftMessage(String convoId, String message) async {
    final box = Hive.box(boxName);
    await box.put('grp_draft_message_$convoId', message);
  }

  /// Get draft message for a group conversation
  static String? getDraftMessage(String convoId) {
    final box = Hive.box(boxName);
    return box.get('grp_draft_message_$convoId');
  }

  /// Clear draft message for a group conversation
  static Future<void> clearDraftMessage(String convoId) async {
    final box = Hive.box(boxName);
    await box.delete('grp_draft_message_$convoId');
  }
}


