import 'dart:io';

void main() async {
  final basePath = Directory.current.path;

  final directories = [
    'lib/models',
    'lib/screens',
    'lib/services',
    'lib/widgets',
  ];

  final files = {
    'lib/main.dart': _mainTemplate(),
    'lib/models/class_model.dart': _classModelTemplate(),
    'lib/screens/home_screen.dart': _homeScreenTemplate(),
    'lib/screens/add_class_screen.dart': _addClassTemplate(),
    'lib/screens/edit_class_screen.dart': _editClassTemplate(),
    'lib/services/local_storage_service.dart': _storageTemplate(),
    'lib/widgets/class_card.dart': _classCardTemplate(),
    'lib/widgets/timer_bar.dart': _timerBarTemplate(),
  };

  // Create directories
  for (var dir in directories) {
    final directory = Directory('$basePath/$dir');
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
      print('Created directory: $dir');
    }
  }

  // Create files
  for (var entry in files.entries) {
    final file = File('$basePath/${entry.key}');
    if (!file.existsSync()) {
      file.writeAsStringSync(entry.value);
      print('Created file: ${entry.key}');
    }
  }

  print('\n✅ Class Timer structure generated successfully.');
}

String _mainTemplate() => '''
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const ClassTimerApp());
}

class ClassTimerApp extends StatelessWidget {
  const ClassTimerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Class Timer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}
''';

String _classModelTemplate() => '''
class ClassSession {
  final String id;
  final String title;
  final int dayOfWeek;
  final DateTime startTime;
  final DateTime endTime;

  ClassSession({
    required this.id,
    required this.title,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });
}
''';

String _homeScreenTemplate() => '''
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Today's Classes")),
      body: const Center(
        child: Text('No classes yet.'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
''';

String _addClassTemplate() => '''
import 'package:flutter/material.dart';

class AddClassScreen extends StatelessWidget {
  const AddClassScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Class")),
      body: const Center(
        child: Text('Add Class Form Here'),
      ),
    );
  }
}
''';

String _editClassTemplate() => '''
import 'package:flutter/material.dart';

class EditClassScreen extends StatelessWidget {
  const EditClassScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Class")),
      body: const Center(
        child: Text('Edit Class Form Here'),
      ),
    );
  }
}
''';

String _storageTemplate() => '''
class LocalStorageService {
  // Hive implementation will go here
}
''';

String _classCardTemplate() => '''
import 'package:flutter/material.dart';

class ClassCard extends StatelessWidget {
  const ClassCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: ListTile(
        title: Text('Class Name'),
        subtitle: Text('Time range'),
      ),
    );
  }
}
''';

String _timerBarTemplate() => '''
import 'package:flutter/material.dart';

class TimerBar extends StatelessWidget {
  final double progress;

  const TimerBar({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(value: progress);
  }
}
''';
