import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/database/daos/workouts_dao.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/shared/widgets/ui/app_card.dart';
import 'package:gymlog/shared/widgets/ui/exercise_thumbnail.dart';

const _kAccentPos = AppColors.success;

// Nav throttle: a fast double-tap on the card used to push the exercise-detail
// route twice (the old GestureDetector had no guard, ripple, or haptic).
DateTime _lastNav = DateTime.fromMillisecondsSinceEpoch(0);
bool _navThrottle() {
  final now = DateTime.now();
  if (now.difference(_lastNav) < const Duration(milliseconds: 600)) {
    return false;
  }
  _lastNav = now;
  return true;
}

/// A single exercise inside the Workout Detail screen: header (static thumbnail
/// + name + equipment) and a set table. Tapping opens the exercise detail.
class DetailExerciseCard extends StatelessWidget {
  final HydratedWorkoutExercise hydratedExercise;

  const DetailExerciseCard({super.key, required this.hydratedExercise});

  @override
  Widget build(BuildContext context) {
    final exercise = hydratedExercise.exerciseMetadata;
    final sets = hydratedExercise.sets;
    final previousSets = hydratedExercise.previousSets;
    final hasPrevHistory = previousSets.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: AppCard(
        padding: EdgeInsets.zero,
        radius: AppRadius.card,
        onTap: () {
          if (!_navThrottle()) return;
          HapticFeedback.selectionClick();
          context.push('/exercise/detail/${exercise.id}', extra: exercise);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ExerciseCardHeader(exercise: exercise),
            const SizedBox(height: 12),
            _SetTableHeader(hasPrevHistory: hasPrevHistory),
            const SizedBox(height: 4),
            ...sets.asMap().entries.map((entry) {
              final idx = entry.key;
              final set = entry.value;
              // Cross-session compare: same set index from the prior session.
              final prevSet =
                  idx < previousSets.length ? previousSets[idx] : null;
              return _DetailSetRow(
                setNumber: idx + 1,
                set: set,
                isAlternate: idx.isOdd,
                prevSet: prevSet,
                hasPrevHistory: hasPrevHistory,
                equipment: exercise.equipment,
              );
            }),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _ExerciseCardHeader extends StatelessWidget {
  final Exercise exercise;

  const _ExerciseCardHeader({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          // Static last-frame thumbnail on a light tile — see ExerciseThumbnail.
          ExcludeSemantics(child: ExerciseThumbnail(gifUrl: exercise.gifUrl)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    exercise.name,
                    style: AppText.exerciseName(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (exercise.equipment.isNotEmpty)
                  Text(exercise.equipment, style: AppText.caption()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SetTableHeader extends StatelessWidget {
  /// VS PREV header shown only when the exercise has prior history.
  final bool hasPrevHistory;

  const _SetTableHeader({required this.hasPrevHistory});

  @override
  Widget build(BuildContext context) {
    // Same column skeleton as the data rows (SET 64 | Expanded | trailing) so
    // header labels and cells share one alignment axis.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text('SET',
                style: AppText.columnHeader(color: AppColors.textSecondary)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('WEIGHT & REPS',
                style: AppText.columnHeader(color: AppColors.textSecondary)),
          ),
          if (hasPrevHistory)
            Text('VS PREV',
                textAlign: TextAlign.right,
                style: AppText.columnHeader(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _DetailSetRow extends StatelessWidget {
  final int setNumber;
  final WorkoutSet set;
  final bool isAlternate;
  final WorkoutSet? prevSet;
  final bool hasPrevHistory;
  final String? equipment;

  const _DetailSetRow({
    required this.setNumber,
    required this.set,
    required this.isAlternate,
    this.prevSet,
    required this.hasPrevHistory,
    this.equipment,
  });

  double? get _crossSessionDelta {
    if (prevSet == null) return null;
    if (set.weightKg <= 0 || prevSet!.weightKg <= 0) return null;
    final d = set.weightKg - prevSet!.weightKg;
    return d == 0 ? null : d;
  }

  @override
  Widget build(BuildContext context) {
    final bg = isAlternate
        ? AppColors.textPrimary.withValues(alpha: 0.03)
        : Colors.transparent;
    final delta = _crossSessionDelta;

    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildSetTypeIndicator(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Text(_formatWeight(set.weightKg, equipment),
                    style: AppText.statLabel(color: AppColors.textPrimary)),
                Text(' × ', style: AppText.statLabel()),
                Text('${set.reps} reps',
                    style: AppText.statLabel(color: AppColors.textPrimary)),
                if (set.isPr) ...[
                  const SizedBox(width: 8),
                  const _PrBadge(),
                ],
              ],
            ),
          ),
          if (hasPrevHistory)
            delta != null
                ? _DeltaChip(delta: delta)
                : Text('—', style: AppText.statLabel()),
        ],
      ),
    );
  }

  Widget _buildSetTypeIndicator() {
    switch (set.setType.toLowerCase()) {
      case 'warmup':
        return const _SetTypePill(
          icon: Icons.local_fire_department_rounded,
          label: 'Warm',
          color: AppColors.warning,
        );
      case 'dropset':
      case 'drop':
        return const _SetTypePill(
          icon: Icons.trending_down_rounded,
          label: 'Drop',
          color: AppColors.accentPrimary,
        );
      case 'failure':
        return const _SetTypePill(
          icon: Icons.warning_amber_rounded,
          label: 'Fail',
          color: AppColors.error,
        );
      default:
        return Text('$setNumber',
            style: AppText.statLabel(color: AppColors.textPrimary));
    }
  }

  static String _formatWeight(double kg, String? equipment) {
    final isBw = equipment?.toLowerCase() == 'body weight';
    final prefix = (isBw && kg > 0) ? '+' : '';
    if (kg == kg.truncateToDouble()) return '$prefix${kg.toInt()} kg';
    return '$prefix${kg.toStringAsFixed(1)} kg';
  }
}

class _SetTypePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SetTypePill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppRadius.badgeAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: AppText.badge(color: color)),
        ],
      ),
    );
  }
}

/// Tinted chip: `+2.5 kg` in green (heavier), `2.5 kg ↓` in amber (a drop is a
/// deload, not an error). Sign + arrow survive for color-blind users.
class _DeltaChip extends StatelessWidget {
  final double delta;
  const _DeltaChip({required this.delta});

  @override
  Widget build(BuildContext context) {
    final isPositive = delta > 0;
    final color = isPositive ? _kAccentPos : AppColors.warning;
    final icon =
        isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
    final abs = delta.abs();
    final amount = abs == abs.truncateToDouble()
        ? abs.toInt().toString()
        : abs.toStringAsFixed(1);

    return Semantics(
      label: '${isPositive ? 'Up' : 'Down'} $amount kilograms from last time',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: AppRadius.badgeAll,
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 2),
            Text('$amount kg', style: AppText.badge(color: color)),
          ],
        ),
      ),
    );
  }
}

/// Amber PR badge inline with PR sets — matches the Home feed's PR badge.
class _PrBadge extends StatelessWidget {
  const _PrBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.prBadgeBg,
        borderRadius: AppRadius.badgeAll,
        border: Border.all(color: AppColors.prBadgeBorder, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events_rounded,
              size: 11, color: AppColors.warning),
          const SizedBox(width: 3),
          Text('PR', style: AppText.badge()),
        ],
      ),
    );
  }
}
