import 'dart:async';
import 'package:flutter/material.dart';
import '../models/class_event.dart';
import '../models/study_session.dart';
import '../services/local_storage_service.dart';

class FocusModeScreen extends StatefulWidget {
  final ClassEvent event;

  const FocusModeScreen({super.key, required this.event});

  @override
  State<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends State<FocusModeScreen> {
  late Timer _timer;
  int _secondsRemaining = 0;
  int _totalDurationSeconds = 0;
  bool _isRunning = false;
  late DateTime _sessionStartTime;
  final LocalStorageService _storageService = LocalStorageService();

  @override
  void initState() {
    super.initState();
    _sessionStartTime = DateTime.now();
    _calculateInitialTime();
    _startTimer();
  }

  void _calculateInitialTime() {
    // Basic implementation: calculate duration between start and end time
    // For now, let's assume a default of 45 minutes if we can't parse easily
    // or just use a fixed duration for demonstration if needed.
    // However, let's try to parse HH:mm
    try {
      final startParts = widget.event.startTime.split(':');
      final endParts = widget.event.endTime.split(':');

      final startMinutes =
          int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

      int durationMinutes = endMinutes - startMinutes;
      if (durationMinutes <= 0) durationMinutes = 45; // Fallback

      _totalDurationSeconds = durationMinutes * 60;
      _secondsRemaining = _totalDurationSeconds;
    } catch (e) {
      _totalDurationSeconds = 45 * 60;
      _secondsRemaining = _totalDurationSeconds; // 45 minutes default
    }
  }

  void _startTimer() {
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer.cancel();
        setState(() {
          _isRunning = false;
        });
        _saveSession(true);
        _showSessionComplete();
      }
    });
  }

  void _pauseTimer() {
    _timer.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _stopTimer() {
    _timer.cancel();
    _showStopConfirmation();
  }

  Future<void> _saveSession(bool completed) async {
    final now = DateTime.now();
    final session = StudySession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: widget.event.title,
      linkedCourse: widget.event.id,
      startTime: _sessionStartTime,
      endTime: now,
      focusModeEnabled: true,
      completed: completed,
    );

    await _storageService.addStudySession(session);
  }

  void _showSessionComplete() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Session Complete!'),
        content: const Text('Great job staying focused.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back
            },
            child: const Text('Return'),
          ),
        ],
      ),
    );
  }

  void _showStopConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Session?'),
        content: const Text(
          'Are you sure you want to end this focus session early?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _saveSession(false);
              if (mounted) {
                Navigator.pop(context); // Go back
              }
            },
            child: const Text('End'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.event.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'FOCUS SESSION',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 64),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 280,
                    height: 280,
                    child: CircularProgressIndicator(
                      value: _totalDurationSeconds > 0
                          ? _secondsRemaining / _totalDurationSeconds
                          : 0,
                      strokeWidth: 12,
                      backgroundColor: theme.colorScheme.primary.withOpacity(
                        0.1,
                      ),
                    ),
                  ),
                  Text(
                    _formatTime(_secondsRemaining),
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontSize: 64,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 64),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildControlCircle(
                    icon: Icons.stop,
                    color: Colors.red.withOpacity(0.1),
                    iconColor: Colors.red,
                    onTap: _stopTimer,
                  ),
                  const SizedBox(width: 32),
                  _buildControlCircle(
                    icon: _isRunning ? Icons.pause : Icons.play_arrow,
                    color: theme.colorScheme.primary,
                    iconColor: Colors.white,
                    size: 80,
                    iconSize: 40,
                    onTap: _isRunning ? _pauseTimer : _startTimer,
                  ),
                  const SizedBox(width: 32),
                  _buildControlCircle(
                    icon: Icons.music_note,
                    color: theme.colorScheme.secondary.withOpacity(0.1),
                    iconColor: theme.colorScheme.secondary,
                    onTap: () {
                      // Future: Ambient sound selector
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlCircle({
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
    double size = 56,
    double iconSize = 24,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: iconSize),
      ),
    );
  }
}
