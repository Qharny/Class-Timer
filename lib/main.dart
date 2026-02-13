import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'theme/app_theme.dart';
import 'widgets/event_card.dart';

import 'services/local_storage_service.dart';
import 'screens/onboarding_screen.dart';
import 'models/class_event.dart';
import 'screens/import_screen.dart';
import 'theme/page_transitions.dart';
import 'screens/focus_mode_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/event_detail_screen.dart';
import 'screens/edit_event_screen.dart';

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
              case '/edit-event':
                final event = settings.arguments as ClassEvent?;
                return RouteTransitions.slideBottom(
                  page: EditEventScreen(event: event),
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
  late Stream<DateTime> _timerStream;

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _timerStream = Stream.periodic(
      const Duration(seconds: 1),
      (_) => DateTime.now(),
    );
  }

  void _loadEvents() {
    setState(() {
      _events = _storageService.getAllClassEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final upcomingEvents = _getUpcomingEvents(3);
    final todayEvents = _getTodayEvents();
    final userName = _storageService.getUserName();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () async {
              await Navigator.pushNamed(context, '/settings');
              _loadEvents();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section: Greeting & Date
            _buildHeader(userName),
            const SizedBox(height: 32),

            // Middle Section: Up Next
            _buildSectionTitle('🔔 UP NEXT'),
            const SizedBox(height: 12),
            if (_events.isEmpty)
              _buildEmptyState(
                'Add your timetable to get started.',
                icon: Icons.calendar_today_outlined,
                actionLabel: 'Import Now',
                onAction: () async {
                  await Navigator.pushNamed(context, '/import');
                  _loadEvents();
                },
              )
            else if (upcomingEvents.isNotEmpty)
              ...upcomingEvents.asMap().entries.map((entry) {
                final isFirst = entry.key == 0;
                return _buildUpNextCard(context, entry.value, isFirst);
              })
            else
              _buildEmptyState('Nothing scheduled. Take a break.'),

            const SizedBox(height: 32),

            // Bottom Section: Today's Schedule
            _buildSectionTitle('📅 TODAY\'S SCHEDULE'),
            const SizedBox(height: 12),
            if (_events.isNotEmpty)
              if (todayEvents.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: todayEvents.length,
                  itemBuilder: (context, index) {
                    return EventCard(event: todayEvents[index]);
                  },
                )
              else
                _buildEmptyState('Nothing scheduled for today.')
            else
              const SizedBox.shrink(),

            const SizedBox(height: 100), // Spacing for FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.pushNamed(context, '/import');
          _loadEvents();
        },
        label: const Text('Add Timetable'),
        icon: const Icon(Icons.add_rounded),
        elevation: 2,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildHeader(String name) {
    final now = DateTime.now();
    final hour = now.hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    final dateStr = DateFormat('EEEE, MMMM d').format(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.grey[600],
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          name,
          style: Theme.of(
            context,
          ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          dateStr,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
        color: Colors.grey[600],
      ),
    );
  }

  Widget _buildUpNextCard(
    BuildContext context,
    ClassEvent event,
    bool isFirst,
  ) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isFirst
            ? theme.colorScheme.primary.withOpacity(0.05)
            : theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFirst
              ? theme.colorScheme.primary.withOpacity(0.2)
              : theme.dividerColor.withOpacity(0.1),
        ),
      ),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailScreen(event: event),
            ),
          );
          _loadEvents();
        },
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildMiniBadge(
                        event.type.toUpperCase(),
                        theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          event.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${event.startTime} - ${event.endTime}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            if (isFirst)
              StreamBuilder<DateTime>(
                stream: _timerStream,
                builder: (context, snapshot) {
                  return _buildCountdown(event.startTime);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdown(String startTime) {
    final now = DateTime.now();
    final parts = startTime.split(':');
    final start = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );

    final diff = start.difference(now);
    if (diff.isNegative) return const SizedBox.shrink();

    final minutes = diff.inMinutes;
    final seconds = diff.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${minutes}m ${seconds}s',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          fontFamily: 'Courier',
        ),
      ),
    );
  }

  Widget _buildMiniBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    String message, {
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 48,
              color: theme.colorScheme.primary.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.hintColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: Text(actionLabel),
            ),
          ],
        ],
      ),
    );
  }

  List<ClassEvent> _getUpcomingEvents(int count) {
    final now = DateTime.now();
    final currentDay = now.weekday;
    final todayEvents = _events.where((e) {
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

    todayEvents.sort((a, b) => a.startTime.compareTo(b.startTime));
    return todayEvents.take(count).toList();
  }

  List<ClassEvent> _getTodayEvents() {
    final currentDay = DateTime.now().weekday;
    final todayEvents = _events
        .where((e) => e.dayOfWeek == currentDay)
        .toList();
    todayEvents.sort((a, b) => a.startTime.compareTo(b.startTime));
    return todayEvents;
  }
}
