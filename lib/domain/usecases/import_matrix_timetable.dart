import 'dart:io';
import 'package:excel/excel.dart';
import 'package:hive/hive.dart';
import '../../data/datasources/excel_matrix_parser_datasource.dart';
import '../../data/models/event_model.dart';
import '../../data/models/student_profile_model.dart';
import '../../services/conflict_crusher.dart';

class ImportMatrixTimetable {
  final MatrixScheduleParserService parserService;

  ImportMatrixTimetable({required this.parserService});

  Future<void> call(File file, StudentProfileModel profile) async {
    final bytes = file.readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);

    List<EventModel> allEvents = [];

    for (var table in excel.tables.keys) {
      final sheet = excel.tables[table]!;

      // 1. Detect Time Headers
      final timeSlots = parserService.detectTimeHeaders(sheet);
      if (timeSlots.isEmpty) continue;

      // 2. Build Events and Filter by Profile
      final events = parserService.buildEventsFromGrid(
        sheet: sheet,
        timeSlots: timeSlots,
        profile: profile,
      );

      allEvents.addAll(events);
    }

    // 3. Merge Consecutive Blocks
    final mergedEvents = parserService.mergeConsecutiveBlocks(allEvents);

    // 4. Save to Hive
    final eventsBox = await Hive.openBox<EventModel>('events');
    await eventsBox.clear(); // Clear existing events for fresh import
    await eventsBox.addAll(mergedEvents);

    // 5. Run Conflict Crusher
    final conflicts = ConflictCrusher.detectConflicts(mergedEvents);
    if (conflicts.isNotEmpty) {
      // Handle conflicts (e.g., log or notify - implementation specific)
      print('Detected ${conflicts.length} conflicts during import.');
    }
  }
}
