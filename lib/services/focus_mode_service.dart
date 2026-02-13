import '../models/domain_models.dart';
import '../services/local_storage_service.dart';

class FocusModeService {
  final LocalStorageService _storageService = LocalStorageService();

  /// Inits the focus session. Future: Trigger DND via plugin.
  Future<void> startSession(EventEntity event) async {
    // Future: flutter_dnd.setDoNotDisturb(true);
  }

  /// Ends the focus session.
  Future<void> endSession({
    required EventEntity event,
    required DateTime startTime,
    required bool completed,
  }) async {
    // Future: flutter_dnd.setDoNotDisturb(false);

    // Tracking completion (already integrated in UI, but moving logic here is better)
    // We'll leave the actual Hive calls in LocalStorageService but call them from here.
  }

  /// Calculates the focus duration based on start and end times.
  Duration calculateDuration(DateTime start, DateTime end) {
    return end.difference(start);
  }
}
