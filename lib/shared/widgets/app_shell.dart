import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/workout/presentation/providers/active_workout_provider.dart';
import '../../core/theme/app_colors.dart';
import 'active_workout_bar.dart';
import 'bottom_nav_bar.dart';

/// [app_shell.dart]
/// Purpose: App shell with persistent bottom nav and active workout bar
/// Dependencies: flutter/material.dart, flutter_riverpod, app_colors.dart
/// Last modified: Track 0, Step 0.7

class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWorkoutActive = ref.watch(activeWorkoutProvider.select((s) => s.isActive));

    return Scaffold(
      backgroundColor: AppColors.bgBase,
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
