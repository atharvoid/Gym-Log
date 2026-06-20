import 'package:flutter/material.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/set_type.dart';
import 'package:gymlog/core/database/daos/routines_dao.dart';
import 'package:gymlog/core/database/daos/workouts_dao.dart';
import 'package:gymlog/shared/widgets/ui/exercise_thumbnail.dart';

/// One exercise inside a routine. Sits directly on the black background (no gray
/// card) — grouping comes from spacing + the set-table hairlines. Shows the
/// PLANNED scheme (the routine's target sets×reps) under the name, then last
/// session's actual sets in the table below.
class RoutineExerciseBlock extends StatelessWidget {
  final HydratedRoutineExercise hydratedExercise;
  final List<LastSessionSetData>? lastSets;
  final VoidCallback? onTap;
  final bool isLoadingHistory;
  final bool isLast;

  const RoutineExerciseBlock({
    super.key,
    required this.hydratedExercise,
    this.lastSets,
    this.onTap,
    this.isLoadingHistory = false,
    this.isLast = false,
  });

  String _fmtKg(double? w) => w == null
      ? '–'
      : (w % 1 == 0 ? w.toInt().toString() : w.toStringAsFixed(1));

  /// The planned scheme from the routine config — what you're meant to do.
  String get _target {
    final c = hydratedExercise.config;
    final reps = c.defaultReps;
    return reps != null
        ? '${c.defaultSets} sets × $reps reps'
        : '${c.defaultSets} sets';
  }

  String _lastSummary(List<LastSessionSetData> sets) {
    if (sets.isEmpty) return 'No history yet';
    final top =
        sets.reduce((a, b) => (a.weightKg ?? 0) >= (b.weightKg ?? 0) ? a : b);
    final r = top.reps?.toString() ?? '–';
    return 'Last session, top set ${_fmtKg(top.weightKg)} kilograms for $r reps';
  }

  @override
  Widget build(BuildContext context) {
    final sets = [...?lastSets]
      ..sort((a, b) => a.setNumber.compareTo(b.setNumber));
    final hasHistory = sets.isNotEmpty;

    // One screen-reader node for the exercise (name + plan + last summary),
    // instead of a fragment per text + per set-table cell.
    final a11yLabel = '${hydratedExercise.exercise.name}. Target $_target. '
        '${isLoadingHistory ? 'Loading last session' : (hasHistory ? _lastSummary(sets) : 'No history yet')}';

    return Semantics(
      container: true,
      button: onTap != null,
      label: a11yLabel,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  excludeFromSemantics: true,
                  borderRadius: AppRadius.thumbnailAll,
                  child: Row(
                    children: [
                      ExerciseThumbnail(
                          gifUrl: hydratedExercise.exercise.gifUrl),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hydratedExercise.exercise.name,
                              style: AppText.exerciseName(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(_target, style: AppText.meta()),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (isLoadingHistory)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            else if (hasHistory)
              ExcludeSemantics(child: _SetTable(sets: sets))
            else
              ExcludeSemantics(
                child: Text(
                  'No history yet — your last session will show here',
                  style: AppText.caption(color: AppColors.textTertiary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SetTable extends StatelessWidget {
  final List<LastSessionSetData> sets;
  const _SetTable({required this.sets});

  /// Right gutter so the numeric columns sit inboard of the screen edge.
  static const double _numGutter = 20;

  String _fmtKg(double? w) => w == null
      ? '–'
      : (w % 1 == 0 ? w.toInt().toString() : w.toStringAsFixed(1));

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text('LAST SESSION',
              style: AppText.columnHeader(color: AppColors.textTertiary)),
        ),
        Row(
          children: [
            Expanded(
              flex: 5,
              child: Text('SET',
                  style: AppText.columnHeader(color: AppColors.textSecondary)),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.only(right: _numGutter),
                child: Text('KG',
                    style: AppText.columnHeader(color: AppColors.textSecondary),
                    textAlign: TextAlign.right),
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.only(right: _numGutter),
                child: Text('REPS',
                    style: AppText.columnHeader(color: AppColors.textSecondary),
                    textAlign: TextAlign.right),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        for (var i = 0; i < sets.length; i++)
          Container(
            decoration: BoxDecoration(
              border: i == 0
                  ? null
                  : const Border(
                      top: BorderSide(color: AppColors.borderSubtle, width: 1)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        child: Text('${sets[i].setNumber}',
                            style: AppText.value(color: AppColors.textSecondary)),
                      ),
                      const SizedBox(width: 10),
                      if (_chipFor(sets[i].setType) case final chip?) chip,
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.only(right: _numGutter),
                    child: Text(_fmtKg(sets[i].weightKg),
                        style: AppText.value(), textAlign: TextAlign.right),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.only(right: _numGutter),
                    child: Text(sets[i].reps?.toString() ?? '–',
                        style: AppText.value(), textAlign: TextAlign.right),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Set-type badge. Color + icon resolve through the shared [SetType] enum so
  /// a warm-up / drop / failure set is IDENTICAL here, in the live logger, and
  /// on the workout-history pill. Normal sets show no badge.
  Widget? _chipFor(String? type) {
    final t = SetType.of(type);
    switch (t) {
      case SetType.warmup:
        return _SetTypeChip(type: t, label: 'Warm');
      case SetType.dropset:
        return _SetTypeChip(type: t, label: 'Drop');
      case SetType.failure:
        return _SetTypeChip(type: t, label: 'Fail');
      case SetType.normal:
        return null;
    }
  }
}

class _SetTypeChip extends StatelessWidget {
  final SetType type;
  final String label;

  const _SetTypeChip({required this.type, required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: type.color.withValues(alpha: 0.15),
          borderRadius: AppRadius.badgeAll,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(type.icon, size: 12, color: type.color),
            const SizedBox(width: 4),
            Text(label, style: AppText.badge(color: type.color)),
          ],
        ),
      );
}
