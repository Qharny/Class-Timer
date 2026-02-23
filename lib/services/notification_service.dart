import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/class_event.dart';
import '../services/local_storage_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap if needed
      },
    );
  }

  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      await androidImplementation?.requestNotificationsPermission();
    }
  }

  Future<void> scheduleClassReminders(ClassEvent event) async {
    final storage = LocalStorageService();
    if (!storage.getNotificationsEnabled()) return;

    final now = DateTime.now();
    final parts = event.startTime.split(':');
    final eventStart = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );

    DateTime scheduledDate = _getNextOccurrence(event.dayOfWeek, eventStart);

    // 15-minute Reminder
    if (storage.settingsBox.get('reminder_15_min', defaultValue: true)) {
      final reminderTime = scheduledDate.subtract(const Duration(minutes: 15));
      if (reminderTime.isAfter(now)) {
        await _scheduleNotification(
          id: event.id.hashCode + 1,
          title: 'Class Starting Soon',
          body: 'You have 15 minutes until ${event.title} at ${event.venue}.',
          scheduledDate: reminderTime,
        );
      }
    }

    // 5-minute Reminder
    if (storage.settingsBox.get('reminder_5_min', defaultValue: true)) {
      final reminderTime = scheduledDate.subtract(const Duration(minutes: 5));
      if (reminderTime.isAfter(now)) {
        await _scheduleNotification(
          id: event.id.hashCode + 2,
          title: 'Move Now!',
          body: 'Time to head to ${event.venue}. Class starts in 5 minutes.',
          scheduledDate: reminderTime,
        );
      }
    }

    // Wrap-up Reminder
    if (storage.settingsBox.get('reminder_wrap_up', defaultValue: true)) {
      final endParts = event.endTime.split(':');
      final eventEnd = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(endParts[0]),
        int.parse(endParts[1]),
      );
      final scheduledEnd = _getNextOccurrence(event.dayOfWeek, eventEnd);
      final reminderTime = scheduledEnd.subtract(const Duration(minutes: 5));
      if (reminderTime.isAfter(now)) {
        await _scheduleNotification(
          id: event.id.hashCode + 3,
          title: 'Wrap Up',
          body: '${event.title} is ending soon. Prepare for transition.',
          scheduledDate: reminderTime,
        );
      }
    }
  }

  Future<void> scheduleStreakReminder() async {
    final storage = LocalStorageService();
    if (!storage.getNotificationsEnabled()) return;
    if (!storage.settingsBox.get('streak_reminder', defaultValue: true)) return;

    final stats = storage.getUserProductivity();
    final now = DateTime.now();
    final reminderTime = DateTime(
      now.year,
      now.month,
      now.day,
      20,
      0,
    ); // 8:00 PM

    DateTime scheduledDate = reminderTime;
    if (now.isAfter(reminderTime)) {
      scheduledDate = reminderTime.add(const Duration(days: 1));
    }

    await _scheduleNotification(
      id: 999,
      title: '🔥 Streak At Risk',
      body:
          'Don\'t lose your ${stats.currentStreak}-day streak. Complete a session now!',
      scheduledDate: scheduledDate,
    );
  }

  Future<void> scheduleDailyMotivation() async {
    final storage = LocalStorageService();
    if (!storage.getNotificationsEnabled()) return;
    if (!storage.settingsBox.get('daily_motivation', defaultValue: true)) {
      return;
    }

    final now = DateTime.now();
    final reminderTime = DateTime(
      now.year,
      now.month,
      now.day,
      7,
      0,
    ); // 7:00 AM

    DateTime scheduledDate = reminderTime;
    if (now.isAfter(reminderTime)) {
      scheduledDate = reminderTime.add(const Duration(days: 1));
    }

    await _scheduleNotification(
      id: 888,
      title: 'Morning Motivation',
      body: 'Consistency builds excellence. Ready for a new day of progress?',
      scheduledDate: scheduledDate,
    );
  }

  Future<void> scheduleEngagementNudge() async {
    final storage = LocalStorageService();
    if (!storage.getNotificationsEnabled()) return;

    // Schedule for 48 hours from now
    final scheduledDate = DateTime.now().add(const Duration(hours: 48));

    await _scheduleNotification(
      id: 777,
      title: 'Your Timetable Misses You',
      body:
          'Consistency is key to academic success. Let\'s get back to your study goals!',
      scheduledDate: scheduledDate,
    );
  }

  Future<void> cancelNotificationsForEvent(String eventId) async {
    final baseId = eventId.hashCode;
    await _notificationsPlugin.cancel(id: baseId + 1);
    await _notificationsPlugin.cancel(id: baseId + 2);
    await _notificationsPlugin.cancel(id: baseId + 3);
  }

  Future<void> rescheduleAll() async {
    await _notificationsPlugin.cancelAll();
    final events = LocalStorageService().getAllClassEvents();
    for (final event in events) {
      await scheduleClassReminders(event);
    }
    await scheduleStreakReminder();
    await scheduleDailyMotivation();
    await scheduleEngagementNudge();
  }

  Future<void> sendInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'instant_notifications',
      'Instant Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'class_timer_reminders',
          'Class Timer Reminders',
          channelDescription: 'Notifications for class and streak reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  DateTime _getNextOccurrence(int dayOfWeek, DateTime eventTime) {
    DateTime scheduledDate = eventTime;
    while (scheduledDate.weekday != dayOfWeek) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    if (scheduledDate.isBefore(DateTime.now())) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    return scheduledDate;
  }
}
