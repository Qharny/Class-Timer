import 'package:flutter/material.dart';
import '../models/course.dart';
import '../services/local_storage_service.dart';

class CourseManagementScreen extends StatefulWidget {
  const CourseManagementScreen({super.key});

  @override
  State<CourseManagementScreen> createState() => _CourseManagementScreenState();
}

class _CourseManagementScreenState extends State<CourseManagementScreen> {
  final _storageService = LocalStorageService();
  List<Course> _courses = [];

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  void _loadCourses() {
    setState(() {
      _courses = _storageService.getAllCourses();
    });
  }

  void _showAddEditCourseDialog([Course? course]) {
    final isEditing = course != null;
    final nameController = TextEditingController(text: course?.name);
    final codeController = TextEditingController(text: course?.code);
    final lecturerController = TextEditingController(text: course?.lecturer);
    final creditHoursController = TextEditingController(
      text: course?.creditHours.toString() ?? '3',
    );
    String colorTag = course?.colorTag ?? '#2196F3';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEditing ? 'Edit Course' : 'Add New Course',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Course Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: codeController,
                decoration: const InputDecoration(labelText: 'Course Code'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: lecturerController,
                decoration: const InputDecoration(labelText: 'Lecturer'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: creditHoursController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Credit Hours'),
              ),
              const SizedBox(height: 24),
              const Text(
                'Select ColorTag',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children:
                    [
                          '#F44336',
                          '#E91E63',
                          '#9C27B0',
                          '#673AB7',
                          '#3F51B5',
                          '#2196F3',
                          '#00BCD4',
                          '#009688',
                          '#4CAF50',
                          '#8BC34A',
                          '#FFEB3B',
                          '#FFC107',
                          '#FF9800',
                          '#FF5722',
                        ]
                        .map(
                          (colorHex) => GestureDetector(
                            onTap: () => setState(() => colorTag = colorHex),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Color(
                                  int.parse(colorHex.replaceFirst('#', '0xFF')),
                                ),
                                shape: BoxShape.circle,
                                border: colorTag == colorHex
                                    ? Border.all(color: Colors.black, width: 2)
                                    : null,
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isEmpty) return;

                  final newCourse = Course(
                    id:
                        course?.id ??
                        DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text,
                    code: codeController.text,
                    lecturer: lecturerController.text,
                    colorTag: colorTag,
                    creditHours: int.tryParse(creditHoursController.text) ?? 3,
                  );

                  await _storageService.addCourse(newCourse);
                  _loadCourses();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(isEditing ? 'UPDATE COURSE' : 'ADD COURSE'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Course Management')),
      body: _courses.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text(
                    'No courses added yet.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _courses.length,
              itemBuilder: (context, index) {
                final course = _courses[index];
                final color = Color(
                  int.parse(course.colorTag.replaceFirst('#', '0xFF')),
                );
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withOpacity(0.1),
                      child: Text(
                        course.code.substring(0, 2).toUpperCase(),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    title: Text(
                      course.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${course.code} • ${course.lecturer}'),
                    trailing: const Icon(Icons.edit_outlined, size: 20),
                    onTap: () => _showAddEditCourseDialog(course),
                    onLongPress: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Course?'),
                          content: const Text(
                            'This will remove the course and all its sessions.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('CANCEL'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('DELETE'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await _storageService.deleteCourse(course.id);
                        _loadCourses();
                      }
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditCourseDialog(),
        label: const Text('New Course'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
