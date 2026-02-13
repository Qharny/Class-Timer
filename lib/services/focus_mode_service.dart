import '../models/domain_models.dart';

class FocusModeService {
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

  static const List<String> motivationalPhrases = [
    'Stay locked in.',
    'Deep work only.',
    'The future is built now.',
    'Eyes on the prize.',
    'Momentum is everything.',
    'One block at a time.',
    'Make it count.',
    'Pure focus.',
  ];

  String getRandomPhrase() {
    return (List<String>.from(motivationalPhrases)..shuffle()).first;
  }
}
