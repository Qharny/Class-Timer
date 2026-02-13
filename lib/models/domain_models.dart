import 'package:flutter/material.dart';

enum EventType { classEvent, study }

class ParsedEvent {
  final String title;
  final String day;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String? venue;

  ParsedEvent({
    required this.title,
    required this.day,
    required this.startTime,
    required this.endTime,
    this.venue,
  });
}

class EventEntity {
  final String id;
  final String title;
  final EventType type;
  final DateTime startTime;
  final DateTime endTime;
  final String? venue;
  final int priority; // Classes (1) > Study (0)

  EventEntity({
    required this.id,
    required this.title,
    required this.type,
    required this.startTime,
    required this.endTime,
    this.venue,
    this.priority = 0,
  });

  /// Normalizes a [ParsedEvent] into an [EventEntity].
  /// Calculates the next occurrence of the event based on the day of the week.
  factory EventEntity.fromParsed(ParsedEvent parsed, {required String id}) {
    final now = DateTime.now();
    final dayMap = {
      'monday': 1,
      'tuesday': 2,
      'wednesday': 3,
      'thursday': 4,
      'friday': 5,
      'saturday': 6,
      'sunday': 7,
    };

    final targetWeekday = dayMap[parsed.day.toLowerCase()] ?? now.weekday;
    int daysToAdd = targetWeekday - now.weekday;
    if (daysToAdd < 0) daysToAdd += 7;

    final baseDate = now.add(Duration(days: daysToAdd));

    final start = DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      parsed.startTime.hour,
      parsed.startTime.minute,
    );

    final end = DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      parsed.endTime.hour,
      parsed.endTime.minute,
    );

    return EventEntity(
      id: id,
      title: parsed.title,
      type: EventType.classEvent,
      startTime: start,
      endTime: end,
      venue: parsed.venue,
      priority: 1, // Default priority for classes
    );
  }

  bool hasConflict(EventEntity other) {
    return startTime.isBefore(other.endTime) &&
        endTime.isAfter(other.startTime);
  }
}
