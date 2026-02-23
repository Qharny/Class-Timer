import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'theme/app_theme.dart';
import 'widgets/event_card.dart';
import 'services/local_storage_service.dart';
import 'services/notification_service.dart';
import 'services/location_service.dart';
import 'screens/onboarding_screen.dart';
import 'models/class_event.dart';
import 'screens/import_screen.dart';
import 'theme/page_transitions.dart';
import 'screens/focus_mode_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/event_detail_screen.dart';
import 'screens/edit_event_screen.dart';
import 'screens/program_setup_screen.dart';
import 'screens/course_management_screen.dart';
import 'screens/timetable_explorer_screen.dart';
import 'screens/grade_calculator_screen.dart';
import 'screens/absence_tracker_screen.dart';
import 'screens/study_planner_screen.dart';
import 'screens/performance_stats_screen.dart';
import 'models/user_productivity.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Initialize Local Storage
  final storageService = LocalStorageService();
  await storageService.init();

  // Initialize Notifications
  final notificationService = NotificationService();
  await notificationService.init();

  // Don't await permission request or rescheduling in main to avoid blocking startup
  unawaited(notificationService.requestPermissions());
  unawaited(notificationService.rescheduleAll());

  final bool onboardingComplete = storageService.isOnboardingComplete();
  final program = storageService.getProgram();
  final themeMode = storageService.getThemeMode();

  String initialRoute = '/';
  if (onboardingComplete) {
    initialRoute = (program == null) ? '/program-setup' : '/dashboard';
  }

  runApp(
    ClassTimerPro(initialRoute: initialRoute, initialThemeMode: themeMode),
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

    // Start periodic GPS check for Late Trigger
    Timer.periodic(const Duration(minutes: 10), (timer) {
      unawaited(LocationService().checkProximityToCampus());
    });

    // Immediate check on start (non-blocking)
    unawaited(LocationService().checkProximityToCampus());
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
              case '/program-setup':
                final isInitial = settings.arguments as bool? ?? true;
                return RouteTransitions.fade(
                  page: ProgramSetupScreen(isInitialSetup: isInitial),
                  settings: settings,
                );
              case '/course-management':
                return RouteTransitions.slideRight(
                  page: const CourseManagementScreen(),
                  settings: settings,
                );
              case '/timetable-explorer':
                return RouteTransitions.slideRight(
                  page: const TimetableExplorerScreen(),
                  settings: settings,
                );
              case '/grade-calculator':
                return RouteTransitions.slideRight(
                  page: const GradeCalculatorScreen(),
                  settings: settings,
                );
              case '/study-planner':
                return RouteTransitions.slideRight(
                  page: const StudyPlannerScreen(),
                  settings: settings,
                );
              case '/performance-stats':
                return RouteTransitions.slideRight(
                  page: const PerformanceStatsScreen(),
                  settings: settings,
                );
              case '/absence-tracker':
                return RouteTransitions.slideRight(
                  page: const AbsenceTrackerScreen(),
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

  UserProductivity _getStats() {
    return _storageService.getUserProductivity();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final upcomingEvents = _getUpcomingEvents(3);
    final todayEvents = _getTodayEvents();
    final completedEvents = _getCompletedEvents(todayEvents);
    final userName = _storageService.getUserName();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
            tooltip: 'Menu',
          ),
        ),
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
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.8),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Class Timer Pro',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Level: Scholar',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.stars, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${LocalStorageService().getUserProductivity().coins} Coins',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.fireplace,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${LocalStorageService().getUserProductivity().currentStreak}d Streak',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Dashboard'),
              onTap: () => Navigator.pop(context),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.only(left: 16, top: 8, bottom: 4),
              child: Text(
                'ACADEMIC TOOLS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.calculate_outlined),
              title: const Text('Grade Predictor'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/grade-calculator');
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_stories_outlined),
              title: const Text('Study Planner'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/study-planner');
              },
            ),
            ListTile(
              leading: const Icon(Icons.event_busy_outlined),
              title: const Text('Absence Tracker'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/absence-tracker');
              },
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.only(left: 16, top: 8, bottom: 4),
              child: Text(
                'ANALYTICS & INTELLIGENCE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart_outlined),
              title: const Text('Performance Stats'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/performance-stats');
              },
            ),
            ListTile(
              leading: Icon(
                Icons.crisis_alert_outlined,
                color: LocalStorageService().isCrisisMode() ? Colors.red : null,
              ),
              title: const Text('Crisis Mode (Exam Week)'),
              trailing: Switch(
                value: LocalStorageService().isCrisisMode(),
                activeColor: Colors.red,
                onChanged: (v) async {
                  await LocalStorageService().setCrisisMode(v);
                  setState(() {});
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings');
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section: Greeting & Date & Streak
            _buildHeader(userName, _getStats()),
            const SizedBox(height: 24),

            // Progress Section
            _buildProgressCard(todayEvents.length, completedEvents.length),
            const SizedBox(height: 32),

            // Quick Actions Section
            _buildSectionTitle('⚡ QUICK ACTIONS'),
            const SizedBox(height: 12),
            _buildQuickActions(),
            const SizedBox(height: 32),

            // Streak Milestones Section
            if (_getStats().currentStreak > 0) ...[
              _buildSectionTitle('🏆 STREAK MILESTONES'),
              const SizedBox(height: 12),
              _buildMilestones(_getStats()),
              const SizedBox(height: 32),
            ],

            // Analytics Section
            _buildSectionTitle('📊 PRODUCTIVITY ANALYTICS'),
            const SizedBox(height: 12),
            _buildAnalyticsCard(_getStats()),
            const SizedBox(height: 16),
            _buildFreezeCard(_getStats()),
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

  Widget _buildProgressCard(int total, int completed) {
    final theme = Theme.of(context);
    final double progress = total > 0 ? completed / total : 0.0;
    final percent = (progress * 100).toInt();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Progress',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$completed / $total Classes Done',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$percent%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _getMotivationMessage(progress),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  String _getMotivationMessage(double progress) {
    if (progress == 0) return "Ready to start your day? You've got this!";
    if (progress < 0.5) return "Good start! Keep the momentum going.";
    if (progress < 1.0) return "Almost there! Just a few more to go.";
    return "Amazing! Daily schedule completed. Rest well!";
  }

  Widget _buildQuickActions() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildActionItem(Icons.add_task_rounded, 'Add Class', () async {
          await Navigator.pushNamed(context, '/edit-event');
          _loadEvents();
        }),
        _buildActionItem(
          Icons.explore_outlined,
          'Explorer',
          () => Navigator.pushNamed(context, '/timetable-explorer'),
        ),
        _buildActionItem(
          Icons.auto_stories_outlined,
          'Courses',
          () => Navigator.pushNamed(context, '/course-management'),
        ),
        _buildActionItem(Icons.timer_outlined, 'Focus', () {
          final upcoming = _getUpcomingEvents(1);
          if (upcoming.isNotEmpty) {
            Navigator.pushNamed(
              context,
              '/focus-mode',
              arguments: upcoming.first,
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No upcoming classes to focus on')),
            );
          }
        }),
      ],
    );
  }

  Widget _buildActionItem(IconData icon, String label, VoidCallback onTap) {
    final theme = Theme.of(context);
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildHeader(String name, UserProductivity stats) {
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

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
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
        ),
        if (stats.currentStreak > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  '${stats.currentStreak}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                if (stats.streakFreezes > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.ac_unit, size: 12, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          '${stats.streakFreezes}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMilestones(UserProductivity stats) {
    final theme = Theme.of(context);
    final streak = stats.currentStreak;

    final milestones = [
      {
        'days': 3,
        'label': 'Getting Started',
        'icon': Icons.star_border_rounded,
      },
      {
        'days': 7,
        'label': 'Consistency Builder',
        'icon': Icons.trending_up_rounded,
      },
      {
        'days': 30,
        'label': 'Academic Machine',
        'icon': Icons.precision_manufacturing_rounded,
      },
      {'days': 100, 'label': 'Unstoppable', 'icon': Icons.auto_awesome_rounded},
    ];

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: milestones.length,
        itemBuilder: (context, index) {
          final m = milestones[index];
          final days = m['days'] as int;
          final isUnlocked = streak >= days;

          return Container(
            width: 140,
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUnlocked
                  ? theme.colorScheme.primary.withOpacity(0.1)
                  : theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isUnlocked
                    ? theme.colorScheme.primary.withOpacity(0.3)
                    : theme.dividerColor.withOpacity(0.1),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  m['icon'] as IconData,
                  color: isUnlocked ? theme.colorScheme.primary : Colors.grey,
                  size: 24,
                ),
                const SizedBox(height: 8),
                Text(
                  m['label'] as String,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: isUnlocked
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isUnlocked
                        ? theme.colorScheme.primary
                        : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$days Days',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: isUnlocked ? theme.colorScheme.primary : Colors.grey,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnalyticsCard(UserProductivity stats) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildAnalyticItem(
            'Longest Streak',
            '${stats.longestStreak}',
            Icons.emoji_events_outlined,
            Colors.amber,
          ),
          Container(
            width: 1,
            height: 40,
            color: theme.dividerColor.withOpacity(0.1),
          ),
          _buildAnalyticItem(
            'Total Sessions',
            '${stats.totalCompletedSessions}',
            Icons.check_circle_outline_rounded,
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildFreezeCard(UserProductivity stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.ac_unit, color: Colors.blue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Streak Freeze',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Protects your streak if you miss a day.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _handleBuyFreeze(),
            child: const Text('Get Free'),
          ),
        ],
      ),
    );
  }

  void _handleBuyFreeze() async {
    await _storageService.buyStreakFreeze();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❄️ Streak Freeze acquired!'),
          backgroundColor: Colors.blue,
        ),
      );
      setState(() {});
    }
  }

  Widget _buildAnalyticItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey),
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

  List<ClassEvent> _getCompletedEvents(List<ClassEvent> todayEvents) {
    final now = DateTime.now();
    return todayEvents.where((e) {
      final parts = e.endTime.split(':');
      final eventEndTime = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      return now.isAfter(eventEndTime);
    }).toList();
  }
}

class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '$title coming soon...',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
