import 'dart:io';

import 'package:class_timer/services/import_service.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Writes a small in-memory workbook to a temp file and returns it, so
/// parseExcel() can be exercised end-to-end without a real uploaded file.
File _writeWorkbook(List<List<String>> rows) {
  final excel = Excel.createExcel();
  final sheetName = excel.getDefaultSheet()!;
  for (int r = 0; r < rows.length; r++) {
    for (int c = 0; c < rows[r].length; c++) {
      excel.updateCell(
        sheetName,
        CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r),
        TextCellValue(rows[r][c]),
      );
    }
  }
  final bytes = excel.encode()!;
  final file = File(
    '${Directory.systemTemp.path}/import_service_test_${DateTime.now().microsecondsSinceEpoch}.xlsx',
  );
  file.writeAsBytesSync(bytes);
  return file;
}

TextBlock _block(String text, Rect box) {
  return TextBlock(
    text: text,
    lines: const [],
    boundingBox: box,
    recognizedLanguages: const [],
    cornerPoints: const [],
  );
}

void main() {
  group('ImportService.parseExcel — dynamic header detection', () {
    late List<File> tempFiles;

    setUp(() => tempFiles = []);
    tearDown(() {
      for (final f in tempFiles) {
        if (f.existsSync()) f.deleteSync();
      }
    });

    test('maps columns by header name even in a non-standard order', () async {
      final file = _writeWorkbook([
        ['Subject', 'Day', 'Start Time', 'End Time', 'Venue'],
        ['Algorithms', 'Tuesday', '10:00', '12:00', 'Room 5'],
      ]);
      tempFiles.add(file);

      final events = await ImportService.parseExcel(file);

      expect(events, hasLength(1));
      expect(events.single.title, 'Algorithms');
      expect(events.single.day, 'Tuesday');
      expect(events.single.startTime, const TimeOfDay(hour: 10, minute: 0));
      expect(events.single.endTime, const TimeOfDay(hour: 12, minute: 0));
      expect(events.single.venue, 'Room 5');
    });

    test(
      'falls back to the fixed Day|Subject|Start|End|Venue layout when no '
      'header row is recognized',
      () async {
        final file = _writeWorkbook([
          ['Col1', 'Col2', 'Col3', 'Col4', 'Col5'],
          ['Wednesday', 'Chemistry', '13:00', '14:30', 'Lab 2'],
        ]);
        tempFiles.add(file);

        final events = await ImportService.parseExcel(file);

        expect(events, hasLength(1));
        expect(events.single.title, 'Chemistry');
        expect(events.single.day, 'Wednesday');
        expect(events.single.startTime, const TimeOfDay(hour: 13, minute: 0));
        expect(events.single.endTime, const TimeOfDay(hour: 14, minute: 30));
        expect(events.single.venue, 'Lab 2');
      },
    );
  });

  group('ImportService.reconstructFromOCR — heuristic association', () {
    final importService = ImportService();

    test(
      'associates a title block with a nearby separate time-range block',
      () {
        final recognizedText = RecognizedText(
          text: 'Monday\nData Structures\n9:00 - 11:00',
          blocks: [
            _block('Monday', const Rect.fromLTWH(0, 0, 80, 20)),
            _block('Data Structures', const Rect.fromLTWH(0, 30, 150, 20)),
            _block('9:00 - 11:00', const Rect.fromLTWH(0, 55, 150, 20)),
          ],
        );

        final events = importService.reconstructFromOCR(recognizedText);

        expect(events, hasLength(1));
        expect(events.single.title, 'Data Structures');
        expect(events.single.day, 'Monday');
        expect(events.single.startTime, const TimeOfDay(hour: 9, minute: 0));
        expect(events.single.endTime, const TimeOfDay(hour: 11, minute: 0));
      },
    );

    test('still handles a title and time combined in one block', () {
      final recognizedText = RecognizedText(
        text: 'Physics Lab 14:00 - 16:00',
        blocks: [
          _block(
            'Physics Lab 14:00 - 16:00',
            const Rect.fromLTWH(0, 0, 200, 20),
          ),
        ],
      );

      final events = importService.reconstructFromOCR(recognizedText);

      expect(events, hasLength(1));
      expect(events.single.title, 'Physics Lab');
      expect(events.single.startTime, const TimeOfDay(hour: 14, minute: 0));
      expect(events.single.endTime, const TimeOfDay(hour: 16, minute: 0));
    });

    test('does not associate a time block with a far-away title block', () {
      final recognizedText = RecognizedText(
        text: 'Unrelated note\n9:00 - 11:00',
        blocks: [
          _block('Unrelated note', const Rect.fromLTWH(0, 0, 100, 20)),
          _block('9:00 - 11:00', const Rect.fromLTWH(0, 500, 150, 20)),
        ],
      );

      final events = importService.reconstructFromOCR(recognizedText);

      expect(events, hasLength(1));
      expect(events.single.title, 'Class'); // fallback, nothing close enough
    });
  });
}
