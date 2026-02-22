import 'package:hive/hive.dart';

part 'event_model.g.dart';

@HiveType(typeId: 2)
class EventModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title; // MR 1B 153

  @HiveField(2)
  final String lecturer;

  @HiveField(3)
  final String venue;

  @HiveField(4)
  final int dayOfWeek; // 1-7 (Monday-Sunday)

  @HiveField(5)
  final DateTime startTime;

  @HiveField(6)
  final DateTime endTime;

  @HiveField(7)
  final String type; // Class / Practical / Study

  @HiveField(8)
  final bool completed;

  EventModel({
    required this.id,
    required this.title,
    required this.lecturer,
    required this.venue,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.type,
    this.completed = false,
  });

  EventModel copyWith({
    String? id,
    String? title,
    String? lecturer,
    String? venue,
    int? dayOfWeek,
    DateTime? startTime,
    DateTime? endTime,
    String? type,
    bool? completed,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      lecturer: lecturer ?? this.lecturer,
      venue: venue ?? this.venue,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      type: type ?? this.type,
      completed: completed ?? this.completed,
    );
  }
}
