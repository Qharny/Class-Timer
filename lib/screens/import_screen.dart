import 'package:flutter/material.dart';
import '../services/import_service.dart';
import '../models/class_event.dart';
import '../widgets/event_card.dart';
import '../services/local_storage_service.dart';

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

  Future<void> _handlePickFile() async {
    setState(() => _isLoading = true);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import Timetable')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _previewEvents == null
          ? _buildLanding()
          : _buildPreview(),
    );
  }

  Widget _buildLanding() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.upload_file, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          const Text('Upload your Excel timetable'),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: _handlePickFile,
            icon: const Icon(Icons.add),
            label: const Text('Select File'),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Found ${_previewEvents!.length} events',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _previewEvents!.length,
            itemBuilder: (context, index) {
              return EventCard(event: _previewEvents![index]);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                setState(() => _isLoading = true);
                for (var event in _previewEvents!) {
                  await _storageService.addClassEvent(event);
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Timetable imported successfully!'),
                    ),
                  );
                  Navigator.pushReplacementNamed(context, '/dashboard');
                }
              },
              child: const Text('Confirm & Save'),
            ),
          ),
        ),
      ],
    );
  }
}
