import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymlog/core/models/rest_preference.dart';
import 'package:gymlog/core/providers/settings_provider.dart';
import 'package:gymlog/features/workout/domain/active_workout_state.dart';
import 'package:gymlog/features/workout/presentation/providers/active_workout_provider.dart';
import 'package:gymlog/shared/widgets/ui/app_action_chip.dart';
import 'rest_time_sheet.dart';

/// Compact rest-duration override chip for exercise card headers.
///
/// Uses [AppActionChip] with [ActionSignifier.sheet] to enforce the
/// "Border = Clickable" affordance contract and minimum 48×48 touch targets.
///
/// Labels:
/// - Default -> `Rest 1:30`
/// - Custom -> `Rest 0:45`
/// - Disabled -> `Rest Off`
class CompactRestChip extends ConsumerWidget {
  final int exerciseIndex;
  final String exerciseName;

  const CompactRestChip({
    super.key,
    required this.exerciseIndex,
    required this.exerciseName,
  });

  String _formatDuration(int totalSeconds) {
    if (totalSeconds <= 0) return 'Off';
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _handleTap(
    BuildContext context,
    WidgetRef ref,
    RestPreference currentPreference,
    int defaultRest,
  ) async {
    final result = await showRestTimeSheet(
      context: context,
      exerciseName: exerciseName,
      currentPreference: currentPreference,
      globalSeconds: defaultRest,
    );

    if (result != null) {
      ref
          .read(activeWorkoutProvider.notifier)
          .setRestPreference(exerciseIndex, result);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workout = ref.watch(activeWorkoutProvider);
    if (workout == null || exerciseIndex >= workout.exercises.length) {
      return const SizedBox.shrink();
    }
    final exercise = workout.exercises[exerciseIndex];
    final defaultRest = ref.watch(defaultRestSecondsProvider);
    final preference = normalizeRestPreference(
      preference: exercise.restPreference,
      globalSeconds: defaultRest,
    );

    final isCustom = preference is RestPreferenceCustomDuration;
    final isDisabled = isOff(preference);

    String labelText;
    if (isDisabled) {
      labelText = 'Rest Off';
    } else if (preference is RestPreferenceCustomDuration) {
      labelText = 'Rest ${_formatDuration(preference.seconds)}';
    } else {
      labelText = 'Rest ${_formatDuration(defaultRest)}';
    }

    final IconData iconData =
        isDisabled ? Icons.timer_off_rounded : Icons.timer_rounded;

    return Align(
      alignment: Alignment.centerLeft,
      child: AppActionChip(
        label: labelText,
        leadingIcon: iconData,
        signifier: ActionSignifier.sheet,
        isSelected: isCustom && !isDisabled,
        semanticLabel:
            'Set rest duration override for $exerciseName. Currently set to $labelText.',
        onTap: () => _handleTap(context, ref, preference, defaultRest),
      ),
    );
  }
}
