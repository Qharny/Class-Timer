import 'package:flutter/material.dart';
import '../models/class_event.dart';
import '../models/course.dart';
import '../models/study_session.dart';
import '../services/local_storage_service.dart';

class EventDetailScreen extends StatelessWidget {
  final ClassEvent event;

  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isStudy = event.type == 'study';
    final course = event.courseId != null
        ? LocalStorageService().getCourse(event.courseId!)
        : null;
    final courseColor = course != null
        ? Color(int.parse(course.colorTag.replaceFirst('#', '0xFF')))
        : theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Event Detail'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.pushNamed(context, '/edit-event', arguments: event);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _showDeleteConfirmation(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme, course, courseColor),
            const SizedBox(height: 32),
            _buildInfoCards(theme, course, courseColor),
            const SizedBox(height: 32),
            _buildSettingsSection(theme, isStudy),
            const SizedBox(height: 48),
            _buildActionButtons(context, theme),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, Course? course, Color courseColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color:
                    (course != null ? courseColor : theme.colorScheme.primary)
                        .withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                event.type.toUpperCase(),
                style: TextStyle(
                  color: course != null
                      ? courseColor
                      : theme.colorScheme.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            if (course != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  course.code,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Text(
          event.title,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (course != null)
          Text(
            course.name,
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
          ),
      ],
    );
  }

  Widget _buildInfoCards(ThemeData theme, Course? course, Color courseColor) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                theme,
                Icons.access_time_rounded,
                'Time',
                '${event.startTime} - ${event.endTime}',
                _getDay(event.dayOfWeek),
                courseColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInfoCard(
                theme,
                Icons.location_on_outlined,
                'Venue',
                event.venue.isEmpty ? 'Not Set' : event.venue,
                'Campus Location',
                courseColor,
              ),
            ),
          ],
        ),
        if (course != null) ...[
          const SizedBox(height: 16),
          _buildInfoCard(
            theme,
            Icons.school_outlined,
            'Academics',
            '${course.creditHours} Credit Hours',
            'Lecturer: ${course.lecturer}',
            courseColor,
            fullWidth: true,
          ),
        ],
      ],
    );
  }

  Widget _buildInfoCard(
    ThemeData theme,
    IconData icon,
    String label,
    String value,
    String subValue,
    Color accentColor, {
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: accentColor),
          const SizedBox(height: 12),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          Text(
            subValue,
            style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(ThemeData theme, bool isStudy) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SETTINGS',
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        _buildSettingTile(
          Icons.notifications_none_rounded,
          'Reminders',
          'Get notified before session',
          Switch(value: true, onChanged: (v) {}),
        ),
        _buildSettingTile(
          Icons.sync_rounded,
          'Google Calendar',
          event.calendarEventId != null ? 'Synced' : 'Not synced',
          Icon(
            event.calendarEventId != null
                ? Icons.check_circle
                : Icons.error_outline,
            color: event.calendarEventId != null ? Colors.green : Colors.grey,
            size: 20,
          ),
        ),
        if (isStudy)
          _buildSettingTile(
            Icons.timer_outlined,
            'Auto Focus Mode',
            'Silence notifications during study',
            Switch(value: false, onChanged: (v) {}),
          ),
      ],
    );
  }

  Widget _buildSettingTile(
    IconData icon,
    String title,
    String subtitle,
    Widget trailing,
  ) {
    return ListBody(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 22, color: Colors.grey),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        if (event.type == 'study') ...[
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () =>
                  Navigator.pushNamed(context, '/focus-mode', arguments: event),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Start Focus Session'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () => _markAsCompleted(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Mark as Completed'),
            ),
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Intelligence Engine finding new slots...'),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('Reschedule Event'),
          ),
        ),
      ],
    );
  }

  String _getDay(int day) {
    switch (day) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return '';
    }
  }

  Future<void> _markAsCompleted(BuildContext context) async {
    final storageService = LocalStorageService();
    final now = DateTime.now();

    final session = StudySession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: event.title,
      linkedCourse: event.id,
      startTime: now.subtract(const Duration(hours: 1)), // Approximate
      endTime: now,
      focusModeEnabled: false,
      completed: true,
    );

    await storageService.addStudySession(session);
    await storageService.updateStreak();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Text('🔥 Streak Updated!'),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'View',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
        ),
      );
      Navigator.pop(context);
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text('Are you sure you want to delete "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final storageService = LocalStorageService();
              await storageService.deleteClassEvent(event.id);
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to dashboard
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
