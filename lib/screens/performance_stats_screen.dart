import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';
import '../models/study_session.dart';

class PerformanceStatsScreen extends StatefulWidget {
  const PerformanceStatsScreen({super.key});

  @override
  State<PerformanceStatsScreen> createState() => _PerformanceStatsScreenState();
}

class _PerformanceStatsScreenState extends State<PerformanceStatsScreen> {
  final _storageService = LocalStorageService();

  @override
  Widget build(BuildContext context) {
    final productivity = _storageService.getUserProductivity();
    final sessions = _storageService.studyBox.values.toList();

    // Calculate total hours
    double totalHours = 0;
    for (var s in sessions) {
      if (s.completed) {
        totalHours += s.endTime.difference(s.startTime).inMinutes / 60.0;
      }
    }

    // Calculate Focus %
    double focusPercentage = 0;
    if (sessions.isNotEmpty) {
      final completedCount = sessions.where((s) => s.completed).length;
      focusPercentage = (completedCount / sessions.length) * 100;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Performance Dashboard')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildStatGrid(
              totalHours,
              focusPercentage,
              productivity.currentStreak,
            ),
            const SizedBox(height: 32),
            _buildChartsSection(),
            const SizedBox(height: 32),
            _buildRecentSessions(sessions),
          ],
        ),
      ),
    );
  }

  Widget _buildStatGrid(double hours, double focus, int streak) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.0,
      children: [
        _buildStatCard(
          'Study Hours',
          '${hours.toStringAsFixed(1)}h',
          Icons.timer,
          Colors.blue,
        ),
        _buildStatCard(
          'Focus Level',
          '${focus.toInt()}%',
          Icons.psychology,
          Colors.purple,
        ),
        _buildStatCard(
          'Current Streak',
          '${streak}d',
          Icons.fireplace,
          Colors.orange,
        ),
        _buildStatCard(
          'Coins Earned',
          '${_storageService.getUserProductivity().coins}',
          Icons.stars,
          Colors.amber,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Focus Pattern Analysis',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          // Simple visual placeholder for a chart
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildBar(0.4),
              _buildBar(0.7),
              _buildBar(0.9),
              _buildBar(0.5),
              _buildBar(0.8),
              _buildBar(0.3),
              _buildBar(0.6),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('M', style: TextStyle(color: Colors.grey, fontSize: 10)),
              Text('T', style: TextStyle(color: Colors.grey, fontSize: 10)),
              Text('W', style: TextStyle(color: Colors.grey, fontSize: 10)),
              Text('T', style: TextStyle(color: Colors.grey, fontSize: 10)),
              Text('F', style: TextStyle(color: Colors.grey, fontSize: 10)),
              Text('S', style: TextStyle(color: Colors.grey, fontSize: 10)),
              Text('S', style: TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBar(double height) {
    return Container(
      width: 12,
      height: 100 * height,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  Widget _buildRecentSessions(List<StudySession> sessions) {
    final recent = sessions.reversed.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Sessions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...recent.map(
          (s) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: s.completed
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              child: Icon(
                s.completed ? Icons.check : Icons.close,
                color: s.completed ? Colors.green : Colors.red,
                size: 16,
              ),
            ),
            title: Text(s.title),
            subtitle: Text(
              '${s.startTime.hour}:${s.startTime.minute.toString().padLeft(2, '0')} · ${s.endTime.difference(s.startTime).inMinutes} mins',
            ),
            trailing: Text(
              s.completed ? '+2 coins' : '0 coins',
              style: const TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
