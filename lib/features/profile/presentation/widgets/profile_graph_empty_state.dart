import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/shared/widgets/motion/pressable_scale.dart';

/// Empty state for the Profile weekly bar chart when no workouts exist.
class ProfileGraphEmptyState extends StatelessWidget {
  final VoidCallback? onStartWorkout;

  const ProfileGraphEmptyState({super.key, this.onStartWorkout});

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    final accent = context.accent;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.bar_chart_outlined,
          size: 48,
          color: surface.textTertiary,
        ),
        const SizedBox(height: 16),
        Text(
          'No workouts yet',
          style: AppText.sheetTitle(color: surface.textPrimary),
        ),
        const SizedBox(height: 6),
        Text(
          'Log your first workout to see your weekly progress.',
          textAlign: TextAlign.center,
          style: AppText.body(color: surface.textSecondary),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: PressableScale(
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                onStartWorkout?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accent.base,
                foregroundColor: accent.onAccent,
                elevation: 0,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.buttonPrimaryAll,
                ),
              ),
              child: Text(
                'Start Workout',
                style: AppText.button(color: accent.onAccent),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
