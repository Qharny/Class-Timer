import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/class_event.dart';
import '../models/study_session.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  static const String classBoxName = 'class_events';
  static const String studyBoxName = 'study_sessions';
  static const String settingsBoxName = 'settings';
  static const String _onboardingKey = 'onboarding_complete';
  static const String _firstTimeKey = 'is_first_time';

  late SharedPreferences _prefs;

  Future<void> init() async {
    await Hive.initFlutter();
    _prefs = await SharedPreferences.getInstance();

    // Register Adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ClassEventAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(StudySessionAdapter());
    }

    // Open Boxes
    await Hive.openBox<ClassEvent>(classBoxName);
    await Hive.openBox<StudySession>(studyBoxName);
    await Hive.openBox(settingsBoxName);
  }

  Box<ClassEvent> get classBox => Hive.box<ClassEvent>(classBoxName);
  Box<StudySession> get studyBox => Hive.box<StudySession>(studyBoxName);
  Box get settingsBox => Hive.box(settingsBoxName);

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

  bool getNotificationsEnabled() {
    return settingsBox.get('notifications_enabled', defaultValue: true);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await settingsBox.put('notifications_enabled', enabled);
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

  bool getAutoFocusEnabled() {
    return settingsBox.get('auto_focus_enabled', defaultValue: false);
  }

  Future<void> setAutoFocusEnabled(bool enabled) async {
    await settingsBox.put('auto_focus_enabled', enabled);
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

  // Helper methods
  Future<void> addClassEvent(ClassEvent event) async {
    await classBox.put(event.id, event);
  }

  Future<void> deleteClassEvent(String id) async {
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
}
