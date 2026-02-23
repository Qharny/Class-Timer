// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_productivity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserProductivityAdapter extends TypeAdapter<UserProductivity> {
  @override
  final int typeId = 4;

  @override
  UserProductivity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProductivity(
      currentStreak: (fields[0] as int?) ?? 0,
      longestStreak: (fields[1] as int?) ?? 0,
      lastCompletedDate: fields[2] as DateTime?,
      totalCompletedSessions: (fields[3] as int?) ?? 0,
      streakFreezes: (fields[4] as int?) ?? 0,
      coins: (fields[5] as int?) ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, UserProductivity obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.currentStreak)
      ..writeByte(1)
      ..write(obj.longestStreak)
      ..writeByte(2)
      ..write(obj.lastCompletedDate)
      ..writeByte(3)
      ..write(obj.totalCompletedSessions)
      ..writeByte(4)
      ..write(obj.streakFreezes)
      ..writeByte(5)
      ..write(obj.coins);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProductivityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
