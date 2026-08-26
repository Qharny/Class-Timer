import 'package:flutter/material.dart';
import '../models/class_event.dart';
import '../services/import_service.dart';
import '../models/domain_models.dart';
import '../services/conflict_engine.dart';
import './conflict_resolution_screen.dart';
import '../services/local_storage_service.dart';
import '../widgets/processing_indicator.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final ImportService _importService = ImportService();
  final LocalStorageService _storageService = LocalStorageService();
  List<ClassEvent>? _previewEvents;
  bool _isLoading = false;
  List<String> _loadingMessages = _parsingMessages;

  static const _parsingMessages = [
    'Reading your file...',
    'Detecting the timetable grid...',
    'Recognizing classes and times...',
    'Cleaning up the details...',
    'Almost there...',
  ];

  static const _scanningMessages = [
    'Scanning your image...',
    'Finding text on the page...',
    'Matching days and time slots...',
    'Building your class list...',
    'Almost there...',
  ];

  static const _syncingMessages = [
    'Checking for schedule conflicts...',
    'Saving your classes...',
    'Setting up reminders...',
    'Syncing your timetable...',
  ];

  Future<void> _handlePickFile() async {
    setState(() {
      _isLoading = true;
      _loadingMessages = _parsingMessages;
    });
    try {
      final events = await _importService.pickAndParseExcel();
      setState(() {
        _previewEvents = events;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error parsing file: $e')));
    }
  }

  Future<void> _handlePickImage() async {
    setState(() {
      _isLoading = true;
      _loadingMessages = _scanningMessages;
    });
    try {
      final events = await _importService.pickAndParseImage();
      setState(() {
        _previewEvents = events;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error scanning image: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Timetable'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? ProcessingIndicator(messages: _loadingMessages)
          : _previewEvents == null
          ? _buildDumpZone()
          : _buildPreview(),
    );
  }

  Widget _buildDumpZone() {
    return Column(
      children: [
        const Spacer(),
        Center(
          child: Column(
            children: [
              _buildMainActionButton(),
              const SizedBox(height: 48),
              _buildOptionsGrid(),
            ],
          ),
        ),
        const Spacer(),
        _buildManualEntryLink(),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildMainActionButton() {
    return InkWell(
      onTap: _handlePickImage, // Primary action: Quick Scan
      borderRadius: BorderRadius.circular(100),
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, size: 60, color: Colors.white),
      ),
    );
  }

  Widget _buildOptionsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 1.2,
        children: [
          _buildOptionCard(
            'Excel / CSV',
            Icons.table_chart_outlined,
            _handlePickFile,
          ),
          _buildOptionCard('PDF', Icons.picture_as_pdf_outlined, () {
            // Future: PDF Parser
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('PDF support is coming soon!')),
            );
          }),
          _buildOptionCard(
            'Screenshot',
            Icons.screenshot_outlined,
            _handlePickImage,
          ),
          _buildOptionCard(
            'Camera',
            Icons.camera_alt_outlined,
            _handlePickImage,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(String label, IconData icon, VoidCallback onTap) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 28),
            const SizedBox(height: 12),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualEntryLink() {
    return TextButton(
      onPressed: () async {
        final result = await Navigator.pushNamed(context, '/edit-event');
        if (result == true && mounted) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      },
      child: Text(
        'Or enter manually',
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final theme = Theme.of(context);
    final groupedEvents = _groupEventsByDay();
    final days = groupedEvents.keys.toList()..sort();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Review Your Timetable',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Verify the details before saving.',
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: days.length,
            itemBuilder: (context, index) {
              final day = days[index];
              final dayEvents = groupedEvents[day]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      _getDayName(day).toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  ...dayEvents.map(
                    (event) => _EditableEventTile(
                      key: ObjectKey(event),
                      event: event,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        ),
        _buildPreviewActions(),
      ],
    );
  }


  Widget _buildPreviewActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => setState(() => _previewEvents = null),
              child: const Text('Back'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () async {
                setState(() {
                  _isLoading = true;
                  _loadingMessages = _syncingMessages;
                });

                int savedCount = 0;
                final failedTitles = <String>[];

                // A `finally` guarantees _isLoading always gets reset, even
                // if something below throws — previously an unhandled error
                // partway through this loop (e.g. a device with no
                // calendars configured, or any other unexpected failure)
                // left the screen stuck on the loading indicator forever
                // with no error shown and no way out.
                try {
                  final existingEvents = _storageService.getAllClassEvents();
                  final existingEntities = existingEvents
                      .map((e) => EventEntity.fromClassEvent(e))
                      .toList();

                  for (var event in _previewEvents!) {
                    try {
                      final newEntity = EventEntity.fromClassEvent(event);
                      final conflicts = ConflictEngine.detectConflicts(
                        newEntity,
                        existingEntities,
                      );

                      if (conflicts.isNotEmpty && mounted) {
                        setState(() => _isLoading = false);
                        await Navigator.push<ClassEvent>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ConflictResolutionScreen(
                              existingEvent: existingEvents.firstWhere(
                                (e) => e.id == conflicts.first.id,
                              ),
                              conflictingEvent: event,
                              allEvents: existingEvents,
                              onResolved: (finalEvent) {
                                // Update the event in preview
                                setState(() {
                                  event.startTime = finalEvent.startTime;
                                  event.endTime = finalEvent.endTime;
                                });
                              },
                            ),
                          ),
                        );
                        if (mounted) {
                          setState(() => _isLoading = true);
                        }
                        // Fall through: whichever way the user resolved it
                        // (accept the suggestion, ignore, or edit manually),
                        // the event still needs to actually be saved below —
                        // it must not be silently dropped from the import.
                      }

                      await _storageService.addClassEvent(event);
                      // Keep the running conflict-check state in sync so two
                      // events within this same import batch that overlap
                      // each other are also caught, not just overlaps
                      // against pre-existing events.
                      existingEvents.add(event);
                      existingEntities.add(EventEntity.fromClassEvent(event));
                      savedCount++;
                    } catch (e) {
                      // Don't let one bad event (a malformed time, a plugin
                      // failure, etc.) take down the whole batch — record it
                      // and keep going with the rest.
                      debugPrint('Failed to save "${event.title}": $e');
                      failedTitles.add(event.title);
                    }
                  }
                } finally {
                  if (mounted) {
                    setState(() => _isLoading = false);
                  }
                }

                if (mounted) {
                  final message = failedTitles.isEmpty
                      ? 'Timetable synced successfully!'
                      : savedCount == 0
                      ? 'Couldn\'t save any classes. Please check them and try again.'
                      : 'Synced $savedCount classes. ${failedTitles.length} '
                            'couldn\'t be saved (${failedTitles.join(', ')}).';
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(message)));
                  Navigator.pushReplacementNamed(context, '/dashboard');
                }
              },
              child: const Text('Confirm & Sync'),
            ),
          ),
        ],
      ),
    );
  }

  Map<int, List<ClassEvent>> _groupEventsByDay() {
    final Map<int, List<ClassEvent>> grouped = {};
    for (var event in _previewEvents!) {
      grouped.putIfAbsent(event.dayOfWeek, () => []).add(event);
    }
    // Sort events within each day
    grouped.forEach((day, events) {
      events.sort((a, b) => a.startTime.compareTo(b.startTime));
    });
    return grouped;
  }

  String _getDayName(int day) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[day - 1];
  }
}

