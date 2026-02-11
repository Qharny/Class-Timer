import 'package:flutter/material.dart';

class TimerBar extends StatelessWidget {
  final double progress;

  const TimerBar({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(value: progress);
  }
}
