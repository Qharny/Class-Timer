import 'package:flutter/material.dart';
import '../models/class_event.dart';
import '../models/course.dart';
import '../services/local_storage_service.dart';

class EventCard extends StatelessWidget {
  final ClassEvent event;

  const EventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = _getEventStatus();
    final progress = _calculateProgress();
    final course = event.courseId != null
        ? LocalStorageService().getCourse(event.courseId!)
        : null;
    final courseColor = course != null
        ? Color(int.parse(course.colorTag.replaceFirst('#', '0xFF')))
        : theme.colorScheme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: () =>
            Navigator.pushNamed(context, '/event-detail', arguments: event),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (course != null)
                          Text(
                            '${course.code} • ${course.name}'.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: courseColor,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                        Text(
                          event.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(context, status, courseColor),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: theme.hintColor),
                  const SizedBox(width: 4),
                  Text(
                    '${event.startTime} - ${event.endTime}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  if (event.venue.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: theme.hintColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      event.venue,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ],
              ),
              if (status == EventStatus.ongoing && progress != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    minHeight: 4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(
    BuildContext context,
    EventStatus status,
    Color baseColor,
  ) {
    Color color;
    String label;

    switch (status) {
      case EventStatus.upcoming:
        color = baseColor;
        label = 'Upcoming';
        break;
      case EventStatus.ongoing:
        color = Colors.orange;
        label = 'Ongoing';
        break;
      case EventStatus.completed:
        color = Colors.green;
        label = 'Completed';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  EventStatus _getEventStatus() {
    final now = DateTime.now();
    final start = _parseTime(event.startTime);
    final end = _parseTime(event.endTime);

    if (now.isBefore(start)) return EventStatus.upcoming;
    if (now.isAfter(end)) return EventStatus.completed;
    return EventStatus.ongoing;
  }

  double? _calculateProgress() {
    final now = DateTime.now();
    final start = _parseTime(event.startTime);
    final end = _parseTime(event.endTime);

    if (now.isBefore(start) || now.isAfter(end)) return null;

    final total = end.difference(start).inSeconds;
    final elapsed = now.difference(start).inSeconds;
    return elapsed / total;
  }

  DateTime _parseTime(String timeStr) {
    final now = DateTime.now();
    final parts = timeStr.split(':');
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }
}

enum EventStatus { upcoming, ongoing, completed }