/// One editable row in the import preview list. This owns its own
/// TextEditingControllers instead of the parent screen creating fresh ones
/// on every rebuild — with fresh controllers, a keystroke in any field on
/// the page forced a full-list rebuild that recreated every field's
/// controller, resetting cursor position and doing a lot of unnecessary
/// work. Keeping state local means only this one tile rebuilds per keystroke.
class _EditableEventTile extends StatefulWidget {
  final ClassEvent event;

  const _EditableEventTile({super.key, required this.event});

  @override
  State<_EditableEventTile> createState() => _EditableEventTileState();
}

class _EditableEventTileState extends State<_EditableEventTile> {
  late final TextEditingController _titleController;
  late final TextEditingController _timeController;
  late final TextEditingController _venueController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event.title);
    _timeController = TextEditingController(
      text: '${widget.event.startTime} - ${widget.event.endTime}',
    );
    _venueController = TextEditingController(text: widget.event.venue);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _timeController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool hasError =
        widget.event.title.isEmpty || widget.event.startTime.isEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasError ? Colors.red.withOpacity(0.05) : theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasError
              ? Colors.red.withOpacity(0.3)
              : theme.dividerColor.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: 'Subject Title',
                  ),
                  controller: _titleController,
                  onChanged: (val) =>
                      setState(() => widget.event.title = val),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const Icon(Icons.edit_outlined, size: 14, color: Colors.grey),
            ],
          ),
          const Divider(height: 16),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: 'Start - End',
                        ),
                        controller: _timeController,
                        onChanged: (val) {
                          final parts = val.split('-');
                          if (parts.length == 2) {
                            setState(() {
                              widget.event.startTime = parts[0].trim();
                              widget.event.endTime = parts[1].trim();
                            });
                          }
                        },
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: 'Venue',
                        ),
                        controller: _venueController,
                        onChanged: (val) =>
                            setState(() => widget.event.venue = val),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
