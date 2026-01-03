import 'dart:typed_data';
import 'package:hive/hive.dart';

part 'message_list_crdt.g.dart';

@HiveType(typeId: 51)
class MessageListCrdt extends HiveObject {
  @HiveField(0)
  String conversationId;

  @HiveField(1)
  Uint8List snapshot;

  @HiveField(2)
  List<int> frontiers;

  @HiveField(3)
  int savedAt;

  MessageListCrdt({
    required this.conversationId,
    required this.snapshot,
    required this.frontiers,
    required this.savedAt,
  });
}
