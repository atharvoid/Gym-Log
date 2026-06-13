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
  const RoutineVolumeGraph({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return BrandedLineChart(
      data: [for (final s in data) ChartPoint(s.day, s.volume)],
      // "1,800 kg" — same full-notation volume language as the Home feed
      // cards and Workout Detail stats (never compact + unit).
      valueFormatter: (v) => '${groupThousands(v)} kg',
      emptyTitle: 'No sessions logged yet',
      emptySubtitle: 'Finish a workout to see your volume trend',
    );
  }
}
