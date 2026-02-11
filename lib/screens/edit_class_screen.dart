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
