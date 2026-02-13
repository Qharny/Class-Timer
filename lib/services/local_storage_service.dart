import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/class_event.dart';
import '../models/study_session.dart';

class LocalStorageService {
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
