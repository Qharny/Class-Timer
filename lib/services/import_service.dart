import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import '../models/class_event.dart';

class ImportService {
  Future<List<ClassEvent>?> pickAndParseExcel() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      var bytes = file.readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);

      List<ClassEvent> events = [];

      for (var table in excel.tables.keys) {
        var sheet = excel.tables[table]!;
        // Skip header row
        for (var i = 1; i < sheet.maxRows; i++) {
          var row = sheet.rows[i];
          if (row.length >= 5) {
            final title = row[0]?.value?.toString() ?? 'Unknown';
            final dayStr = row[1]?.value?.toString() ?? 'Monday';
            final start = row[2]?.value?.toString() ?? '08:00';
            final end = row[3]?.value?.toString() ?? '09:00';
            final venue = row[4]?.value?.toString() ?? 'N/A';

            events.add(
              ClassEvent(
                id:
                    DateTime.now().millisecondsSinceEpoch.toString() +
                    i.toString(),
                title: title,
                type: 'class',
                dayOfWeek: _parseDay(dayStr),
                startTime: start,
                endTime: end,
                venue: venue,
              ),
            );
          }
        }
      }
      return events;
    }
    return null;
  }

  int _parseDay(String day) {
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
}
