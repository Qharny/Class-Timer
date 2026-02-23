import 'package:hive/hive.dart';

part 'attendance_record.g.dart';

@HiveType(typeId: 8)
class AttendanceRecord extends HiveObject {
  @HiveField(0)
  final String eventId;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  bool attended;

  AttendanceRecord({
    required this.eventId,
    required this.date,
    this.attended = false,
  });
}
