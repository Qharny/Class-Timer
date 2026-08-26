import 'package:flutter/material.dart';
import '../models/program.dart';
import '../services/local_storage_service.dart';
import '../services/location_service.dart';

class ProgramSetupScreen extends StatefulWidget {
  final bool isInitialSetup;

  const ProgramSetupScreen({super.key, this.isInitialSetup = false});

  @override
  State<ProgramSetupScreen> createState() => _ProgramSetupScreenState();
}

class _ProgramSetupScreenState extends State<ProgramSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storageService = LocalStorageService();

  final _institutionController = TextEditingController();
  final _programController = TextEditingController();
  String _level = 'Level 100';
  int _semester = 1;
  double? _campusLat;
  double? _campusLng;
  bool _capturingLocation = false;

  final List<String> _levels = [
    'Level 100',
    'Level 200',
    'Level 300',
    'Level 400',
    'Graduate',
  ];

  @override
  void initState() {
    super.initState();
    final program = _storageService.getProgram();
    if (program != null) {
      _institutionController.text = program.institution;
      _programController.text = program.name;
      _level = program.level;
      _semester = program.semester;
      _campusLat = program.campusLat;
      _campusLng = program.campusLng;
    }
  }

  @override
  void dispose() {
    _institutionController.dispose();
    _programController.dispose();
    super.dispose();
  }

  void _saveProgram() async {
    if (_formKey.currentState!.validate()) {
      final program = Program(
        institution: _institutionController.text,
        name: _programController.text,
        level: _level,
        semester: _semester,
        campusLat: _campusLat,
        campusLng: _campusLng,
      );
      await _storageService.setProgram(program);
      if (mounted) {
        if (widget.isInitialSetup) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        } else {
          Navigator.pop(context);
        }
      }
    }
  }

  Future<void> _captureCampusLocation() async {
    setState(() => _capturingLocation = true);
    final position = await LocationService().captureCurrentPosition();
    if (!mounted) return;
    setState(() => _capturingLocation = false);

    if (position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not get your location. Check that location services and '
            'permission are enabled, then try again while you\'re on campus.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _campusLat = position.latitude;
      _campusLng = position.longitude;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Campus location saved.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isInitialSetup ? 'Program Setup' : 'Edit Program'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Tell us about your academic journey. This helps us tailor your experience.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _institutionController,
                decoration: const InputDecoration(
                  labelText: 'Institution Name (Optional)',
                  prefixIcon: Icon(Icons.school_outlined),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _programController,
                decoration: const InputDecoration(
                  labelText: 'Program Name (e.g., Computer Science)',
                  prefixIcon: Icon(Icons.book_outlined),
                ),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: _level,
                decoration: const InputDecoration(
                  labelText: 'Academic Level',
                  prefixIcon: Icon(Icons.trending_up),
                ),
                items: _levels
                    .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                    .toList(),
                onChanged: (v) => setState(() => _level = v!),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Semester',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  ToggleButtons(
                    isSelected: [_semester == 1, _semester == 2],
                    onPressed: (index) => setState(() => _semester = index + 1),
                    borderRadius: BorderRadius.circular(12),
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('1'),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('2'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text(
                'Campus Location (Optional)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              const Text(
                'Set this while you\'re physically on campus so the app can '
                'nudge you if you\'re still far away as a class approaches. '
                'Nothing is requested or checked until you set this.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _campusLat != null && _campusLng != null
                          ? 'Saved: ${_campusLat!.toStringAsFixed(5)}, ${_campusLng!.toStringAsFixed(5)}'
                          : 'Not set',
                      style: TextStyle(
                        color: _campusLat != null ? null : Colors.grey,
                      ),
                    ),
                  ),
                  if (_campusLat != null)
                    TextButton(
                      onPressed: () => setState(() {
                        _campusLat = null;
                        _campusLng = null;
                      }),
                      child: const Text('Clear'),
                    ),
                  OutlinedButton.icon(
                    onPressed: _capturingLocation
                        ? null
                        : _captureCampusLocation,
                    icon: _capturingLocation
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location, size: 18),
                    label: const Text('Use Current Location'),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: _saveProgram,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('SAVE PROGRAM PROFILE'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
