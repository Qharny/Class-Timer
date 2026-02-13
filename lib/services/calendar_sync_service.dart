import '../models/domain_models.dart';

class CalendarSyncService {
  /// Syncs an event to an external calendar.
  /// Strategy: Optimistic local save first, then async background sync.
  Future<void> syncEvent(EventEntity event) async {
    // 1. Check if event has external ID
    // if (event.externalCalendarId != null)
    //   await _updateExternal(event);
    // else
    //   await _createExternal(event);
  }

  /// Handles when events are deleted externally.
  Future<void> handleExternalDeletion(String externalId) async {
    // Logic to remove local link or delete local event
  }
}
