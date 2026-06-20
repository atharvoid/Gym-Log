import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';

/// Empty state for the Profile weekly bar chart when no workouts exist.
class ProfileGraphEmptyState extends StatelessWidget {
  final VoidCallback? onStartWorkout;

  const ProfileGraphEmptyState({super.key, this.onStartWorkout});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.bar_chart_outlined,
          size: 48,
          color: Color(0xFF3A3A4A),
        ),
        const SizedBox(height: 16),
        Text(
          'No workouts yet',
          style: AppText.sheetTitle(),
        ),
        const SizedBox(height: 6),
        Text(
          'Log your first workout to see your weekly progress.',
          textAlign: TextAlign.center,
          style: AppText.body(),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              onStartWorkout?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.profileGraphActiveBar,
              foregroundColor: AppColors.bgBase,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'Start Workout',
              style: AppText.button(color: AppColors.bgBase),
            ),
          ),
        ),
      ],
    );
  }
}
