import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';
import '../services/notification_service.dart';
import '../services/calendar_sync_service.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onThemeChanged;
  final VoidCallback onNameChanged;

  const SettingsScreen({
    super.key,
    required this.onThemeChanged,
    required this.onNameChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final LocalStorageService _storageService = LocalStorageService();
  late TextEditingController _nameController;
  late bool _notificationsEnabled;
  late ThemeMode _themeMode;

  late String _syncProvider;
  late int _reminderMinutes;
  late bool _contextMessagesEnabled;
  late bool _autoFocusEnabled;

  // Granular notification settings
  late bool _reminder15Min;
  late bool _reminder5Min;
  late bool _reminderWrapUp;
  late bool _streakReminder;
  late bool _dailyMotivation;
  late bool _notificationSound;
  late bool _alarmMode;

  @override
  void initState() {
    super.initState();
    _notificationsEnabled = _storageService.getNotificationsEnabled();
    _themeMode = _storageService.getThemeMode();
    _nameController = TextEditingController(
      text: _storageService.getUserName(),
    );
    _reminderMinutes = _storageService.getReminderMinutes();
    _contextMessagesEnabled = _storageService.getContextMessagesEnabled();
    _autoFocusEnabled = _storageService.getAutoFocusEnabled();
    _syncProvider = _storageService.getSyncProvider();

    _reminder15Min = _storageService.getReminderEnabled('reminder_15_min');
    _reminder5Min = _storageService.getReminderEnabled('reminder_5_min');
    _reminderWrapUp = _storageService.getReminderEnabled('reminder_wrap_up');
    _streakReminder = _storageService.getReminderEnabled('streak_reminder');
    _dailyMotivation = _storageService.getReminderEnabled('daily_motivation');
    _notificationSound = _storageService.getNotificationSoundEnabled();
    _alarmMode = _storageService.getAlarmModeEnabled();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _toggleNotifications(bool value) async {
    setState(() {
      _notificationsEnabled = value;
    });
    await _storageService.setNotificationsEnabled(value);
    await NotificationService().rescheduleAll();
  }

  void _setThemeMode(ThemeMode? mode) async {
    if (mode == null) return;
    setState(() {
      _themeMode = mode;
    });
    await _storageService.setThemeMode(mode);
    widget.onThemeChanged();
  }

  void _handleResetData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Data?'),
        content: const Text(
          'This will permanently delete all your classes and study sessions. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _storageService.clearAllData();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data has been cleared.')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _buildSectionHeader(context, 'Profile'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Your Name',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) async {
                await _storageService.setUserName(value);
                widget.onNameChanged();
              },
            ),
          ),
          const Divider(),
          _buildSectionHeader(context, 'Appearance'),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Theme Mode'),
            subtitle: Text(_getThemeName(_themeMode)),
            onTap: () => _showThemeSelector(),
          ),
          const Divider(),
          _buildSectionHeader(context, 'Notifications'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Class Reminders'),
            subtitle: const Text('Get notified before classes start'),
            value: _notificationsEnabled,
            onChanged: _toggleNotifications,
          ),
          if (_notificationsEnabled) ...[
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('15-Minute Reminder'),
                    subtitle: const Text('Alert before class starts'),
                    value: _reminder15Min,
                    onChanged: (v) async {
                      setState(() => _reminder15Min = v);
                      await _storageService.setReminderEnabled(
                        'reminder_15_min',
                        v,
                      );
                      await NotificationService().rescheduleAll();
                    },
                  ),
                  SwitchListTile(
                    title: const Text('5-Minute Reminder'),
                    subtitle: const Text('Final move alert'),
                    value: _reminder5Min,
                    onChanged: (v) async {
                      setState(() => _reminder5Min = v);
                      await _storageService.setReminderEnabled(
                        'reminder_5_min',
                        v,
                      );
                      await NotificationService().rescheduleAll();
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Wrap-Up Reminder'),
                    subtitle: const Text('Alert when class is ending'),
                    value: _reminderWrapUp,
                    onChanged: (v) async {
                      setState(() => _reminderWrapUp = v);
                      await _storageService.setReminderEnabled(
                        'reminder_wrap_up',
                        v,
                      );
                      await NotificationService().rescheduleAll();
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Daily Streak Warning'),
                    subtitle: const Text('Alert if streak is at risk'),
                    value: _streakReminder,
                    onChanged: (v) async {
                      setState(() => _streakReminder = v);
                      await _storageService.setReminderEnabled(
                        'streak_reminder',
                        v,
                      );
                      await NotificationService().rescheduleAll();
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Morning Motivation'),
                    subtitle: const Text('Start your day with discipline'),
                    value: _dailyMotivation,
                    onChanged: (v) async {
                      setState(() => _dailyMotivation = v);
                      await _storageService.setReminderEnabled(
                        'daily_motivation',
                        v,
                      );
                      await NotificationService().rescheduleAll();
                    },
                  ),
                  const Divider(indent: 16),
                  SwitchListTile(
                    secondary: const Icon(Icons.volume_up_outlined),
                    title: const Text('Notification Sound'),
                    subtitle: const Text('Play sound on alerts'),
                    value: _notificationSound,
                    onChanged: (v) async {
                      setState(() => _notificationSound = v);
                      await _storageService.setNotificationSoundEnabled(v);
                      await NotificationService().init(); // Update channel
                      await NotificationService().rescheduleAll();
                    },
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.alarm_on_outlined),
                    title: const Text('Alarm Mode'),
                    subtitle: const Text('High priority notifications'),
                    value: _alarmMode,
                    onChanged: (v) async {
                      setState(() => _alarmMode = v);
                      await _storageService.setAlarmModeEnabled(v);
                      await NotificationService().init(); // Update channel
                      await NotificationService().rescheduleAll();
                    },
                  ),
                ],
              ),
            ),
          ],
          const Divider(),
          _buildSectionHeader(context, 'Smart Buffer'),
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: const Text('Reminder Timing'),
            subtitle: Text('Notify me $_reminderMinutes minutes before'),
            trailing: DropdownButton<int>(
              value: _reminderMinutes,
              underline: const SizedBox(),
              items: [5, 10, 15]
                  .map((m) => DropdownMenuItem(value: m, child: Text('$m min')))
                  .toList(),
              onChanged: (v) async {
                if (v != null) {
                  setState(() => _reminderMinutes = v);
                  await _storageService.setReminderMinutes(v);
                  await NotificationService().rescheduleAll();
                }
              },
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.chat_bubble_outline),
            title: const Text('Context Messages'),
            subtitle: const Text('Show motivational nudges during study'),
            value: _contextMessagesEnabled,
            onChanged: (v) async {
              setState(() => _contextMessagesEnabled = v);
              await _storageService.setContextMessagesEnabled(v);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.vibration),
            title: const Text('Auto-Focus Mode'),
            subtitle: const Text(
              'Automatically enter Zen mode on session start',
            ),
            value: _autoFocusEnabled,
            onChanged: (v) async {
              setState(() => _autoFocusEnabled = v);
              await _storageService.setAutoFocusEnabled(v);
            },
          ),
          const Divider(),
          _buildSectionHeader(context, 'Academic'),
          ListTile(
            leading: const Icon(Icons.school_outlined),
            title: const Text('Academic Program'),
            subtitle: const Text('Institution, Program, Level'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(
              context,
              '/program-setup',
              arguments: false,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.book_outlined),
            title: const Text('Course Management'),
            subtitle: const Text('Manage courses and colors'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, '/course-management'),
          ),
          ListTile(
            leading: const Icon(Icons.explore_outlined),
            title: const Text('Timetable Explorer'),
            subtitle: const Text('Search and filter academic sessions'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, '/timetable-explorer'),
          ),
          const Divider(),
          _buildSectionHeader(context, 'Calendar Sync'),
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Sync Provider'),
            subtitle: Text(
              _syncProvider == 'off' ? 'Disabled' : _syncProvider.toUpperCase(),
            ),
            onTap: _showSyncSelector,
          ),
          if (_syncProvider != 'off') ...[
            ListTile(
              leading: const Icon(Icons.account_circle_outlined),
              title: const Text('Connected Account'),
              subtitle: Text(_storageService.getConnectedAccount()),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Last Sync'),
              subtitle: Text(_storageService.getLastSyncTime() ?? 'Never'),
              trailing: TextButton(
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Re-syncing all events...')),
                  );
                  final events = _storageService.getAllClassEvents();
                  for (final event in events) {
                    await CalendarSyncService().syncEvent(event);
                  }
                  await _storageService.setLastSyncTime(
                    DateTime.now().toString(),
                  );
                  setState(() {});
                },
                child: const Text('RESYNC ALL'),
              ),
            ),
          ],
          const Divider(),
          _buildSectionHeader(context, 'Data Management'),
          ListTile(
            leading: const Icon(Icons.file_upload_outlined),
            title: const Text('Export Timetable'),
            subtitle: const Text('Download your schedule as CSV'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Preparing export...')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: const Text('Cloud Backup'),
            subtitle: const Text('Save your data to the cloud'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Backup service coming soon.')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Reset Onboarding'),
            subtitle: const Text('Show tutorial on next launch'),
            onTap: () async {
              await _storageService.setOnboardingComplete(false);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Onboarding reset.')),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text(
              'Clear All Data',
              style: TextStyle(color: Colors.red),
            ),
            subtitle: const Text('Wipe everything from local storage'),
            onTap: _handleResetData,
          ),
          const Divider(),
          _buildSectionHeader(context, 'Security & Privacy'),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Privacy Policy'),
                  content: const SingleChildScrollView(
                    child: Text(
                      'Your data stays on your device. We do not collect or sell your personal information. Sync data is encrypted and sent directly to your provider.',
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('CLOSE'),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(),
          _buildSectionHeader(context, 'About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Class Timer Pro'),
            subtitle: Text('Version 1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Open Source Licenses'),
            onTap: () => showLicensePage(context: context),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  String _getThemeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      default:
        return 'System Default';
    }
  }

  void _showThemeSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('System Default'),
              value: ThemeMode.system,
              groupValue: _themeMode,
              onChanged: (mode) {
                _setThemeMode(mode);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              value: ThemeMode.light,
              groupValue: _themeMode,
              onChanged: (mode) {
                _setThemeMode(mode);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              value: ThemeMode.dark,
              groupValue: _themeMode,
              onChanged: (mode) {
                _setThemeMode(mode);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSyncSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Google Calendar'),
              leading: const Icon(Icons.calendar_today),
              onTap: () async {
                setState(() => _syncProvider = 'google');
                await _storageService.setSyncProvider('google');
                await _storageService.setConnectedAccount('Google Calendar');

                // Initial Sync
                final events = _storageService.getAllClassEvents();
                for (final event in events) {
                  await CalendarSyncService().syncEvent(event);
                }
                await _storageService.setLastSyncTime(
                  DateTime.now().toString().split('.')[0],
                );
                if (mounted) Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Device Calendar'),
              leading: const Icon(Icons.perm_contact_calendar_outlined),
              onTap: () async {
                setState(() => _syncProvider = 'device');
                await _storageService.setSyncProvider('device');
                await _storageService.setConnectedAccount('Device Calendar');

                // Initial Sync
                final events = _storageService.getAllClassEvents();
                for (final event in events) {
                  await CalendarSyncService().syncEvent(event);
                }
                await _storageService.setLastSyncTime(
                  DateTime.now().toString().split('.')[0],
                );
                if (mounted) Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Turn Off Sync'),
              leading: const Icon(Icons.sync_disabled),
              onTap: () async {
                setState(() => _syncProvider = 'off');
                await _storageService.setSyncProvider('off');
                if (mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
