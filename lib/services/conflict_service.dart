import '../models/class_event.dart';

class ConflictService {
  bool checkConflict(ClassEvent newEvent, List<ClassEvent> existingEvents) {
    for (var event in existingEvents) {
      if (event.dayOfWeek == newEvent.dayOfWeek) {
        if (_isOverlapping(newEvent, event)) {
          return true;
        }
      }
    }
    return false;
  }

  bool _isOverlapping(ClassEvent e1, ClassEvent e2) {
    final start1 = _parseTime(e1.startTime);
    final end1 = _parseTime(e1.endTime);
    final start2 = _parseTime(e2.startTime);
    final end2 = _parseTime(e2.endTime);

    return (start1.isBefore(end2) && end1.isAfter(start2));
  }

  DateTime _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return DateTime(2024, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
  }

  List<ClassEvent> findConflicts(
    ClassEvent newEvent,
    List<ClassEvent> existingEvents,
  ) {
    return existingEvents
        .where(
          (event) =>
              event.dayOfWeek == newEvent.dayOfWeek &&
              _isOverlapping(newEvent, event),
        )
        .toList();
  }
}
