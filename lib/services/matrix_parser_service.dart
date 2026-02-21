import 'package:flutter/material.dart';
import '../models/domain_models.dart';

class MatrixScheduleParserService {
  /// Detects the row index that contains time ranges (e.g., 7:00-8:00).
  int detectTimeHeader(List<List<dynamic>> rows) {
    for (int i = 0; i < rows.length; i++) {
      int matches = 0;
      for (var cell in rows[i]) {
        if (cell != null && _isTimeSlot(cell.toString())) {
          matches++;
        }
      }
      if (matches >= 5) return i;
    }
    return -1;
  }

  bool _isTimeSlot(String text) {
    return RegExp(r'\d{1,2}:\d{2}\s*[-–]\s*\d{1,2}:\d{2}').hasMatch(text);
  }

  /// Extracts time slots from the header row.
  List<String> extractTimeSlots(List<dynamic> headerRow) {
    return headerRow.map((cell) => cell?.toString() ?? '').toList();
  }

  /// Main logic to build events from the grid.
  List<ParsedEvent> buildEventsFromGrid({
    required String day,
    required List<List<dynamic>> rows,
    required int headerIndex,
    String? programFilter,
    String? levelFilter,
  }) {
    final List<ParsedEvent> events = [];
    final headerRow = rows[headerIndex];
    final timeSlots = extractTimeSlots(headerRow);

    // Rows below header usually contain classrooms in column 0
    for (int i = headerIndex + 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;

      final venue = row[0]?.toString() ?? 'Unknown Venue';

      // Skip rows that don't look like venue rows (heuristic: column 0 shouldn't be empty)
      if (venue.trim().isEmpty) continue;

      for (int j = 1; j < row.length; j++) {
        final cellContent = row[j]?.toString();
        if (cellContent == null ||
            cellContent.trim().isEmpty ||
            cellContent.toUpperCase() == 'BREAK') {
          continue;
        }

        // Apply filtering if provided
        if (programFilter != null && !cellContent.contains(programFilter))
          continue;
        if (levelFilter != null && !cellContent.contains(levelFilter)) continue;

        final timeRange = timeSlots[j];
        final times = _parseTimeRange(timeRange);
        if (times == null) continue;

        final parsedContent = parseCellContent(cellContent);

        events.add(
          ParsedEvent(
            title: parsedContent['course'] ?? cellContent,
            day: day,
            startTime: times['start']!,
            endTime: times['end']!,
            venue: venue,
          ),
        );
      }
    }

    return mergeConsecutiveBlocks(events);
  }

  Map<String, String> parseCellContent(String content) {
    final lines = content.split('\n').map((l) => l.trim()).toList();
    if (lines.isEmpty) return {};

    final result = <String, String>{};

    // Heuristic:
    // First line = Course Code / Title
    // Last line = Lecturer
    result['course'] = lines.first;
    if (lines.length > 1) {
      result['lecturer'] = lines.last;
    }

    // Detect Practical
    if (content.contains('(P)')) {
      result['type'] = 'Practical';
    }

    return result;
  }

  Map<String, TimeOfDay>? _parseTimeRange(String range) {
    final match = RegExp(
      r'(\d{1,2}:\d{2})\s*[-–]\s*(\d{1,2}:\d{2})',
    ).firstMatch(range);
    if (match == null) return null;

    return {
      'start': _parseTime(match.group(1)!),
      'end': _parseTime(match.group(2)!),
    };
  }

  TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1]);

    // Heuristic for AM/PM if not explicitly stated
    // If hour < 7, it's likely PM (e.g., 6:00 is 18:00)
    if (hour < 7) hour += 12;

    return TimeOfDay(hour: hour, minute: minute);
  }

  List<ParsedEvent> mergeConsecutiveBlocks(List<ParsedEvent> events) {
    if (events.isEmpty) return [];

    // Sort by venue, then day, then start time
    events.sort((a, b) {
      int cmp = a.venue?.compareTo(b.venue ?? '') ?? 0;
      if (cmp != 0) return cmp;
      cmp = a.day.compareTo(b.day);
      if (cmp != 0) return cmp;
      return a.startTime.hour.compareTo(b.startTime.hour);
    });

    final List<ParsedEvent> merged = [];
    ParsedEvent? current;

    for (var event in events) {
      if (current == null) {
        current = event;
        continue;
      }

      if (current.title == event.title &&
          current.venue == event.venue &&
          current.day == event.day &&
          current.endTime.hour == event.startTime.hour &&
          current.endTime.minute == event.startTime.minute) {
        // Merge!
        current = ParsedEvent(
          title: current.title,
          day: current.day,
          startTime: current.startTime,
          endTime: event.endTime,
          venue: current.venue,
        );
      } else {
        merged.add(current);
        current = event;
      }
    }

    if (current != null) merged.add(current);
    return merged;
  }
}
