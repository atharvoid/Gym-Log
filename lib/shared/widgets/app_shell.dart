import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/workout/presentation/providers/active_workout_provider.dart';
import '../../core/theme/app_colors.dart';
import 'active_workout_bar.dart';
import 'bottom_nav_bar.dart';

/// [app_shell.dart]
/// Purpose: High-Density Tracker - App shell with bottom nav
/// Dependencies: flutter/material.dart, flutter_riverpod, app_colors.dart
/// Last modified: High-Density Tracker Overhaul

class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWorkoutActive = ref.watch(activeWorkoutProvider) != null;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: child,
          ),
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeOutCubic,
            transitionBuilder: (child, animation) {
              return SizeTransition(
                sizeFactor: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1.0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: isWorkoutActive 
                ? const ActiveWorkoutBar(key: ValueKey('activeBar')) 
                : const SizedBox.shrink(key: ValueKey('emptyBar')),
          ),
          const BottomNavBar(),
        ],
      ),
    );
  }
}
