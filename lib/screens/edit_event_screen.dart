import 'package:class_timer/models/course.dart';
import 'package:flutter/material.dart';
import '../models/class_event.dart';
import '../services/local_storage_service.dart';

class EditEventScreen extends StatefulWidget {
  final ClassEvent? event;

  const EditEventScreen({super.key, this.event});

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storageService = LocalStorageService();

  late TextEditingController _titleController;
  late TextEditingController _venueController;
  late String _type;
  late int _dayOfWeek;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  bool _remindersEnabled = true;
  String? _selectedCourseId;
  List<Course> _courses = [];

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    _titleController = TextEditingController(text: e?.title ?? '');
    _venueController = TextEditingController(text: e?.venue ?? '');
    _type = e?.type ?? 'class';
    _dayOfWeek = e?.dayOfWeek ?? DateTime.now().weekday;

    _courses = _storageService.getAllCourses();
    _selectedCourseId = e?.courseId;

    if (e != null) {
      _startTime = _parseTimeOfDay(e.startTime);
      _endTime = _parseTimeOfDay(e.endTime);
    } else {
      _startTime = const TimeOfDay(hour: 8, minute: 0);
      _endTime = const TimeOfDay(hour: 9, minute: 0);
    }
  }

  TimeOfDay _parseTimeOfDay(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final hour = tod.hour.toString().padLeft(2, '0');
    final minute = tod.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool isStart) async {
    final initial = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
          // Auto-adjust end time if it's before start
          if (_endTime.hour < picked.hour ||
              (_endTime.hour == picked.hour &&
                  _endTime.minute < picked.minute)) {
            _endTime = TimeOfDay(
              hour: (picked.hour + 1) % 24,
              minute: picked.minute,
            );
          }
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final newEvent = ClassEvent(
        id:
            widget.event?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        type: _type,
        dayOfWeek: _dayOfWeek,
        startTime: _formatTimeOfDay(_startTime),
        endTime: _formatTimeOfDay(_endTime),
        venue: _venueController.text,
        courseId: _selectedCourseId,
      );

      await _storageService.addClassEvent(newEvent);
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event == null ? 'Add Event' : 'Edit Event'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'SAVE',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Event Title',
                hintText: 'e.g. Advanced Mathematics',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(
                labelText: 'Event Type',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'class',
                  child: Row(
                    children: [
                      Icon(Icons.school_outlined, size: 20),
                      SizedBox(width: 8),
                      Text('Class'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'study',
                  child: Row(
                    children: [
                      Icon(Icons.menu_book_outlined, size: 20),
                      SizedBox(width: 8),
                      Text('Study Session'),
                    ],
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _selectedCourseId,
              decoration: const InputDecoration(
                labelText: 'Link to Course (Optional)',
                prefixIcon: Icon(Icons.book_outlined),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('No Course (General)'),
                ),
                ..._courses.map(
                  (c) => DropdownMenuItem(
                    value: c.id,
                    child: Text('${c.code}: ${c.name}'),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _selectedCourseId = v),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<int>(
              value: _dayOfWeek,
              decoration: const InputDecoration(
                labelText: 'Day',
                prefixIcon: Icon(Icons.calendar_today_outlined),
              ),
              items: List.generate(7, (i) => i + 1).map((d) {
                return DropdownMenuItem(value: d, child: Text(_getDayName(d)));
              }).toList(),
              onChanged: (v) => setState(() => _dayOfWeek = v!),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _pickTime(true),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Start Time',
                        prefixIcon: Icon(Icons.access_time),
                      ),
                      child: Text(_formatTimeOfDay(_startTime)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickTime(false),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'End Time',
                        prefixIcon: Icon(Icons.access_time_filled),
                      ),
                      child: Text(_formatTimeOfDay(_endTime)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _venueController,
              decoration: const InputDecoration(
                labelText: 'Venue (Optional)',
                hintText: 'e.g. Room 402, Block B',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 32),
            SwitchListTile(
              title: const Text('Reminders'),
              subtitle: const Text('Notify me 15 mins before'),
              value: _remindersEnabled,
              secondary: const Icon(Icons.notifications_active_outlined),
              onChanged: (v) => setState(() => _remindersEnabled = v),
            ),
            const SizedBox(height: 48),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Save Event',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDayName(int day) {
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
}
