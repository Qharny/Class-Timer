import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'theme/app_theme.dart';

import 'services/local_storage_service.dart';
import 'screens/onboarding_screen.dart';
import 'models/class_event.dart';
import 'screens/import_screen.dart';
import 'theme/page_transitions.dart';
import 'screens/focus_mode_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Initialize Local Storage
  final storageService = LocalStorageService();
  await storageService.init();

  final bool onboardingComplete = storageService.isOnboardingComplete();

  runApp(ClassTimerPro(initialRoute: onboardingComplete ? '/dashboard' : '/'));
}

class ClassTimerPro extends StatelessWidget {
  final String initialRoute;
  const ClassTimerPro({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Class Timer Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: initialRoute,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return RouteTransitions.fade(
              page: const OnboardingScreen(),
              settings: settings,
            );
          case '/dashboard':
            return RouteTransitions.fade(
              page: const DashboardScreen(),
              settings: settings,
            );
          case '/import':
            return RouteTransitions.slideBottom(
              page: const ImportScreen(),
              settings: settings,
            );
          case '/focus-mode':
            final event = settings.arguments as ClassEvent;
            return RouteTransitions.scale(
              page: FocusModeScreen(event: event),
              settings: settings,
            );
          default:
            return null;
        }
      },
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final LocalStorageService _storageService = LocalStorageService();
  List<ClassEvent> _events = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() {
    setState(() {
      _events = _storageService.getAllClassEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final upcomingEvent = _getUpcomingEvent();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome back,', style: theme.textTheme.bodyLarge),
            Text('Scholar!', style: theme.textTheme.displayLarge),
            const SizedBox(height: 30),
            if (upcomingEvent != null)
              _buildUpcomingCard(context, upcomingEvent)
            else
              _buildEmptyState(context),
            const SizedBox(height: 20),
            _buildActionGrid(context),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.pushNamed(context, '/import');
          _loadEvents();
        },
        label: const Text('Add Timetable'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  ClassEvent? _getUpcomingEvent() {
    if (_events.isEmpty) return null;
    // Simple logic: get the first one for now (can be improved with current time)
    return _events.first;
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 40,
              color: Colors.grey,
            ),
            const SizedBox(height: 10),
            const Text('No classes imported yet.', textAlign: TextAlign.center),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/import'),
              child: const Text('Import Now'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingCard(BuildContext context, ClassEvent event) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: const Text('Up Next'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              event.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(event.startTime),
            Text(event.venue),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Ready',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard(
          context,
          'Total Classes',
          '${_events.length}',
          Icons.book,
          Colors.teal,
        ),
        _buildStatCard(context, 'Focus Time', '0h', Icons.timer, Colors.blue),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
