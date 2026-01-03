// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'convo_list_crdt.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ConvoListCrdtAdapter extends TypeAdapter<ConvoListCrdt> {
  @override
  final int typeId = 50;

  @override
  ConvoListCrdt read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ConvoListCrdt(
      snapshot: fields[0] as Uint8List,
      frontiers: (fields[1] as List).cast<int>(),
      savedAt: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, ConvoListCrdt obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.snapshot)
      ..writeByte(1)
      ..write(obj.frontiers)
      ..writeByte(2)
      ..write(obj.savedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConvoListCrdtAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
