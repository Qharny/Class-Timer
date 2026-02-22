import 'package:excel/excel.dart';
import '../models/event_model.dart';
import '../models/student_profile_model.dart';
import '../models/parsing_helpers.dart';
import 'package:intl/intl.dart';

class MatrixScheduleParserService {
  List<TimeSlotModel> detectTimeHeaders(Sheet sheet) {
    List<TimeSlotModel> timeSlots = [];
    // Typically headers are in the first or second row
    var row = sheet.rows[0];
    for (int i = 0; i < row.length; i++) {
      var cellValue = row[i]?.value?.toString() ?? '';
      if (cellValue.contains('-') ||
          cellValue.toLowerCase().contains('am') ||
          cellValue.toLowerCase().contains('pm')) {
        // Example format: 08:00 - 10:00 or 8am-10am
        var times = cellValue.split(RegExp(r'[-–]'));
        if (times.length == 2) {
          try {
            DateTime start = _parseTime(times[0].trim());
            DateTime end = _parseTime(times[1].trim());
            timeSlots.add(
              TimeSlotModel(
                label: cellValue,
                startTime: start,
                endTime: end,
                columnIndex: i,
              ),
            );
          } catch (e) {
            // Ignore non-time headers
          }
        }
      }
    }
    return timeSlots;
  }

  List<VenueModel> extractVenues(Sheet sheet) {
    List<VenueModel> venues = [];
    // Typically venues are in the first column starting from row 1
    for (int i = 1; i < sheet.rows.length; i++) {
      var cellValue = sheet.rows[i][0]?.value?.toString() ?? '';
      if (cellValue.isNotEmpty && !cellValue.toLowerCase().contains('day')) {
        venues.add(VenueModel(name: cellValue, rowIndex: i));
      }
    }
    return venues;
  }

  List<EventModel> buildEventsFromGrid({
    required Sheet sheet,
    required List<TimeSlotModel> timeSlots,
    required StudentProfileModel profile,
  }) {
    List<EventModel> events = [];

    // UMaT styles often have multiple venues (rows) and time slots (columns)
    // We need to iterate through the grid and find cells that match the profile
    for (int rowIndex = 1; rowIndex < sheet.rows.length; rowIndex++) {
      var row = sheet.rows[rowIndex];
      var venueCell = row[0]?.value?.toString() ?? 'Unknown Venue';

      for (var timeSlot in timeSlots) {
        var cell = row[timeSlot.columnIndex];
        var cellValue = cell?.value?.toString() ?? '';

        if (cellValue.contains(profile.programCode) &&
            cellValue.contains(profile.level)) {
          // Identify lecturer and title
          // UMaT format: MR 1B (Lecturer Name)
          var parts = cellValue.split('\n'); // Often multi-line
          String title = parts[0];
          String lecturer = parts.length > 1 ? parts[1] : 'Unknown Lecturer';

          events.add(
            EventModel(
              id:
                  DateTime.now().millisecondsSinceEpoch.toString() +
                  rowIndex.toString() +
                  timeSlot.columnIndex.toString(),
              title: title,
              lecturer: lecturer,
              venue: venueCell,
              dayOfWeek: _detectDayOfWeek(sheet, rowIndex),
              startTime: timeSlot.startTime,
              endTime: timeSlot.endTime,
              type: 'Class', // Default
            ),
          );
        }
      }
    }
    return events;
  }

  List<EventModel> mergeConsecutiveBlocks(List<EventModel> events) {
    if (events.isEmpty) return [];

    // Sort by day, venue, and start time
    events.sort((a, b) {
      int dayComp = a.dayOfWeek.compareTo(b.dayOfWeek);
      if (dayComp != 0) return dayComp;
      int venueComp = a.venue.compareTo(b.venue);
      if (venueComp != 0) return venueComp;
      return a.startTime.compareTo(b.startTime);
    });

    List<EventModel> mergedEvents = [];
    EventModel current = events[0];

    for (int i = 1; i < events.length; i++) {
      EventModel next = events[i];

      if (current.title == next.title &&
          current.venue == next.venue &&
          current.lecturer == next.lecturer &&
          current.dayOfWeek == next.dayOfWeek &&
          current.endTime == next.startTime) {
        // Merge
        current = current.copyWith(endTime: next.endTime);
      } else {
        mergedEvents.add(current);
        current = next;
      }
    }
    mergedEvents.add(current);
    return mergedEvents;
  }

  DateTime _parseTime(String timeStr) {
    // Helper to parse times like "08:00", "8am", "2pm"
    timeStr = timeStr.toLowerCase().replaceAll(' ', '');
    DateFormat format;
    if (timeStr.contains('am') || timeStr.contains('pm')) {
      format = DateFormat("ha");
      if (timeStr.contains(':')) {
        format = DateFormat("h:ma");
      }
    } else {
      format = DateFormat("H:mm");
    }

    DateTime parsed = format.parse(timeStr);
    // Use an arbitrary date for comparison (today)
    return DateTime(2024, 1, 1, parsed.hour, parsed.minute);
  }

  int _detectDayOfWeek(Sheet sheet, int rowIndex) {
    // UMaT timetables sometimes group rows by days or have a "Day" column
    // For now, let's assume a standard matrix where we might need to look up
    // the day from a previous row or a specific column.
    // This is a placeholder logic that needs to be refined based on actual sheet structure.
    // Common pattern: First column might indicate the day, and it's merged down.

    // Searching upwards for a day label if not in current row
    for (int i = rowIndex; i >= 0; i--) {
      var firstCell = sheet.rows[i][0]?.value?.toString().toLowerCase() ?? '';
      if (firstCell.contains('monday')) return 1;
      if (firstCell.contains('tuesday')) return 2;
      if (firstCell.contains('wednesday')) return 3;
      if (firstCell.contains('thursday')) return 4;
      if (firstCell.contains('friday')) return 5;
      if (firstCell.contains('saturday')) return 6;
      if (firstCell.contains('sunday')) return 7;
    }
    return 1; // Default to Monday
  }
}
