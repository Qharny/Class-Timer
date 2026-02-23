import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/class_event.dart';
import '../models/study_session.dart';
import '../models/course.dart';
import '../models/program.dart';
import '../models/user_productivity.dart';
import '../models/attendance_record.dart';
import 'notification_service.dart';
import 'calendar_sync_service.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  static const String classBoxName = 'class_events';
  static const String studyBoxName = 'study_sessions';
  static const String settingsBoxName = 'settings';
  static const String courseBoxName = 'courses';
  static const String programBoxName = 'program_profile';
  static const String productivityBoxName = 'user_productivity';
  static const String attendanceBoxName = 'attendance_records';
  static const String _onboardingKey = 'onboarding_complete';
  static const String _firstTimeKey = 'is_first_time';

  late SharedPreferences _prefs;

  Future<void> init() async {
    // NOTE: Hive.initFlutter() is already called in main() — do NOT call it again here
    _prefs = await SharedPreferences.getInstance();

    // Register Adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ClassEventAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(StudySessionAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(CourseAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(ProgramAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(UserProductivityAdapter());
    }
    if (!Hive.isAdapterRegistered(8)) {
      Hive.registerAdapter(AttendanceRecordAdapter());
    }

    // Open Boxes — with migration safety for schema changes
    await Hive.openBox<ClassEvent>(classBoxName);
    await Hive.openBox<StudySession>(studyBoxName);
    await Hive.openBox(settingsBoxName);
    await Hive.openBox<Course>(courseBoxName);
    await Hive.openBox<Program>(programBoxName);

    // Productivity box — adapter is now null-safe for schema migrations
    await Hive.openBox<UserProductivity>(productivityBoxName);

    // Attendance box: new in v2
    await Hive.openBox<AttendanceRecord>(attendanceBoxName);
  }

  Box<ClassEvent> get classBox => Hive.box<ClassEvent>(classBoxName);
  Box<StudySession> get studyBox => Hive.box<StudySession>(studyBoxName);
  Box get settingsBox => Hive.box(settingsBoxName);
  Box<Course> get courseBox => Hive.box<Course>(courseBoxName);
  Box<Program> get programBox => Hive.box<Program>(programBoxName);
  Box<UserProductivity> get productivityBox =>
      Hive.box<UserProductivity>(productivityBoxName);
  Box<AttendanceRecord> get attendanceBox =>
      Hive.box<AttendanceRecord>(attendanceBoxName);

  bool isOnboardingComplete() {
    return _prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> setOnboardingComplete(bool complete) async {
    await _prefs.setBool(_onboardingKey, complete);
  }

  bool isFirstTime() {
    final bool? isFirstTime = _prefs.getBool(_firstTimeKey);
    if (isFirstTime == null) {
      // First time running the app, set to false for future checks
      _prefs.setBool(_firstTimeKey, false);
      return true;
    }
    return false;
  }

  ThemeMode getThemeMode() {
    final mode = settingsBox.get('theme_mode', defaultValue: 'system');
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    String modeString;
    switch (mode) {
      case ThemeMode.light:
        modeString = 'light';
        break;
      case ThemeMode.dark:
        modeString = 'dark';
        break;
      default:
        modeString = 'system';
    }
    await settingsBox.put('theme_mode', modeString);
  }

  bool getNotificationsEnabled() =>
      settingsBox.get('notifications_enabled', defaultValue: true);
  Future<void> setNotificationsEnabled(bool value) async =>
      await settingsBox.put('notifications_enabled', value);

  bool getReminderEnabled(String key, {bool defaultValue = true}) {
    return settingsBox.get(key, defaultValue: defaultValue);
  }

  Future<void> setReminderEnabled(String key, bool value) async {
    await settingsBox.put(key, value);
  }

  String getUserName() {
    return settingsBox.get('user_name', defaultValue: 'Scholar');
  }

  Future<void> setUserName(String name) async {
    await settingsBox.put('user_name', name);
  }

  Future<void> clearAllData() async {
    await classBox.clear();
    await studyBox.clear();
    await settingsBox.clear();
    await setOnboardingComplete(false); // Reset onboarding on full clear
  }

  // New settings for Smart Buffer & Sync
  int getReminderMinutes() {
    return settingsBox.get('reminder_minutes', defaultValue: 15);
  }

  Future<void> setReminderMinutes(int minutes) async {
    await settingsBox.put('reminder_minutes', minutes);
  }

  bool getContextMessagesEnabled() {
    return settingsBox.get('context_messages_enabled', defaultValue: true);
  }

  Future<void> setContextMessagesEnabled(bool enabled) async {
    await settingsBox.put('context_messages_enabled', enabled);
  }

  bool isCrisisMode() {
    return settingsBox.get('crisis_mode', defaultValue: false);
  }

  Future<void> setCrisisMode(bool enabled) async {
    await settingsBox.put('crisis_mode', enabled);
  }

  bool getAutoFocusEnabled() {
    return settingsBox.get('auto_focus_enabled', defaultValue: false);
  }

  Future<void> setAutoFocusEnabled(bool enabled) async {
    await settingsBox.put('auto_focus_enabled', enabled);
  }

  bool getNotificationSoundEnabled() {
    return settingsBox.get('notification_sound', defaultValue: true);
  }

  Future<void> setNotificationSoundEnabled(bool enabled) async {
    await settingsBox.put('notification_sound', enabled);
  }

  bool getAlarmModeEnabled() {
    return settingsBox.get('alarm_mode', defaultValue: false);
  }

  Future<void> setAlarmModeEnabled(bool enabled) async {
    await settingsBox.put('alarm_mode', enabled);
  }

  String getSyncProvider() {
    return settingsBox.get('sync_provider', defaultValue: 'off');
  }

  Future<void> setSyncProvider(String provider) async {
    await settingsBox.put('sync_provider', provider);
  }

  String? getLastSyncTime() {
    return settingsBox.get('last_sync_time');
  }

  Future<void> setLastSyncTime(String time) async {
    await settingsBox.put('last_sync_time', time);
  }

  String getConnectedAccount() {
    return settingsBox.get('connected_account', defaultValue: 'Not connected');
  }

  Future<void> setConnectedAccount(String account) async {
    await settingsBox.put('connected_account', account);
  }

  // Academic Hierarchy CRUD
  Program? getProgram() {
    return programBox.get('current_program');
  }

  Future<void> setProgram(Program program) async {
    await programBox.put('current_program', program);
  }

  List<Course> getAllCourses() {
    return courseBox.values.toList();
  }

  Course? getCourse(String id) {
    return courseBox.get(id);
  }

  Future<void> addCourse(Course course) async {
    await courseBox.put(course.id, course);
  }

  Future<void> deleteCourse(String id) async {
    await courseBox.delete(id);
  }

  // Helper methods
  Future<void> addClassEvent(ClassEvent event) async {
    await classBox.put(event.id, event);
    await NotificationService().scheduleClassReminders(event);
    await CalendarSyncService().syncEvent(event);
  }

  Future<void> deleteClassEvent(String id) async {
    final event = classBox.get(id);
    if (event?.calendarEventId != null) {
      await CalendarSyncService().deleteEvent(event!.calendarEventId!);
    }
    await NotificationService().cancelNotificationsForEvent(id);
    await classBox.delete(id);
  }

  Future<void> addStudySession(StudySession session) async {
    await studyBox.put(session.id, session);
  }

  List<ClassEvent> getAllClassEvents() {
    return classBox.values.toList();
  }

  List<StudySession> getAllStudySessions() {
    return studyBox.values.toList();
  }

  // Productivity & Streak Logic
  UserProductivity getUserProductivity() {
    return productivityBox.get('stats', defaultValue: UserProductivity()) ??
        UserProductivity();
  }

  Future<void> updateStreak() async {
    final stats = getUserProductivity();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (stats.lastCompletedDate == null) {
      stats.currentStreak = 1;
      stats.coins += 5; // First ever session bonus
    } else {
      final lastDate = DateTime(
        stats.lastCompletedDate!.year,
        stats.lastCompletedDate!.month,
        stats.lastCompletedDate!.day,
      );
      final difference = today.difference(lastDate).inDays;

      if (difference == 1) {
        stats.currentStreak += 1;
      } else if (difference > 1) {
        // missed day - check for freeze
        if (stats.streakFreezes > 0) {
          stats.streakFreezes -= 1;
          stats.currentStreak += 1;
          // Note: In a real app, you might want to log this or notify the user
        } else {
          stats.currentStreak = 1;
        }
      }
      // If difference == 0 (same day), do nothing to streak
    }

    if (stats.currentStreak > stats.longestStreak) {
      stats.longestStreak = stats.currentStreak;
    }

    stats.lastCompletedDate = today;
    stats.totalCompletedSessions += 1;
    stats.coins += 2; // Fixed session reward

    await productivityBox.put('stats', stats);

    // Notification Milestones
    if (stats.currentStreak == 7) {
      stats.coins += 10;
      await NotificationService().sendInstantNotification(
        id: 1007,
        title: '🔥 7-Day Streak!',
        body: 'You\'re building momentum. Keep it up! (+10 coins)',
      );
    } else if (stats.currentStreak == 30) {
      stats.coins += 50;
      await NotificationService().sendInstantNotification(
        id: 1030,
        title: '🏆 30 Days Strong!',
        body: 'You\'re becoming highly disciplined. (+50 coins)',
      );
    }
  }

  Future<void> buyStreakFreeze() async {
    final stats = getUserProductivity();
    if (stats.coins >= 50) {
      stats.coins -= 50;
      stats.streakFreezes += 1;
      await productivityBox.put('stats', stats);
    }
  }

  Future<void> addCoins(int amount) async {
    final stats = getUserProductivity();
    stats.coins += amount;
    await productivityBox.put('stats', stats);
  }

  // Attendance Management
  Future<void> markAttendance(
    String eventId,
    DateTime date,
    bool attended,
  ) async {
    final key = '${eventId}_${date.year}${date.month}${date.day}';
    await attendanceBox.put(
      key,
      AttendanceRecord(eventId: eventId, date: date, attended: attended),
    );
  }

  List<AttendanceRecord> getAttendanceForEvent(String eventId) {
    return attendanceBox.values.where((r) => r.eventId == eventId).toList();
  }

  double getAttendancePercentage(String eventId) {
    final records = getAttendanceForEvent(eventId);
    if (records.isEmpty) return 100.0;
    final attendedCount = records.where((r) => r.attended).length;
    return (attendedCount / records.length) * 100;
  }
}
