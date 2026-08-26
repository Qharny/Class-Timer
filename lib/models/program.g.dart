// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'program.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProgramAdapter extends TypeAdapter<Program> {
  @override
  final int typeId = 3;

  @override
  Program read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Program(
      institution: fields[0] as String,
      name: fields[1] as String,
      level: fields[2] as String,
      semester: fields[3] as int,
      department: fields[4] as String?,
      group: fields[5] as String?,
      campusLat: fields[6] as double?,
      campusLng: fields[7] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, Program obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.institution)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.level)
      ..writeByte(3)
      ..write(obj.semester)
      ..writeByte(4)
      ..write(obj.department)
      ..writeByte(5)
      ..write(obj.group)
      ..writeByte(6)
      ..write(obj.campusLat)
      ..writeByte(7)
      ..write(obj.campusLng);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgramAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
