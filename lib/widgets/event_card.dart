import 'package:flutter/material.dart';
import '../models/class_event.dart';

class EventCard extends StatelessWidget {
  final ClassEvent event;

  const EventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          event.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${_getDay(event.dayOfWeek)} • ${event.startTime} - ${event.endTime}',
        ),
        trailing: Text(event.venue),
      ),
    );
  }

  String _getDay(int day) {
    switch (day) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }
}
