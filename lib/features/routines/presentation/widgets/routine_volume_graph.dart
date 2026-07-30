import 'package:flutter/material.dart';
import 'package:gymlog/core/database/daos/workouts_dao.dart';
import 'package:gymlog/core/utils/units.dart';
import 'package:gymlog/shared/widgets/branded_line_chart.dart';

/// Hevy-style volume chart. Dumb widget — renders only from [data].
/// The screen owns the section header, range dropdown, and delta pill.
///
/// THIN WRAPPER over [BrandedLineChart] — Routine Detail, Exercise Detail
/// and Profile must stay pixel-identical: same axis formatting, same avg
/// line, same touch behavior, same selected-dot styling, same empty state.
/// Do NOT reintroduce a bespoke fl_chart implementation here; duplicated
/// chart logic is exactly what the shared component exists to prevent
/// (it had already drifted once: full-number axis labels and a permanently
/// ringed last dot on this screen vs. compact labels everywhere else).
class RoutineVolumeGraph extends StatelessWidget {
  final List<DailyVolumeSample> data;

  /// Active weight unit ('kg' | 'lbs').
  ///
  /// Passed in by the owning screen rather than read from a provider here:
  /// this widget is deliberately dumb and RoutineDetailScreen already watches
  /// weightUnitProvider. Same pattern as RoutineExerciseBlock's `unit`.
  final String unit;

  const RoutineVolumeGraph({
    super.key,
    required this.data,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return BrandedLineChart(
      // Volume is stored in kg, so the plotted VALUES are converted here — not
      // just the label. Formatting alone would leave the Y-axis ticks on a kg
      // scale underneath an lbs header, which reads as a broken chart.
      data: [
        for (final s in data) ChartPoint(s.day, kgToDisplay(s.volume, unit))
      ],
      // "1,800 kg" / "3,968 lbs" — same full-notation volume language as the
      // Home feed cards and Workout Detail stats (never compact + unit).
      // Values are already converted above, so this must NOT call formatVolume
      // (that would convert a second time).
      valueFormatter: (v) => '${groupThousands(v)} ${unitLabel(unit)}',
      emptyTitle: 'No sessions logged yet',
      emptySubtitle: 'Finish a workout to see your volume trend',
    );
  }
}
