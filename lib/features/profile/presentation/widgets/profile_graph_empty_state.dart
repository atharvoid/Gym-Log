import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/shared/widgets/motion/pressable_scale.dart';
import 'package:gymlog/shared/widgets/ui/app_button_shell.dart';

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
        // TEXT SCALING (ship-readiness #3 / D2): this was
        // SizedBox(height: 48) around a raw Text. A fixed height is a
        // CEILING -- once the label's line box passes 48dp at a raised OS
        // font size, the glyphs are painted and then cut off at the bottom,
        // with no overflow exception to warn anyone. The 48dp is now a FLOOR
        // (ConstrainedBox.minHeight + AppButtonShell's invisible row child),
        // so the button grows instead of clipping, and the label sits in
        // Flexible + ellipsis so a long label truncates horizontally.
        // Invariant: a button declares a minimum height, never an exact one.
        ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: double.infinity,
            minHeight: 48,
          ),
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
                minimumSize: const Size(double.infinity, 48),
                // Horizontal inset only. Vertical padding on top of the
                // shell's 48dp floor would inflate the button past 48dp.
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.buttonPrimaryAll,
                ),
              ),
              child: AppButtonShell(
                label: 'Start Workout',
                style: AppText.button(color: accent.onAccent),
                minHeight: 48,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
