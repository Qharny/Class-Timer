import 'dart:async';
import 'package:flutter/material.dart';
import '../models/class_event.dart';
import '../models/study_session.dart';
import '../services/local_storage_service.dart';
import '../services/focus_mode_service.dart';

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
    if (_storageService.getAutoFocusEnabled()) {
      _startTimer();
    }
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
    if (completed) {
      await _storageService.updateStreak();
    }
  }

  void _showSessionComplete() {
    final stats = _storageService.getUserProductivity();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Session Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Great job staying focused.'),
            if (stats.currentStreak > 0) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Text(
                      '${stats.currentStreak} Day Streak!',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, true); // Go back with success
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
    final focusService = FocusModeService();

    return Scaffold(
      backgroundColor: Colors.black, // Immersive dark background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
          child: Column(
            children: [
              // Top: Subject Title
              Text(
                widget.event.title.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),

              // Middle: Countdown Timer
              Column(
                children: [
                  Text(
                    _formatTime(_secondsRemaining),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 84,
                      fontWeight: FontWeight.w200,
                      fontFamily: 'Courier', // Monospace for stability
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Motivational Micro-text
                  if (_storageService.getContextMessagesEnabled())
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child: Text(
                        focusService.getRandomPhrase(),
                        key: ValueKey(
                          _secondsRemaining ~/ 10,
                        ), // Change every 10s
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                ],
              ),

              const Spacer(),

              // Bottom: Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildMinimalButton(
                    onTap: () => _isRunning ? _pauseTimer() : _startTimer(),
                    icon: _isRunning ? Icons.pause : Icons.play_arrow,
                    label: _isRunning ? 'PAUSE' : 'RESUME',
                  ),
                  const SizedBox(width: 48),
                  _buildMinimalButton(
                    onTap: _stopTimer,
                    icon: Icons.close,
                    label: 'END SESSION',
                    isDestructive: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalButton({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(
            icon,
            color: isDestructive
                ? Colors.redAccent.withOpacity(0.8)
                : Colors.white60,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isDestructive
                  ? Colors.redAccent.withOpacity(0.8)
                  : Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
