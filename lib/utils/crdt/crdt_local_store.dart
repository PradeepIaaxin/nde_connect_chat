import 'package:hive/hive.dart';
import 'package:nde_email/convo_list_crdt.dart';
import 'package:nde_email/message_list_crdt.dart';


class CrdtLocalStore {
  static Future<ConvoListCrdt?> loadConvoList(String userId) async {
    final box = await Hive.openBox<ConvoListCrdt>('convo_crdt');
    return box.get(userId);
  }

  static Future<void> saveConvoList(
    String userId,
    ConvoListCrdt data,
  ) async {
    final box = await Hive.openBox<ConvoListCrdt>('convo_crdt');
    await box.put(userId, data);
  }

  static Future<MessageListCrdt?> loadMessageList(
    String convoId,
  ) async {
    final box = await Hive.openBox<MessageListCrdt>('message_crdt');
    return box.get(convoId);
  }

  static Future<void> saveMessageList(
    MessageListCrdt data,
  ) async {
    final box = await Hive.openBox<MessageListCrdt>('message_crdt');
    await box.put(data.conversationId, data);
  }
}
