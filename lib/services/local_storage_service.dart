import 'package:hive_flutter/hive_flutter.dart';
import '../models/class_event.dart';
import '../models/study_session.dart';

class LocalStorageService {
  static const String classBoxName = 'class_events';
  static const String studyBoxName = 'study_sessions';
  static const String settingsBoxName = 'settings';

  Future<void> init() async {
    await Hive.initFlutter();

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
    return settingsBox.get('onboarding_complete', defaultValue: false);
  }

  Future<void> setOnboardingComplete(bool complete) async {
    await settingsBox.put('onboarding_complete', complete);
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
