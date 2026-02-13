import 'package:hive/hive.dart';

part 'study_session.g.dart';

@HiveType(typeId: 1)
class StudySession extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late String linkedCourse;

  @HiveField(3)
  late DateTime startTime;

  @HiveField(4)
  late DateTime endTime;

  @HiveField(5)
  late bool focusModeEnabled;

  @HiveField(6)
  late bool completed;

  StudySession({
    required this.id,
    required this.title,
    required this.linkedCourse,
    required this.startTime,
    required this.endTime,
    this.focusModeEnabled = false,
    this.completed = false,
  });
}
