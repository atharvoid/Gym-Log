import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// [active_workout_bar.dart]
/// Purpose: Persistent active workout bar shown above bottom nav
/// Dependencies: flutter/material.dart, go_router, app_colors.dart, app_typography.dart
/// Last modified: Track 0, Step 0.7

class ActiveWorkoutBar extends StatelessWidget {
  const ActiveWorkoutBar({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/workout/active'),
      child: Container(
        height: 48,
        decoration: const BoxDecoration(
          color: AppColors.accentGreen,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 2),
            bottom: BorderSide(color: AppColors.border, width: 2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_arrow, color: AppColors.accentFg, size: 20),
            const SizedBox(width: 8),
            Text(
              'Workout in progress — tap to resume',
              style: AppTypography.body(context).copyWith(
                color: AppColors.accentFg,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
