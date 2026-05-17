import 'package:flutter/material.dart';

class ActiveWorkoutBar extends StatelessWidget {
  const ActiveWorkoutBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: const Center(child: Text('Active workout — tap to open')),
    );
  }
}
