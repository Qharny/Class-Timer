import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';
import '../models/class_event.dart';

class AbsenceTrackerScreen extends StatefulWidget {
  const AbsenceTrackerScreen({super.key});

  @override
  State<AbsenceTrackerScreen> createState() => _AbsenceTrackerScreenState();
}

class _AbsenceTrackerScreenState extends State<AbsenceTrackerScreen> {
  final _storageService = LocalStorageService();

  @override
  Widget build(BuildContext context) {
    final events = _storageService.getAllClassEvents();

    // Group events by title (assuming title is the course name for this simple tracker)
    final Map<String, List<ClassEvent>> courseGroups = {};
    for (var event in events) {
      if (!courseGroups.containsKey(event.title)) {
        courseGroups[event.title] = [];
      }
      courseGroups[event.title]!.add(event);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Absence Tracker')),
      body: events.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: courseGroups.length,
              itemBuilder: (context, index) {
                final courseName = courseGroups.keys.elementAt(index);
                final groupEvents = courseGroups[courseName]!;
                final eventId = groupEvents
                    .first
                    .id; // Using first event ID as proxy for the course stats
                final percentage = _storageService.getAttendancePercentage(
                  eventId,
                );

                return _buildCourseAttendanceCard(
                  courseName,
                  percentage,
                  eventId,
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_note, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No classes found to track.',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseAttendanceCard(
    String name,
    double percentage,
    String eventId,
  ) {
    Color statusColor = Colors.green;
    if (percentage < 75) statusColor = Colors.orange;
    if (percentage < 50) statusColor = Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        percentage < 75
                            ? 'Risk of attendance shortage'
                            : 'Safe attendance level',
                        style: TextStyle(
                          color: statusColor.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${percentage.toInt()}%',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showAttendanceHistory(name, eventId),
                  icon: const Icon(Icons.history, size: 18),
                  label: const Text('HISTORY'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _markManualAttendance(name, eventId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('MARK ATTENDANCE'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _markManualAttendance(String name, String eventId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Attendance: $name',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Attended'),
              onTap: () async {
                await _storageService.markAttendance(
                  eventId,
                  DateTime.now(),
                  true,
                );
                if (mounted) Navigator.pop(context);
                setState(() {});
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: const Text('Missed'),
              onTap: () async {
                await _storageService.markAttendance(
                  eventId,
                  DateTime.now(),
                  false,
                );
                if (mounted) Navigator.pop(context);
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAttendanceHistory(String name, String eventId) {
    final records = _storageService.getAttendanceForEvent(eventId);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$name History'),
        content: SizedBox(
          width: double.maxFinite,
          child: records.isEmpty
              ? const Text('No history recorded yet.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final record = records[index];
                    return ListTile(
                      leading: Icon(
                        record.attended ? Icons.check_circle : Icons.cancel,
                        color: record.attended ? Colors.green : Colors.red,
                      ),
                      title: Text(
                        '${record.date.day}/${record.date.month}/${record.date.year}',
                      ),
                      subtitle: Text(record.attended ? 'Attended' : 'Missed'),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }
}
