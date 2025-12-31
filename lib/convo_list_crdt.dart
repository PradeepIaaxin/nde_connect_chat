import 'dart:typed_data';
import 'package:hive/hive.dart';

part 'convo_list_crdt.g.dart';

@HiveType(typeId: 50)
class ConvoListCrdt extends HiveObject {
  @HiveField(0)
  Uint8List snapshot;

  @HiveField(1)
  List<int> frontiers;

  @HiveField(2)
  int savedAt;

  ConvoListCrdt({
    required this.snapshot,
    required this.frontiers,
    required this.savedAt,
  });
}
