import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:class_timer/models/domain_models.dart';
import 'package:class_timer/services/conflict_engine.dart';
import 'package:class_timer/services/rescheduling_engine.dart';

void main() {
  group('ConflictEngine Tests', () {
    final now = DateTime.now();
    final event1 = EventEntity(
      id: '1',
      title: 'Class A',
      type: EventType.classEvent,
      startTime: DateTime(now.year, now.month, now.day, 9, 0),
      endTime: DateTime(now.year, now.month, now.day, 10, 30),
    );

    test('Detects overlapping events', () {
      final overlapping = EventEntity(
        id: '2',
        title: 'Class B',
        type: EventType.classEvent,
        startTime: DateTime(now.year, now.month, now.day, 10, 0),
        endTime: DateTime(now.year, now.month, now.day, 11, 0),
      );

      final conflicts = ConflictEngine.detectConflicts(overlapping, [event1]);
      expect(conflicts.length, 1);
      expect(conflicts.first.id, '1');
    });

    test('Identifies hard vs soft conflicts', () {
      final studyEvent = EventEntity(
        id: '2',
        title: 'Study session',
        type: EventType.study,
        startTime: DateTime(now.year, now.month, now.day, 10, 0),
        endTime: DateTime(now.year, now.month, now.day, 11, 0),
      );

      final severity = ConflictEngine.getSeverity(event1, studyEvent);
      expect(severity, ConflictSeverity.soft);
    });
  });

  group('ReschedulingEngine Tests', () {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);

    final events = [
      EventEntity(
        id: '1',
        title: 'Morning Class',
        type: EventType.classEvent,
        startTime: DateTime(now.year, now.month, now.day, 9, 0),
        endTime: DateTime(now.year, now.month, now.day, 11, 0),
      ),
      EventEntity(
        id: '2',
        title: 'Afternoon Class',
        type: EventType.classEvent,
        startTime: DateTime(now.year, now.month, now.day, 14, 0),
        endTime: DateTime(now.year, now.month, now.day, 16, 0),
      ),
    ];

    test('Finds free slots', () {
      final slots = ReschedulingEngine.findFreeSlots(
        existingEvents: events,
        day: day,
        startLimit: const TimeOfDay(hour: 8, minute: 0),
        endLimit: const TimeOfDay(hour: 18, minute: 0),
        minDuration: const Duration(hours: 1),
      );

      // Expected slots:
      // 1. 08:00 - 09:00 (1h)
      // 2. 11:00 - 14:00 (3h)
      // 3. 16:00 - 18:00 (2h)
      expect(slots.length, 3);
      expect(slots[0].start.hour, 8);
      expect(slots[1].start.hour, 11);
      expect(slots[2].start.hour, 16);
    });
  });
}
