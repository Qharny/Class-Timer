import '../models/domain_models.dart';

class ConflictEngine {
  /// Checks if a new event conflicts with any existing events.
  /// Returns a list of conflicting events.
  static List<EventEntity> detectConflicts(
    EventEntity newEvent,
    List<EventEntity> existingEvents,
  ) {
    return existingEvents
        .where((existing) => newEvent.hasConflict(existing))
        .toList();
  }

  /// Determines if a conflict is 'Hard' or 'Soft'.
  /// Hard: Class overlapping Class.
  /// Soft: Study overlapping Class (can be rescheduled).
  static ConflictSeverity getSeverity(EventEntity e1, EventEntity e2) {
    if (e1.type == EventType.classEvent && e2.type == EventType.classEvent) {
      return ConflictSeverity.hard;
    }
    return ConflictSeverity.soft;
  }
}

enum ConflictSeverity { hard, soft }
