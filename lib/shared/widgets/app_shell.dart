import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/workout/presentation/providers/active_workout_provider.dart';
import 'active_workout_bar.dart';
import 'bottom_nav_bar.dart';

class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWorkoutActive = ref.watch(activeWorkoutProvider.select((s) => s.isActive));

    return Scaffold(
      body: child,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isWorkoutActive) const ActiveWorkoutBar(),
          const BottomNavBar(),
        ],
      ),
    );
  }
}
