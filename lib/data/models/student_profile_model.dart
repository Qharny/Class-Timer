import 'package:hive/hive.dart';

part 'student_profile_model.g.dart';

@HiveType(typeId: 1)
class StudentProfileModel extends HiveObject {
  @HiveField(0)
  final String programCode; // MR, GL, etc.

  @HiveField(1)
  final String level; // 1A, 1B

  @HiveField(2)
  final String department;

  @HiveField(3)
  final String faculty;

  StudentProfileModel({
    required this.programCode,
    required this.level,
    required this.department,
    required this.faculty,
  });
}
