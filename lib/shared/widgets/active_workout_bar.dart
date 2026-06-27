import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/dynamic_accent_theme.dart';
import '../../features/workout/presentation/providers/active_workout_provider.dart';
import '../../features/workout/presentation/providers/workout_timer_provider.dart';

/// [active_workout_bar.dart]
/// Minimized "workout in progress" bar shown above the bottom nav while a
/// session is live. Hevy-clean: a live elapsed timer + the workout name +
/// "N exercises · M sets" — no decorative pulse, just the data you need to
/// decide whether to jump back in. Tapping anywhere expands /workout/active.
class ActiveWorkoutBar extends ConsumerWidget {
  const ActiveWorkoutBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = context.accent;
    final timer = ref.watch(workoutTimerProvider); // "HH:MM:SS", ticks 1/s

    final summary = ref.watch(activeWorkoutProvider.select((s) {
      if (s == null) return (name: 'Workout', exercises: 0, sets: 0);
      final raw = s.name?.trim();
      var done = 0;
      for (final ex in s.exercises) {
        for (final set in ex.sets) {
          if (set.isCompleted) done++;
        }
      }
      return (
        name: (raw == null || raw.isEmpty) ? 'Workout' : raw,
        exercises: s.exercises.length,
        sets: done,
      );
    }));

    final detail =
        '${summary.exercises} exercise${summary.exercises == 1 ? '' : 's'}'
        ' · ${summary.sets} set${summary.sets == 1 ? '' : 's'}';

    return Semantics(
      button: true,
      label: 'Resume workout, elapsed $timer',
      child: GestureDetector(
        onTap: () => context.push('/workout/active'),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(AppRadius.buttonSecondary),
            border: Border.all(color: AppColors.borderDefault, width: 1),
          ),
          child: Row(
            children: [
              // Live timer pill — the only accent fill; calm, no pulsing glow.
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: accent.muted,
                  borderRadius: AppRadius.badgeAll,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: accent.base,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    // HH:MM:SS is fixed-width; add tabular figures if your
                    // AppText.value font jitters between frames.
                    Text(timer, style: AppText.value(color: accent.light)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Name + details
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.cardTitle(),
                    ),
                    const SizedBox(height: 2),
                    Text(detail,
                        style: AppText.meta(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text('Resume', style: AppText.button(color: accent.light)),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textTertiary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
