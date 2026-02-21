import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../models/class_event.dart';
import '../models/domain_models.dart';
import 'matrix_parser_service.dart';
import 'local_storage_service.dart';

class ImportService {
  /// Picks a file and parses it as Excel.
  Future<List<ClassEvent>> pickAndParseExcel() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (result == null || result.files.single.path == null) {
      return [];
    }

    final file = File(result.files.single.path!);
    final parsedEvents = await parseExcel(file);

    // Map ParsedEvent to ClassEvent for Hive storage (temporary mapping)
    return parsedEvents.map((pe) {
      return _mapParsedToClassEvent(pe);
    }).toList();
  }

  /// Picks an image and parses it using OCR.
  Future<List<ClassEvent>> pickAndParseImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return [];

    final inputImage = InputImage.fromFilePath(image.path);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final RecognizedText recognizedText = await textRecognizer.processImage(
      inputImage,
    );

    final List<ParsedEvent> parsedEvents = _reconstructFromOCR(recognizedText);
    textRecognizer.close();

    return parsedEvents.map((pe) => _mapParsedToClassEvent(pe)).toList();
  }

  ClassEvent _mapParsedToClassEvent(ParsedEvent pe) {
    return ClassEvent(
      id:
          DateTime.now().millisecondsSinceEpoch.toString() +
          pe.title.hashCode.toString(),
      title: pe.title,
      type: 'class',
      dayOfWeek: _dayToNum(pe.day),
      startTime:
          '${pe.startTime.hour.toString().padLeft(2, '0')}:${pe.startTime.minute.toString().padLeft(2, '0')}',
      endTime:
          '${pe.endTime.hour.toString().padLeft(2, '0')}:${pe.endTime.minute.toString().padLeft(2, '0')}',
      venue: pe.venue ?? 'Unknown',
    );
  }

  List<ParsedEvent> _reconstructFromOCR(RecognizedText recognizedText) {
    final List<ParsedEvent> events = [];
    String currentDay = 'Monday';

    // Basic heuristic: Group text blocks by proximity or sequence
    // This is a simplified version of the "hardest" part mentioned in architecture
    for (TextBlock block in recognizedText.blocks) {
      final String text = block.text.trim();

      // Detect Day
      final dayMatch = RegExp(
        r'(monday|tuesday|wednesday|thursday|friday|saturday|sunday)',
        caseSensitive: false,
      ).firstMatch(text);
      if (dayMatch != null) {
        currentDay = dayMatch.group(0)!;
        continue;
      }

      // Detect Time Pattern (e.g., 9:00 - 11:00)
      final timeRangeMatch = RegExp(
        r'(\d{1,2}:\d{2})\s*[-–]\s*(\d{1,2}:\d{2})',
      ).firstMatch(text);

      if (timeRangeMatch != null) {
        final startStr = timeRangeMatch.group(1)!;
        final endStr = timeRangeMatch.group(2)!;

        // Try to find the title - often the text block immediately before or after the time
        // For now, if the block contains both, we might need to split it
        String title = text.replaceAll(timeRangeMatch.group(0)!, '').trim();

        if (title.isEmpty) {
          title = 'Class'; // Fallback
        }

        events.add(
          ParsedEvent(
            title: title,
            day: currentDay,
            startTime: _parseTime(startStr),
            endTime: _parseTime(endStr),
            venue: 'See Image',
          ),
        );
      }
    }

    return events;
  }

  /// Picks an Excel file and parses it using the Matrix Engine.
  Future<List<ClassEvent>> pickAndParseMatrixExcel() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (result == null || result.files.single.path == null) {
      return [];
    }

    final file = File(result.files.single.path!);
    final parsedEvents = await parseMatrixExcel(file);

    return parsedEvents.map((pe) => _mapParsedToClassEvent(pe)).toList();
  }

  static Future<List<ParsedEvent>> parseMatrixExcel(File file) async {
    final bytes = file.readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);
    final parser = MatrixScheduleParserService();
    final List<ParsedEvent> allEvents = [];

    final profile = LocalStorageService().getProgram();

    for (var table in excel.tables.keys) {
      final rows = excel.tables[table]?.rows;
      if (rows == null || rows.isEmpty) continue;

      // Extract raw rows
      final rawRows = rows.map((r) => r.map((c) => c?.value).toList()).toList();

      final headerIndex = parser.detectTimeHeader(rawRows);
      if (headerIndex == -1) continue;

      final events = parser.buildEventsFromGrid(
        day: table, // Sheet names are usually days
        rows: rawRows,
        headerIndex: headerIndex,
        programFilter: profile?.name,
        levelFilter: profile?.level,
      );

      allEvents.addAll(events);
    }

    return allEvents;
  }

  static int _dayToNum(String day) {
    switch (day.toLowerCase()) {
      case 'monday':
        return 1;
      case 'tuesday':
        return 2;
      case 'wednesday':
        return 3;
      case 'thursday':
        return 4;
      case 'friday':
        return 5;
      case 'saturday':
        return 6;
      case 'sunday':
        return 7;
      default:
        return 1;
    }
  }

  /// Parses an Excel/CSV file and returns a list of [ParsedEvent]s.
  static Future<List<ParsedEvent>> parseExcel(File file) async {
    final bytes = file.readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);
    final List<ParsedEvent> parsedEvents = [];

    for (var table in excel.tables.keys) {
      final rows = excel.tables[table]?.rows;
      if (rows == null || rows.isEmpty) continue;

      // Basic header detection (future: dynamic mapping)
      // Assuming: Day | Subject | Start | End | Venue
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.length < 4) continue;

        try {
          final day = row[0]?.value?.toString() ?? '';
          final title = row[1]?.value?.toString() ?? '';
          final startStr = row[2]?.value?.toString() ?? '';
          final endStr = row[3]?.value?.toString() ?? '';
          final venue = row.length > 4 ? row[4]?.value?.toString() : null;

          if (title.isEmpty || startStr.isEmpty) continue;

          parsedEvents.add(
            ParsedEvent(
              title: title,
              day: day,
              startTime: _parseTime(startStr),
              endTime: _parseTime(endStr),
              venue: venue,
            ),
          );
        } catch (e) {
          // Log parsing error and continue
          debugPrint('Error parsing row $i: $e');
        }
      }
    }

    return parsedEvents;
  }

  static TimeOfDay _parseTime(String timeStr) {
    // Expected formats: "HH:mm", "H:mm", "9:00 AM"
    final cleanTime = timeStr.trim().toLowerCase();

    // Basic HH:mm extraction
    final regExp = RegExp(r'(\d{1,2}):(\d{2})');
    final match = regExp.firstMatch(cleanTime);

    if (match != null) {
      int hour = int.parse(match.group(1)!);
      int minute = int.parse(match.group(2)!);

      if (cleanTime.contains('pm') && hour < 12) hour += 12;
      if (cleanTime.contains('am') && hour == 12) hour = 0;

      return TimeOfDay(hour: hour, minute: minute);
    }

    return const TimeOfDay(hour: 0, minute: 0);
  }
}
