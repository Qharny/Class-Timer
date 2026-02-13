import 'package:flutter/material.dart';
import '../models/domain_models.dart';

class ReschedulingEngine {
  /// Finds free time slots between existing events for a given day.
  /// [availableStart] and [availableEnd] define the user's active hours (e.g., 6 AM - 10 PM).
  static List<DateTimeRange> findFreeSlots({
    required List<EventEntity> existingEvents,
    required DateTime day,
    required TimeOfDay startLimit,
    required TimeOfDay endLimit,
    required Duration minDuration,
  }) {
    final List<DateTimeRange> freeSlots = [];

    // 1. Filter and sort events for the day
    final dayEvents =
        existingEvents
            .where(
              (e) =>
                  e.startTime.year == day.year &&
                  e.startTime.month == day.month &&
                  e.startTime.day == day.day,
            )
            .toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

    // 2. Define search boundaries
    DateTime currentPointer = DateTime(
      day.year,
      day.month,
      day.day,
      startLimit.hour,
      startLimit.minute,
    );

    final DateTime limitEnd = DateTime(
      day.year,
      day.month,
      day.day,
      endLimit.hour,
      endLimit.minute,
    );

    // 3. Iterate through gaps
    for (var event in dayEvents) {
      if (event.startTime.isAfter(currentPointer)) {
        final gap = event.startTime.difference(currentPointer);
        if (gap >= minDuration) {
          freeSlots.add(
            DateTimeRange(start: currentPointer, end: event.startTime),
          );
        }
      }
      if (event.endTime.isAfter(currentPointer)) {
        currentPointer = event.endTime;
      }
    }

    // 4. Check final gap
    if (limitEnd.isAfter(currentPointer)) {
      final gap = limitEnd.difference(currentPointer);
      if (gap >= minDuration) {
        freeSlots.add(DateTimeRange(start: currentPointer, end: limitEnd));
      }
    }

    return freeSlots;
  }
}

class DateTimeRange {
  final DateTime start;
  final DateTime end;
  DateTimeRange({required this.start, required this.end});

  Duration get duration => end.difference(start);
}
