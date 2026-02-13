// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'class_event.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ClassEventAdapter extends TypeAdapter<ClassEvent> {
  @override
  final int typeId = 0;

  @override
  ClassEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ClassEvent(
      id: fields[0] as String,
      title: fields[1] as String,
      type: fields[2] as String,
      dayOfWeek: fields[3] as int,
      startTime: fields[4] as String,
      endTime: fields[5] as String,
      venue: fields[6] as String,
      calendarEventId: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ClassEvent obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.dayOfWeek)
      ..writeByte(4)
      ..write(obj.startTime)
      ..writeByte(5)
      ..write(obj.endTime)
      ..writeByte(6)
      ..write(obj.venue)
      ..writeByte(7)
      ..write(obj.calendarEventId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClassEventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
