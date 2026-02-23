import 'package:device_calendar/device_calendar.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/class_event.dart';
import '../services/local_storage_service.dart';

class CalendarSyncService {
  final DeviceCalendarPlugin _calendarPlugin = DeviceCalendarPlugin();

  Future<void> syncEvent(ClassEvent event) async {
    final storage = LocalStorageService();
    final provider = storage.getSyncProvider();
    if (provider == 'off') return;

    final permissionsGranted = await _calendarPlugin.requestPermissions();
    if (!permissionsGranted.isSuccess || !permissionsGranted.data!) return;

    final calendars = await _calendarPlugin.retrieveCalendars();
    if (!calendars.isSuccess || calendars.data == null) return;

    // Logic to select calendar
    Calendar? targetCalendar;
    if (provider == 'google') {
      targetCalendar = calendars.data!.firstWhere(
        (c) => c.accountType == 'com.google' || c.name!.contains('gmail'),
        orElse: () => calendars.data!.first,
      );
    } else {
      targetCalendar = calendars.data!.firstWhere(
        (c) => c.isDefault ?? false,
        orElse: () => calendars.data!.first,
      );
    }

    // Prepare Event details
    final now = DateTime.now();
    final startParts = event.startTime.split(':');
    final endParts = event.endTime.split(':');

    // Find the next occurrence of this day
    int daysUntil = (event.dayOfWeek - now.weekday + 7) % 7;
    if (daysUntil == 0 &&
        _isPast(int.parse(startParts[0]), int.parse(startParts[1]))) {
      daysUntil = 7;
    }

    final firstOccurrence = now.add(Duration(days: daysUntil));
    final startDateTime = DateTime(
      firstOccurrence.year,
      firstOccurrence.month,
      firstOccurrence.day,
      int.parse(startParts[0]),
      int.parse(startParts[1]),
    );
    final endDateTime = DateTime(
      firstOccurrence.year,
      firstOccurrence.month,
      firstOccurrence.day,
      int.parse(endParts[0]),
      int.parse(endParts[1]),
    );

    final calendarEvent = Event(
      targetCalendar.id,
      eventId: event.calendarEventId,
      title: event.title,
      description: 'Automatically synced from Class Timer',
      location: event.venue,
      start: tz.TZDateTime.from(startDateTime, tz.local),
      end: tz.TZDateTime.from(endDateTime, tz.local),
      recurrenceRule: RecurrenceRule(RecurrenceFrequency.Weekly, interval: 1),
    );

    final result = await _calendarPlugin.createOrUpdateEvent(calendarEvent);
    if (result != null && result.isSuccess) {
      event.calendarEventId = result.data;
      await event.save();
    }
  }

  Future<void> deleteEvent(String calendarEventId) async {
    final storage = LocalStorageService();
    if (storage.getSyncProvider() == 'off') return;

    final calendars = await _calendarPlugin.retrieveCalendars();
    if (calendars.isSuccess && calendars.data != null) {
      for (var cal in calendars.data!) {
        await _calendarPlugin.deleteEvent(cal.id, calendarEventId);
      }
    }
  }

  bool _isPast(int hour, int minute) {
    final now = DateTime.now();
    if (now.hour > hour) return true;
    if (now.hour == hour && now.minute >= minute) return true;
    return false;
  }
}
