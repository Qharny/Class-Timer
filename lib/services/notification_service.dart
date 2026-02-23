import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import '../models/class_event.dart';
import '../services/local_storage_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> init() async {
    final storage = LocalStorageService();
    final bool playSound = storage.getNotificationSoundEnabled();
    final bool alarmMode = storage.getAlarmModeEnabled();

    await AwesomeNotifications().initialize('resource://mipmap/launcher_icon', [
      NotificationChannel(
        channelKey: 'class_reminders',
        channelName: 'Class Reminders',
        channelDescription: 'Notifications for class start times',
        defaultColor: const Color(0xFF9D50BB),
        ledColor: Colors.white,
        importance: alarmMode
            ? NotificationImportance.Max
            : NotificationImportance.High,
        channelShowBadge: true,
        onlyAlertOnce: true,
        playSound: playSound,
        criticalAlerts: true,
      ),
      NotificationChannel(
        channelKey: 'streak_reminders',
        channelName: 'Streak & Motivation',
        channelDescription: 'Daily reminders to keep your streak alive',
        defaultColor: const Color(0xFFFF5722),
        ledColor: Colors.orange,
        importance: NotificationImportance.High,
        channelShowBadge: true,
        playSound: playSound,
      ),
      NotificationChannel(
        channelKey: 'engagement_nudges',
        channelName: 'Engagement Nudges',
        channelDescription: 'Gentle reminders to return to your studies',
        defaultColor: const Color(0xFF4CAF50),
        ledColor: Colors.green,
        importance: NotificationImportance.Default,
        playSound: playSound,
      ),
    ], debug: true);
  }

  Future<void> requestPermissions() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  Future<void> scheduleClassReminders(ClassEvent event) async {
    final storage = LocalStorageService();
    if (!storage.getNotificationsEnabled()) return;

    // Smart Buffer Dynamic Reminder
    final bufferMinutes = storage.getReminderMinutes();
    final parts = event.startTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    DateTime scheduledTime = DateTime(
      2024,
      1,
      1,
      hour,
      minute,
    ).subtract(Duration(minutes: bufferMinutes));

    final isCrisis = storage.isCrisisMode();
    final crisisPrefix = isCrisis ? '🚨 [CRISIS MODE] ' : '';

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: event.id.hashCode + 4, // unique offset for dynamic buffer
        channelKey: 'class_reminders',
        title: '${crisisPrefix}Class Buffer Alert',
        body: 'Your class ${event.title} starts in $bufferMinutes minutes.',
        notificationLayout: NotificationLayout.Default,
        category: storage.getAlarmModeEnabled()
            ? NotificationCategory.Alarm
            : NotificationCategory.Reminder,
      ),
      schedule: NotificationCalendar(
        weekday: event.dayOfWeek,
        hour: scheduledTime.hour,
        minute: scheduledTime.minute,
        second: 0,
        millisecond: 0,
        repeats: true,
      ),
    );

    // 15-minute Reminder
    if (storage.settingsBox.get('reminder_15_min', defaultValue: true)) {
      final parts = event.startTime.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      // Calculate 15 mins before
      DateTime dummy = DateTime(
        2024,
        1,
        1,
        hour,
        minute,
      ).subtract(const Duration(minutes: 15));

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: event.id.hashCode + 1,
          channelKey: 'class_reminders',
          title: 'Class Starting Soon',
          body: 'You have 15 minutes until ${event.title} at ${event.venue}.',
          notificationLayout: NotificationLayout.Default,
          category: storage.getAlarmModeEnabled()
              ? NotificationCategory.Alarm
              : NotificationCategory.Reminder,
        ),
        schedule: NotificationCalendar(
          weekday: event.dayOfWeek,
          hour: dummy.hour,
          minute: dummy.minute,
          second: 0,
          millisecond: 0,
          repeats: true,
        ),
      );
    }

    // 5-minute Reminder
    if (storage.settingsBox.get('reminder_5_min', defaultValue: true)) {
      final parts = event.startTime.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      DateTime dummy = DateTime(
        2024,
        1,
        1,
        hour,
        minute,
      ).subtract(const Duration(minutes: 5));

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: event.id.hashCode + 2,
          channelKey: 'class_reminders',
          title: 'Move Now!',
          body: 'Time to head to ${event.venue}. Class starts in 5 minutes.',
          notificationLayout: NotificationLayout.Default,
          category: storage.getAlarmModeEnabled()
              ? NotificationCategory.Alarm
              : NotificationCategory.Reminder,
        ),
        schedule: NotificationCalendar(
          weekday: event.dayOfWeek,
          hour: dummy.hour,
          minute: dummy.minute,
          second: 0,
          millisecond: 0,
          repeats: true,
        ),
      );
    }

    // Wrap-up Reminder
    if (storage.settingsBox.get('reminder_wrap_up', defaultValue: true)) {
      final endParts = event.endTime.split(':');
      final hour = int.parse(endParts[0]);
      final minute = int.parse(endParts[1]);

      DateTime dummy = DateTime(
        2024,
        1,
        1,
        hour,
        minute,
      ).subtract(const Duration(minutes: 5));

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: event.id.hashCode + 3,
          channelKey: 'class_reminders',
          title: 'Wrap Up',
          body: '${event.title} is ending soon. Prepare for transition.',
          notificationLayout: NotificationLayout.Default,
        ),
        schedule: NotificationCalendar(
          weekday: event.dayOfWeek,
          hour: dummy.hour,
          minute: dummy.minute,
          second: 0,
          millisecond: 0,
          repeats: true,
        ),
      );
    }
  }

  Future<void> scheduleStreakReminder() async {
    final storage = LocalStorageService();
    if (!storage.getNotificationsEnabled()) return;
    if (!storage.settingsBox.get('streak_reminder', defaultValue: true)) return;

    final stats = storage.getUserProductivity();

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 999,
        channelKey: 'streak_reminders',
        title: '🔥 Streak At Risk',
        body:
            'Don\'t lose your ${stats.currentStreak}-day streak. Complete a session now!',
      ),
      schedule: NotificationCalendar(
        hour: 20,
        minute: 0,
        second: 0,
        millisecond: 0,
        repeats: true,
      ),
    );
  }

  Future<void> scheduleDailyMotivation() async {
    final storage = LocalStorageService();
    if (!storage.getNotificationsEnabled()) return;
    if (!storage.settingsBox.get('daily_motivation', defaultValue: true)) {
      return;
    }

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 888,
        channelKey: 'streak_reminders', // Using same channel for discipline
        title: 'Morning Motivation',
        body: 'Consistency builds excellence. Ready for a new day of progress?',
      ),
      schedule: NotificationCalendar(
        hour: 7,
        minute: 0,
        second: 0,
        millisecond: 0,
        repeats: true,
      ),
    );
  }

  Future<void> scheduleEngagementNudge() async {
    final storage = LocalStorageService();
    if (!storage.getNotificationsEnabled()) return;

    // Engagement nudge is scheduled once for 48 hours later
    // AwesomeNotifications doesn't have a simple "Duration" schedule that survives reboot as easily as Calendar
    // but we can use NotificationInterval
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 777,
        channelKey: 'engagement_nudges',
        title: 'Your Timetable Misses You',
        body:
            'Consistency is key to academic success. Let\'s get back to your study goals!',
      ),
      schedule: NotificationInterval(
        interval: const Duration(hours: 48),
        repeats: false,
      ),
    );
  }

  Future<void> cancelNotificationsForEvent(String eventId) async {
    final baseId = eventId.hashCode;
    await AwesomeNotifications().cancel(baseId + 1);
    await AwesomeNotifications().cancel(baseId + 2);
    await AwesomeNotifications().cancel(baseId + 3);
    await AwesomeNotifications().cancel(baseId + 4);
  }

  Future<void> rescheduleAll() async {
    await AwesomeNotifications().cancelAllSchedules();
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
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'streak_reminders', // Generic for milestones
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }
}
