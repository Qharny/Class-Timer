import 'package:hive/hive.dart';

part 'class_event.g.dart';

@HiveType(typeId: 0)
class ClassEvent extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late String type; // 'class' or 'study'

  @HiveField(3)
  late int dayOfWeek; // 1-7 (Monday-Sunday)

  @HiveField(4)
  late String startTime; // HH:mm

  @HiveField(5)
  late String endTime; // HH:mm

  @HiveField(6)
  late String venue;

  @HiveField(7)
  late String? calendarEventId;

  ClassEvent({
    required this.id,
    required this.title,
    required this.type,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.venue,
    this.calendarEventId,
  });
}
