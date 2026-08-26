import 'dart:async';
import 'package:flutter/material.dart';

/// A loading state that cycles through a sequence of status messages instead
/// of showing a bare spinner, so a multi-step operation (parsing a file,
/// saving a batch of events) reads as progress rather than an indefinite hang.
class ProcessingIndicator extends StatefulWidget {
  final List<String> messages;
  final Duration interval;

  const ProcessingIndicator({
    super.key,
    required this.messages,
    this.interval = const Duration(milliseconds: 1600),
  });

  @override
  State<ProcessingIndicator> createState() => _ProcessingIndicatorState();
}

class _ProcessingIndicatorState extends State<ProcessingIndicator> {
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.messages.length > 1) {
      _timer = Timer.periodic(widget.interval, (_) {
        if (!mounted) return;
        setState(() => _index = (_index + 1) % widget.messages.length);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = widget.messages.isEmpty
        ? 'Working on it...'
        : widget.messages[_index % widget.messages.length];

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 28),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.2),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: Text(
                message,
                key: ValueKey<String>(message),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
