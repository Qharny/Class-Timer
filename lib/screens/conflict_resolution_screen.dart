import 'package:flutter/material.dart' hide DateTimeRange;
import '../models/class_event.dart';
import '../models/domain_models.dart';
import '../services/rescheduling_engine.dart';

class ConflictResolutionScreen extends StatefulWidget {
  final ClassEvent existingEvent;
  final ClassEvent conflictingEvent;
  final List<ClassEvent> allEvents;
  final Function(ClassEvent) onResolved;

  const ConflictResolutionScreen({
    super.key,
    required this.existingEvent,
    required this.conflictingEvent,
    required this.allEvents,
    required this.onResolved,
  });

  @override
  State<ConflictResolutionScreen> createState() =>
      _ConflictResolutionScreenState();
}

class _ConflictResolutionScreenState extends State<ConflictResolutionScreen> {
  DateTimeRange? _suggestion;

  @override
  void initState() {
    super.initState();
    _generateSuggestion();
  }

  void _generateSuggestion() {
    // Only suggest rescheduling if the conflicting event is a 'study' type
    // Or if one of them is flexible. For now, let's just find a free slot.
    final domainEvents = widget.allEvents.map((e) => _toEntity(e)).toList();

    final slots = ReschedulingEngine.findFreeSlots(
      existingEvents: domainEvents,
      day: DateTime.now(), // Simplified: assuming today for suggestion
      startLimit: const TimeOfDay(hour: 7, minute: 0),
      endLimit: const TimeOfDay(hour: 22, minute: 0),
      minDuration: const Duration(hours: 1),
    );

    if (slots.isNotEmpty) {
      setState(() {
        _suggestion = slots.first;
      });
    }
  }

  EventEntity _toEntity(ClassEvent e) {
    // Basic mapping for engine use
    return EventEntity(
      id: e.id,
      title: e.title,
      type: e.type == 'class' ? EventType.classEvent : EventType.study,
      startTime: _parseTime(e.startTime),
      endTime: _parseTime(e.endTime),
      venue: e.venue,
      priority: e.type == 'class' ? 1 : 2,
    );
  }

  DateTime _parseTime(String time) {
    final parts = time.split(':');
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Conflict Detected')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 64,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              'You have a conflict.',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            _buildConflictPair(),
            const Spacer(),
            if (_suggestion != null) _buildSuggestionCard(),
            const SizedBox(height: 24),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildConflictPair() {
    return Column(
      children: [
        _buildEventSmallCard(
          'Existing Event',
          widget.existingEvent,
          Colors.grey,
        ),
        const SizedBox(height: 12),
        const Icon(Icons.swap_vert, color: Colors.grey),
        const SizedBox(height: 12),
        _buildEventSmallCard('New Event', widget.conflictingEvent, Colors.red),
      ],
    );
  }

  Widget _buildEventSmallCard(String label, ClassEvent event, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            event.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            '${event.startTime} - ${event.endTime}',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard() {
    final startStr =
        '${_suggestion!.start.hour.toString().padLeft(2, '0')}:${_suggestion!.start.minute.toString().padLeft(2, '0')}';
    final endStr =
        '${_suggestion!.end.hour.toString().padLeft(2, '0')}:${_suggestion!.end.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Text(
            'Suggested Fix',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          const SizedBox(height: 8),
          Text('Move ${widget.conflictingEvent.title} to $startStr - $endStr?'),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        if (_suggestion != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final startStr =
                    '${_suggestion!.start.hour.toString().padLeft(2, '0')}:${_suggestion!.start.minute.toString().padLeft(2, '0')}';
                final endStr =
                    '${_suggestion!.end.hour.toString().padLeft(2, '0')}:${_suggestion!.end.minute.toString().padLeft(2, '0')}';
                widget.conflictingEvent.startTime = startStr;
                widget.conflictingEvent.endTime = endStr;
                widget.onResolved(widget.conflictingEvent);
                Navigator.pop(context);
              },
              child: const Text('Accept Suggestion'),
            ),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  // Simply pop and let parent know to use as-is
                  widget.onResolved(widget.conflictingEvent);
                  Navigator.pop(context);
                },
                child: const Text('Ignore'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Edit Manually'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
