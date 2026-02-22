import 'package:flutter/material.dart';
import '../models/class_event.dart';
import '../models/course.dart';
import '../services/local_storage_service.dart';
import '../widgets/event_card.dart';

class TimetableExplorerScreen extends StatefulWidget {
  const TimetableExplorerScreen({super.key});

  @override
  State<TimetableExplorerScreen> createState() =>
      _TimetableExplorerScreenState();
}

class _TimetableExplorerScreenState extends State<TimetableExplorerScreen> {
  final _storageService = LocalStorageService();
  final _searchController = TextEditingController();

  List<ClassEvent> _allEvents = [];
  List<ClassEvent> _filteredEvents = [];
  List<Course> _courses = [];

  String? _selectedCourseId;
  String? _selectedDay;
  String? _selectedType;

  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() {
    setState(() {
      _allEvents = _storageService.getAllClassEvents();
      _courses = _storageService.getAllCourses();
      _filteredEvents = _allEvents;
    });
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredEvents = _allEvents.where((e) {
        final matchesQuery =
            e.title.toLowerCase().contains(query) ||
            e.venue.toLowerCase().contains(query);

        final matchesCourse =
            _selectedCourseId == null || e.courseId == _selectedCourseId;

        final matchesDay =
            _selectedDay == null || _getDayName(e.dayOfWeek) == _selectedDay;

        final matchesType = _selectedType == null || e.type == _selectedType;

        return matchesQuery && matchesCourse && matchesDay && matchesType;
      }).toList();

      // Sort by day and time
      _filteredEvents.sort((a, b) {
        if (a.dayOfWeek != b.dayOfWeek) {
          return a.dayOfWeek.compareTo(b.dayOfWeek);
        }
        return a.startTime.compareTo(b.startTime);
      });
    });
  }

  String _getDayName(int day) {
    return _days[day - 1];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Timetable Explorer'), elevation: 0),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by course or venue...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilters();
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip(
                  label: _selectedDay ?? 'All Days',
                  isActive: _selectedDay != null,
                  onTap: _showDayFilter,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: _selectedCourseId != null
                      ? _courses
                            .firstWhere((c) => c.id == _selectedCourseId)
                            .code
                      : 'All Courses',
                  isActive: _selectedCourseId != null,
                  onTap: _showCourseFilter,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: _selectedType != null
                      ? _selectedType!.toUpperCase()
                      : 'All Types',
                  isActive: _selectedType != null,
                  onTap: _showTypeFilter,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Results
          Expanded(
            child: _filteredEvents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No sessions match your search.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredEvents.length,
                    itemBuilder: (context, index) {
                      final event = _filteredEvents[index];
                      // Group by day header if it changes
                      bool showHeader =
                          index == 0 ||
                          _filteredEvents[index - 1].dayOfWeek !=
                              event.dayOfWeek;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showHeader) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                                horizontal: 4,
                              ),
                              child: Text(
                                _getDayName(event.dayOfWeek).toUpperCase(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ],
                          EventCard(event: event),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ActionChip(
      onPressed: onTap,
      label: Text(label),
      avatar: isActive
          ? const Icon(Icons.check, size: 16)
          : const Icon(Icons.arrow_drop_down, size: 16),
      backgroundColor: isActive ? theme.colorScheme.primaryContainer : null,
      labelStyle: TextStyle(
        color: isActive ? theme.colorScheme.onPrimaryContainer : null,
        fontWeight: isActive ? FontWeight.bold : null,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  void _showDayFilter() {
    _showOptions('Select Day', ['All Days', ..._days], (val) {
      setState(() => _selectedDay = val == 'All Days' ? null : val);
      _applyFilters();
    });
  }

  void _showCourseFilter() {
    final options = ['All Courses', ..._courses.map((c) => c.code)];
    _showOptions('Select Course', options, (val) {
      if (val == 'All Courses') {
        setState(() => _selectedCourseId = null);
      } else {
        final course = _courses.firstWhere((c) => c.code == val);
        setState(() => _selectedCourseId = course.id);
      }
      _applyFilters();
    });
  }

  void _showTypeFilter() {
    _showOptions('Select Type', ['All Types', 'class', 'study'], (val) {
      setState(() => _selectedType = val == 'All Types' ? null : val);
      _applyFilters();
    });
  }

  void _showOptions(
    String title,
    List<String> options,
    Function(String) onSelect,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: options.map(
                    (opt) => ListTile(
                      title: Text(opt.toUpperCase()),
                      onTap: () {
                        onSelect(opt);
                        Navigator.pop(context);
                      },
                    ),
                  ).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
