import 'package:flutter_test/flutter_test.dart';
import 'package:class_timer/services/matrix_parser_service.dart';
import 'package:class_timer/models/domain_models.dart';
import 'package:flutter/material.dart';

void main() {
  late MatrixScheduleParserService parser;

  setUp(() {
    parser = MatrixScheduleParserService();
  });

  group('MatrixScheduleParserService Tests', () {
    test('detectTimeHeader should find the correct row', () {
      final rows = [
        ['University Timetable'],
        ['Semester 1'],
        ['', ''],
        [
          '',
          '7:00-8:00',
          '8:00-9:00',
          '9:00-10:00',
          '10:00-11:00',
          '11:00-12:00',
        ],
        ['LH 1', 'CS 101', 'CS 101', 'BREAK', 'MATH 102', 'MATH 102'],
      ];

      expect(parser.detectTimeHeader(rows), 3);
    });

    test('parseCellContent should extract course and lecturer', () {
      const content = 'GL 1A 159 (P)\nANOHAH';
      final result = parser.parseCellContent(content);

      expect(result['course'], 'GL 1A 159 (P)');
      expect(result['lecturer'], 'ANOHAH');
      expect(result['type'], 'Practical');
    });

    test('mergeConsecutiveBlocks should merge identical sessions', () {
      final events = [
        ParsedEvent(
          title: 'CS 101',
          day: 'Monday',
          startTime: const TimeOfDay(hour: 7, minute: 0),
          endTime: const TimeOfDay(hour: 8, minute: 0),
          venue: 'LH 1',
        ),
        ParsedEvent(
          title: 'CS 101',
          day: 'Monday',
          startTime: const TimeOfDay(hour: 8, minute: 0),
          endTime: const TimeOfDay(hour: 9, minute: 0),
          venue: 'LH 1',
        ),
      ];

      final merged = parser.mergeConsecutiveBlocks(events);
      expect(merged.length, 1);
      expect(merged.first.startTime.hour, 7);
      expect(merged.first.endTime.hour, 9);
    });
  });
}
