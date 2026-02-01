// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_meta_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EventMetaAdapter extends TypeAdapter<EventMeta> {
  @override
  final int typeId = 1;

  @override
  EventMeta read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EventMeta(
      id: fields[0] as String,
      title: fields[1] as String,
      participantIds: (fields[2] as List).cast<String>(),
      createdAt: fields[3] as DateTime,
      updatedAt: fields[4] as DateTime,
      deletedAt: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, EventMeta obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.participantIds)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.updatedAt)
      ..writeByte(5)
      ..write(obj.deletedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventMetaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
