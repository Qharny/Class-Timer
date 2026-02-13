import 'package:hive/hive.dart';

part 'course.g.dart';

@HiveType(typeId: 2)
class Course extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String code;

  @HiveField(3)
  late String lecturer;

  @HiveField(4)
  late String colorTag; // Hex color string

  @HiveField(5)
  late int creditHours;

  @HiveField(6)
  late int reminderMinutes; // Per-course reminder override

  Course({
    required this.id,
    required this.name,
    required this.code,
    required this.lecturer,
    required this.colorTag,
    required this.creditHours,
    this.reminderMinutes = 15,
  });
}
