import '../models/domain_models.dart';

class NotificationService {
  Future<void> init() async {
    // Future: Initialize flutter_local_notifications or similar
  }

  /// Schedules a "Smart Buffer" notification for an event.
  /// Logic: Classes get "Head to venue", Study sessions get "Prepare materials".
  Future<void> scheduleSmartReminder(EventEntity event) async {
    final bufferTime = const Duration(minutes: 10);
    final reminderTime = event.startTime.subtract(bufferTime);

    if (reminderTime.isBefore(DateTime.now())) return;

    String message;
    if (event.type == EventType.study) {
      message = "Prepare your materials for: ${event.title}";
    } else {
      message = "Time to head to your venue: ${event.venue ?? 'Room'}";
    }

    _sendToSystem(
      id: event.id.hashCode,
      title: event.title,
      body: message,
      scheduledTime: reminderTime,
    );
  }

  /// Schedules an "End Session" buffer to wrap up.
  Future<void> scheduleWrapUp(EventEntity event) async {
    final bufferTime = const Duration(minutes: 5);
    final reminderTime = event.endTime.subtract(bufferTime);

    if (reminderTime.isBefore(DateTime.now())) return;

    _sendToSystem(
      id: '${event.id}_end'.hashCode,
      title: "Wrapping up: ${event.title}",
      body: "Session ends in 5 minutes.",
      scheduledTime: reminderTime,
    );
  }

  Future<void> _sendToSystem({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    // Here we would call the platform-specific notification plugin.
    // For now, mirroring the architecture's focus on logic separation.
  }

  Future<void> cancelReminder(String id) async {
    // Platform-specific cancel logic
  }
}
