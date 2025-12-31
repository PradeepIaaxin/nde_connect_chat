// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_list_crdt.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MessageListCrdtAdapter extends TypeAdapter<MessageListCrdt> {
  @override
  final int typeId = 51;

  @override
  MessageListCrdt read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MessageListCrdt(
      conversationId: fields[0] as String,
      snapshot: fields[1] as Uint8List,
      frontiers: (fields[2] as List).cast<int>(),
      savedAt: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, MessageListCrdt obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.conversationId)
      ..writeByte(1)
      ..write(obj.snapshot)
      ..writeByte(2)
      ..write(obj.frontiers)
      ..writeByte(3)
      ..write(obj.savedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageListCrdtAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
