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
