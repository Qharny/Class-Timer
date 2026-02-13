import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'theme/app_theme.dart';

import 'services/local_storage_service.dart';
import 'screens/onboarding_screen.dart';
import 'models/class_event.dart';
import 'screens/import_screen.dart';
import 'theme/page_transitions.dart';
import 'screens/focus_mode_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/event_detail_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Initialize Local Storage
  final storageService = LocalStorageService();
  await storageService.init();

  final bool onboardingComplete = storageService.isOnboardingComplete();
  final themeMode = storageService.getThemeMode();

  runApp(
    ClassTimerPro(
      initialRoute: onboardingComplete ? '/dashboard' : '/',
      initialThemeMode: themeMode,
    ),
  );
}

class ClassTimerPro extends StatefulWidget {
  final String initialRoute;
  final ThemeMode initialThemeMode;
  const ClassTimerPro({
    super.key,
    required this.initialRoute,
    required this.initialThemeMode,
  });

  @override
  State<ClassTimerPro> createState() => _ClassTimerProState();
}

class _ClassTimerProState extends State<ClassTimerPro> {
  late ValueNotifier<ThemeMode> _themeNotifier;

  @override
  void initState() {
    super.initState();
    _themeNotifier = ValueNotifier(widget.initialThemeMode);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          title: 'Class Timer Pro',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode,
          initialRoute: widget.initialRoute,
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
              case '/settings':
                return RouteTransitions.slideBottom(
                  page: SettingsScreen(
                    onThemeChanged: () {
                      _themeNotifier.value = LocalStorageService()
                          .getThemeMode();
                    },
                    onNameChanged: () {
                      setState(() {}); // Refresh dashboard greeting
                    },
                  ),
                  settings: settings,
                );
              default:
                return null;
            }
          },
        );
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
    final upcomingEvent = _getUpNextEvent();
    final todayEvents = _getTodayEvents();
    final userName = _storageService.getUserName();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.pushNamed(context, '/settings');
              _loadEvents();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome back,', style: theme.textTheme.bodyLarge),
            Text('$userName!', style: theme.textTheme.displayLarge),
            const SizedBox(height: 30),

            // Up Next Section
            _buildSectionHeader(context, 'UP NEXT'),
            const SizedBox(height: 12),
            if (upcomingEvent != null)
              _buildUpcomingCard(context, upcomingEvent)
            else
              _buildEmptyUpcomingCard(context),

            const SizedBox(height: 32),

            // Today's Schedule
            _buildSectionHeader(context, 'TODAY\'S SCHEDULE'),
            const SizedBox(height: 12),
            if (todayEvents.isNotEmpty)
              SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: todayEvents.length,
                  itemBuilder: (context, index) =>
                      _buildScheduleCard(context, todayEvents[index]),
                ),
              )
            else
              _buildEmptyScheduleCard(context),

            const SizedBox(height: 32),

            // Quick Stats
            _buildSectionHeader(context, 'QUICK STATS'),
            const SizedBox(height: 12),
            _buildActionGrid(context, todayEvents.length),
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

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
        color: Colors.grey,
      ),
    );
  }

  ClassEvent? _getUpNextEvent() {
    if (_events.isEmpty) return null;

    final now = DateTime.now();
    final currentDay = now.weekday; // 1-7 (Mon-Sun)

    // Filter events for today and after current time
    List<ClassEvent> potentialNext = _events.where((e) {
      if (e.dayOfWeek != currentDay) return false;

      final parts = e.startTime.split(':');
      final eventTime = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      return eventTime.isAfter(now);
    }).toList();

    if (potentialNext.isEmpty) {
      // Look for next day? For now, just return null if nothing today
      return null;
    }

    potentialNext.sort((a, b) => a.startTime.compareTo(b.startTime));
    return potentialNext.first;
  }

  List<ClassEvent> _getTodayEvents() {
    final currentDay = DateTime.now().weekday;
    final todayEvents = _events
        .where((e) => e.dayOfWeek == currentDay)
        .toList();
    todayEvents.sort((a, b) => a.startTime.compareTo(b.startTime));
    return todayEvents;
  }

  Widget _buildEmptyUpcomingCard(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(
          child: Text(
            'No more classes for today!',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyScheduleCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        'Nothing scheduled for today.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget _buildUpcomingCard(BuildContext context, ClassEvent event) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailScreen(event: event),
          ),
        );
        _loadEvents();
      },
      borderRadius: BorderRadius.circular(20),
      child: Card(
        elevation: 8,
        shadowColor: theme.colorScheme.primary.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withRed(100),
              ],
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${event.startTime} - ${event.endTime}',
                      style: TextStyle(color: Colors.white.withOpacity(0.8)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          event.venue,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleCard(BuildContext context, ClassEvent event) {
    final theme = Theme.of(context);
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.startTime,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            event.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Text(
            event.venue,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context, int todayCount) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildStatCard(
          context,
          'Today\'s Classes',
          '$todayCount',
          Icons.calendar_view_day,
          Colors.orange,
        ),
        _buildStatCard(
          context,
          'Total Classes',
          '${_events.length}',
          Icons.book,
          Colors.teal,
        ),
        _buildStatCard(context, 'Focus Time', '0h', Icons.timer, Colors.blue),
        _buildStatCard(
          context,
          'Productivity',
          'High',
          Icons.insights,
          Colors.purple,
        ),
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
      elevation: 0,
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 10, color: color.withOpacity(0.8)),
              textAlign: TextAlign.start,
            ),
          ],
        ),
      ),
    );
  }
}
