import '../data/models/event_model.dart';

class ConflictCrusher {
  /// Detects conflicts in O(n) time by sorting events by startTime.
  static List<Map<String, EventModel>> detectConflicts(
    List<EventModel> events,
  ) {
    if (events.isEmpty) return [];

    // Sort events by startTime
    events.sort((a, b) => a.startTime.compareTo(b.startTime));

    List<Map<String, EventModel>> conflicts = [];

    for (int i = 0; i < events.length - 1; i++) {
      if (events[i].endTime.isAfter(events[i + 1].startTime)) {
        conflicts.add({'event1': events[i], 'event2': events[i + 1]});
      }
    }

    return conflicts;
  }

  /// Builds a weekly index of events for faster lookups.
  static Map<int, List<EventModel>> buildWeeklyIndex(List<EventModel> events) {
    Map<int, List<EventModel>> index = {};

    for (var event in events) {
      index.putIfAbsent(event.dayOfWeek, () => []).add(event);
    }

    // Sort each day's events by startTime
    for (var day in index.keys) {
      index[day]!.sort((a, b) => a.startTime.compareTo(b.startTime));
    }

    return index;
  }
}
