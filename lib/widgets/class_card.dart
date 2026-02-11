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
