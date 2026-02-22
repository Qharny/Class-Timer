// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_profile_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StudentProfileModelAdapter extends TypeAdapter<StudentProfileModel> {
  @override
  final int typeId = 1;

  @override
  StudentProfileModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StudentProfileModel(
      programCode: fields[0] as String,
      level: fields[1] as String,
      department: fields[2] as String,
      faculty: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, StudentProfileModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.programCode)
      ..writeByte(1)
      ..write(obj.level)
      ..writeByte(2)
      ..write(obj.department)
      ..writeByte(3)
      ..write(obj.faculty);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentProfileModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
