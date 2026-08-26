import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
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
    // Reading and decoding the .xlsx file is synchronous, CPU-heavy work
    // (unzip + XML parse in pure Dart). Running it on the main isolate
    // blocked the UI thread completely for the whole duration — no frames,
    // no spinner animation, the app looked hung. compute() runs it on a
    // background isolate instead, so the UI stays responsive while it works.
    final parsedEvents = await compute(parseExcel, file);

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

    final List<ParsedEvent> parsedEvents = reconstructFromOCR(recognizedText);
    textRecognizer.close();

    return parsedEvents.map((pe) => _mapParsedToClassEvent(pe)).toList();
  }

  static int _idCounter = 0;

  ClassEvent _mapParsedToClassEvent(ParsedEvent pe) {
    _idCounter++;
    final uniqueId =
        '${DateTime.now().microsecondsSinceEpoch}_${_idCounter}_${pe.title.hashCode.abs()}';
    return ClassEvent(
      id: uniqueId,
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

  static final RegExp _dayRegex = RegExp(
    r'(monday|tuesday|wednesday|thursday|friday|saturday|sunday)',
    caseSensitive: false,
  );
  static final RegExp _timeRangeRegex = RegExp(
    r'(\d{1,2}:\d{2})\s*[-–]\s*(\d{1,2}:\d{2})',
  );

  /// Reconstructs events from OCR text blocks.
  ///
  /// A timetable screenshot is a grid, and ML Kit returns one text block per
  /// roughly-contiguous region — a course name and its time range often land
  /// in two separate blocks rather than one combined block. This does two
  /// passes: first classify every block as a day header, a time range (with
  /// an optional inline title, for the case where both are one block), or a
  /// plain title candidate; then for every time range without an inline
  /// title, associate it with whichever nearby title-candidate block is
  /// spatially closest — this is the "Heuristic Association" step.
  List<ParsedEvent> reconstructFromOCR(RecognizedText recognizedText) {
    // Reading order (top-to-bottom, then left-to-right within a row) so day
    // headers get picked up before the events listed beneath them,
    // regardless of the order ML Kit happens to return blocks in.
    final blocks = List<TextBlock>.from(recognizedText.blocks)
      ..sort((a, b) {
        final rowCompare = a.boundingBox.top.compareTo(b.boundingBox.top);
        if ((a.boundingBox.top - b.boundingBox.top).abs() > 10) {
          return rowCompare;
        }
        return a.boundingBox.left.compareTo(b.boundingBox.left);
      });

    final timeBlocks = <_OcrTimeBlock>[];
    final titleCandidates = <TextBlock>[];
    String currentDay = 'Monday';

    for (final block in blocks) {
      final text = block.text.trim();
      if (text.isEmpty) continue;

      final dayMatch = _dayRegex.firstMatch(text);
      // Treat short blocks that are essentially just the day name as
      // section headers; a longer block that merely mentions a day inline
      // (e.g. "Monday Lecture 9:00 - 10:00") is handled as a normal block.
      if (dayMatch != null && text.length <= 12) {
        currentDay = dayMatch.group(0)!;
        continue;
      }

      final timeMatch = _timeRangeRegex.firstMatch(text);
      if (timeMatch != null) {
        final inlineTitle = text.replaceAll(timeMatch.group(0)!, '').trim();
        timeBlocks.add(
          _OcrTimeBlock(
            boundingBox: block.boundingBox,
            day: currentDay,
            startTime: _parseTime(timeMatch.group(1)!),
            endTime: _parseTime(timeMatch.group(2)!),
            inlineTitle: inlineTitle.isEmpty ? null : inlineTitle,
          ),
        );
      } else {
        titleCandidates.add(block);
      }
    }

    final usedCandidates = <TextBlock>{};
    final events = <ParsedEvent>[];

    for (final timeBlock in timeBlocks) {
      String? title = timeBlock.inlineTitle;

      if (title == null) {
        // Only associate blocks that are genuinely close together (the same
        // table cell/row) — a max distance scaled to the time block's own
        // height keeps this from grabbing an unrelated, merely-nearest-of-
        // what's-left block on a sparse page.
        final maxDistance = timeBlock.boundingBox.height * 3;
        TextBlock? nearest;
        double nearestDistance = double.infinity;

        for (final candidate in titleCandidates) {
          if (usedCandidates.contains(candidate)) continue;
          final distance =
              (candidate.boundingBox.center - timeBlock.boundingBox.center)
                  .distance;
          if (distance < nearestDistance) {
            nearestDistance = distance;
            nearest = candidate;
          }
        }

        if (nearest != null && nearestDistance <= maxDistance) {
          title = nearest.text.trim();
          usedCandidates.add(nearest);
        }
      }

      events.add(
        ParsedEvent(
          title: (title == null || title.isEmpty) ? 'Class' : title,
          day: timeBlock.day,
          startTime: timeBlock.startTime,
          endTime: timeBlock.endTime,
          venue: 'See Image',
        ),
      );
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
  ///
  /// Detects the header row and maps its columns (Day, Subject, Start Time,
  /// End Time, Venue) by name rather than assuming a fixed column order, so
  /// a file with columns in a different order — or extra columns — still
  /// imports correctly.
  static Future<List<ParsedEvent>> parseExcel(File file) async {
    final bytes = file.readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);
    final List<ParsedEvent> parsedEvents = [];

    for (var table in excel.tables.keys) {
      final rows = excel.tables[table]?.rows;
      if (rows == null || rows.isEmpty) continue;

      final mapping = _detectColumnMapping(rows);
      if (mapping == null) continue;

      for (int i = mapping.headerRowIndex + 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty) continue;

        try {
          String cellAt(int? index) {
            if (index == null || index >= row.length) return '';
            return row[index]?.value?.toString().trim() ?? '';
          }

          final day = cellAt(mapping.dayIndex);
          final title = cellAt(mapping.titleIndex);
          final startStr = cellAt(mapping.startIndex);
          final endStr = cellAt(mapping.endIndex);
          final venue = cellAt(mapping.venueIndex);

          if (title.isEmpty || startStr.isEmpty) continue;

          parsedEvents.add(
            ParsedEvent(
              title: title,
              day: day,
              startTime: _parseTime(startStr),
              endTime: _parseTime(endStr),
              venue: venue.isEmpty ? null : venue,
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

  static const _dayHeaderKeywords = ['day', 'weekday'];
  static const _titleHeaderKeywords = [
    'subject',
    'course',
    'class',
    'title',
    'unit',
    'name',
  ];
  static const _startHeaderKeywords = ['start', 'from', 'begin'];
  static const _endHeaderKeywords = ['end', 'to', 'finish'];
  static const _venueHeaderKeywords = ['venue', 'room', 'location', 'hall'];

  /// Scans the first few rows of a sheet for a header row containing
  /// recognizable column names, in any order, and maps each semantic field
  /// to its column index. Falls back to the previous fixed
  /// Day | Subject | Start | End | Venue layout if no header row is
  /// recognized, so files that already matched that assumption still work.
  static _ColumnMapping? _detectColumnMapping(List<List<Data?>> rows) {
    bool matchesAny(String cell, List<String> keywords) {
      final lower = cell.toLowerCase();
      return keywords.any((k) => lower.contains(k));
    }

    final searchLimit = rows.length < 5 ? rows.length : 5;
    for (int r = 0; r < searchLimit; r++) {
      final row = rows[r];
      int? dayIdx, titleIdx, startIdx, endIdx, venueIdx;

      for (int c = 0; c < row.length; c++) {
        final cell = row[c]?.value?.toString().trim() ?? '';
        if (cell.isEmpty) continue;

        if (dayIdx == null && matchesAny(cell, _dayHeaderKeywords)) {
          dayIdx = c;
        } else if (titleIdx == null && matchesAny(cell, _titleHeaderKeywords)) {
          titleIdx = c;
        } else if (startIdx == null && matchesAny(cell, _startHeaderKeywords)) {
          startIdx = c;
        } else if (endIdx == null && matchesAny(cell, _endHeaderKeywords)) {
          endIdx = c;
        } else if (venueIdx == null && matchesAny(cell, _venueHeaderKeywords)) {
          venueIdx = c;
        }
      }

      // Require at least Subject + Start Time to trust this as a real
      // header row rather than a coincidental keyword match in data.
      if (titleIdx != null && startIdx != null) {
        return _ColumnMapping(
          headerRowIndex: r,
          dayIndex: dayIdx,
          titleIndex: titleIdx,
          startIndex: startIdx,
          endIndex: endIdx,
          venueIndex: venueIdx,
        );
      }
    }

    // Fallback: assume the previous fixed layout, header in row 0.
    if (rows.isNotEmpty && rows[0].length >= 4) {
      return _ColumnMapping(
        headerRowIndex: 0,
        dayIndex: 0,
        titleIndex: 1,
        startIndex: 2,
        endIndex: 3,
        venueIndex: rows[0].length > 4 ? 4 : null,
      );
    }

    return null;
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

/// Maps semantic timetable fields to the column index they were found at
/// in a detected header row.
class _ColumnMapping {
  final int headerRowIndex;
  final int? dayIndex;
  final int titleIndex;
  final int startIndex;
  final int? endIndex;
  final int? venueIndex;

  _ColumnMapping({
    required this.headerRowIndex,
    required this.dayIndex,
    required this.titleIndex,
    required this.startIndex,
    required this.endIndex,
    required this.venueIndex,
  });
}

/// A recognized time-range block from an OCR pass, and the title it was
/// either read from inline or (later) associated with by proximity.
class _OcrTimeBlock {
  final Rect boundingBox;
  final String day;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String? inlineTitle;

  _OcrTimeBlock({
    required this.boundingBox,
    required this.day,
    required this.startTime,
    required this.endTime,
    this.inlineTitle,
  });
}
