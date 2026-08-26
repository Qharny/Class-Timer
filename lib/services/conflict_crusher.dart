import '../data/models/event_model.dart';

class ConflictCrusher {
  /// Detects conflicts in O(n log n) time by sorting events by startTime and
  /// day, then sweeping while tracking the latest end time seen so far.
  ///
  /// Comparing only adjacent pairs after sorting is not sufficient: with
  /// A(9-11), B(9:30-9:45), C(10:30-11:30) sorted as A,B,C, the adjacent
  /// pairs (A,B) and (B,C) don't reveal that A and C also overlap. Tracking
  /// the running max end time per day catches those non-adjacent overlaps.
  static List<Map<String, EventModel>> detectConflicts(
    List<EventModel> events,
  ) {
    if (events.isEmpty) return [];

    final sorted = List<EventModel>.from(events)
      ..sort((a, b) {
        final dayCmp = a.dayOfWeek.compareTo(b.dayOfWeek);
        if (dayCmp != 0) return dayCmp;
        return a.startTime.compareTo(b.startTime);
      });

    final List<Map<String, EventModel>> conflicts = [];
    final List<EventModel> active = [];

    for (final event in sorted) {
      // Drop events from other days or that have already ended before this
      // one starts.
      active.removeWhere(
        (e) =>
            e.dayOfWeek != event.dayOfWeek ||
            !e.endTime.isAfter(event.startTime),
      );

      for (final other in active) {
        conflicts.add({'event1': other, 'event2': event});
      }

      active.add(event);
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
