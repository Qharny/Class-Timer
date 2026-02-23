import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';
import '../models/class_event.dart';

class StudyPlannerScreen extends StatefulWidget {
  const StudyPlannerScreen({super.key});

  @override
  State<StudyPlannerScreen> createState() => _StudyPlannerScreenState();
}

class _StudyPlannerScreenState extends State<StudyPlannerScreen> {
  final _storageService = LocalStorageService();
  final List<String> _topics = [];
  final TextEditingController _topicController = TextEditingController();

  List<Map<String, dynamic>> _suggestedGaps = [];

  @override
  void initState() {
    super.initState();
    _calculateGaps();
  }

  void _calculateGaps() {
    final events = _storageService.getAllClassEvents();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Sort events by time
    final List<ClassEvent> dayEvents = events
        .where((e) => e.dayOfWeek == today.weekday)
        .toList();
    dayEvents.sort((a, b) => a.startTime.compareTo(b.startTime));

    List<Map<String, dynamic>> gaps = [];

    // Day starts at 8:00 AM
    String lastEnd = "08:00";

    for (var event in dayEvents) {
      if (_isGapSignificant(lastEnd, event.startTime)) {
        gaps.add({
          'start': lastEnd,
          'end': event.startTime,
          'duration': _getDurationMinutes(lastEnd, event.startTime),
        });
      }
      lastEnd = event.endTime;
    }

    // Check gap until 8:00 PM
    if (_isGapSignificant(lastEnd, "20:00")) {
      gaps.add({
        'start': lastEnd,
        'end': "20:00",
        'duration': _getDurationMinutes(lastEnd, "20:00"),
      });
    }

    setState(() {
      _suggestedGaps = gaps;
    });
  }

  bool _isGapSignificant(String start, String end) {
    return _getDurationMinutes(start, end) >= 45;
  }

  int _getDurationMinutes(String start, String end) {
    final s = start.split(':');
    final e = end.split(':');
    final sMin = int.parse(s[0]) * 60 + int.parse(s[1]);
    final eMin = int.parse(e[0]) * 60 + int.parse(e[1]);
    return eMin - sMin;
  }

  void _addTopic() {
    if (_topicController.text.isNotEmpty) {
      setState(() {
        _topics.add(_topicController.text);
        _topicController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Study Planner')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'What are you studying for?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _topicController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Calculus Exam, Bio Quiz',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _addTopic,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _topics
                  .map(
                    (t) => Chip(
                      label: Text(t),
                      onDeleted: () => setState(() => _topics.remove(t)),
                      backgroundColor: Theme.of(
                        context,
                      ).primaryColor.withOpacity(0.1),
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: 32),
            const Text(
              'Detected Free Slots Today',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _suggestedGaps.isEmpty
                ? _buildNoGapsState()
                : Column(
                    children: _suggestedGaps
                        .map((gap) => _buildGapCard(gap))
                        .toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildGapCard(Map<String, dynamic> gap) {
    final duration = gap['duration'];
    final topic = _topics.isNotEmpty
        ? _topics[(_suggestedGaps.indexOf(gap) % _topics.length)]
        : 'General Study';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topic,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${gap['start']} - ${gap['end']} (${duration}m gap)',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final newEvent = ClassEvent(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: 'Study: $topic',
                type: 'study',
                dayOfWeek: DateTime.now().weekday,
                startTime: gap['start'],
                endTime: gap['end'],
                venue: 'Library/Home',
              );
              await _storageService.addClassEvent(newEvent);
              _calculateGaps(); // Refresh
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Study block "$topic" added to schedule!'),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text('PLAN'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoGapsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Your schedule is packed today!',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Text(
            'Keep it up, Scholar.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
