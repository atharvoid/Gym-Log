import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/core/exercises/muscle_taxonomy.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/database/daos/workouts_dao.dart';
import 'package:gymlog/core/models/measurement_type.dart';
import 'package:gymlog/core/providers/premium_provider.dart';
import 'package:gymlog/features/routines/presentation/widgets/routine_detail_styles.dart';
import 'package:gymlog/shared/widgets/async_error_state.dart';
import 'package:gymlog/shared/widgets/branded_line_chart.dart';
import 'package:gymlog/shared/widgets/premium_paywall.dart';
import 'package:gymlog/shared/widgets/ui/time_range_filter.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import 'package:gymlog/shared/widgets/ui/skeleton.dart';
import '../providers/exercise_analytics_provider.dart';
import 'package:gymlog/shared/widgets/exercise_hero_image.dart';
import 'package:gymlog/shared/widgets/motion/entrance_fade.dart';

class ExerciseDetailScreen extends ConsumerStatefulWidget {
  final int exerciseId;
  final Exercise? exercise;

  const ExerciseDetailScreen(
      {super.key, required this.exerciseId, this.exercise});

  @override
  ConsumerState<ExerciseDetailScreen> createState() =>
      _ExerciseDetailScreenState();
}

final _exerciseFallbackProvider =
    FutureProvider.autoDispose.family<Exercise, int>((ref, id) {
  final db = ref.watch(databaseProvider);
  return db.exercisesDao.getExerciseById(id);
});

class _ExerciseDetailScreenState extends ConsumerState<ExerciseDetailScreen> {
  int _activeToggleIndex = 0;
  String _selectedTimeRange = '6M';

  List<String> _getToggleLabels(MeasurementType mType) {
    switch (mType) {
      case MeasurementType.weightAndReps:
        return [
          'One Rep Max',
          'Heaviest Weight',
          'Session Volume',
          'Total Reps'
        ];
      case MeasurementType.repsOnly:
        return ['Max Reps', 'Total Reps'];
      case MeasurementType.duration:
        return ['Max Duration', 'Total Duration'];
      case MeasurementType.distance:
        return ['Distance', 'Duration', 'Pace'];
    }
  }

  double? _metricForToggle(
    ExerciseHistoryData e,
    int index,
    MeasurementType mType,
  ) {
    switch (mType) {
      case MeasurementType.weightAndReps:
        switch (index) {
          case 0:
            return e.estimated1RM ?? e.weight;
          case 1:
            return e.weight;
          case 2:
            return e.volume;
          case 3:
            return e.reps.toDouble();
          default:
            return e.estimated1RM ?? e.weight;
        }
      case MeasurementType.repsOnly:
        return e.reps.toDouble();
      case MeasurementType.duration:
        return e.reps.toDouble();
      case MeasurementType.distance:
        switch (index) {
          case 0:
            return e.weight;
          case 1:
            return e.reps.toDouble();
          case 2:
            if (e.weight != null && e.weight! > 0 && e.reps > 0) {
              return e.reps / (e.weight! / 1000.0);
            }
            return null;
          default:
            return e.weight;
        }
    }
  }

  Widget _wrapPulse({required Widget child}) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return SkeletonPulse(child: child);
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(
        exerciseAnalyticsProvider((widget.exerciseId, _selectedTimeRange)));
    final prs = ref.watch(exercisePersonalRecordsProvider(
        (widget.exerciseId, _selectedTimeRange)));

    final exerciseAsync = widget.exercise != null
        ? AsyncValue.data(widget.exercise!)
        : ref.watch(_exerciseFallbackProvider(widget.exerciseId));

    final surface = context.surface;

    return exerciseAsync.when(
      loading: () => _buildPageSkeleton(context),
      error: (e, st) => Scaffold(
        backgroundColor: surface.bgBase,
        appBar: AppBar(
          backgroundColor: surface.bgBase,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: surface.textPrimary),
        ),
        body: AsyncErrorState(
          message: "Couldn't load this exercise.",
          onRetry: () =>
              ref.invalidate(_exerciseFallbackProvider(widget.exerciseId)),
        ),
      ),
      data: (exercise) {
        final disableAnims = MediaQuery.disableAnimationsOf(context);

        // GIF section — sits OUTSIDE _entryFade so the Hero widget is never
        // clipped by the FadeTransition. For reduced-motion users: a static
        // frame with no Hero. BoxFit.cover matches the thumbnail source and
        // the flightShuttleBuilder in exercise_selection_screen.dart.
        final Widget gifSection = ExerciseHeroImage(
          gifUrl: exercise.gifUrl,
          exerciseId: exercise.id,
          height: 220,
          enableHero: !disableAnims,
        );

        return Scaffold(
          backgroundColor: surface.bgBase,
          appBar: AppBar(
            title: Text(
              exercise.name,
              style: AppText.sheetTitle(
                color: surface.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            backgroundColor: surface.bgBase,
            scrolledUnderElevation: 0,
            titleSpacing: 0,
            iconTheme: IconThemeData(color: surface.textPrimary),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // GIF/Hero lives outside _entryFade so the Hero can fly without
              // being wrapped in a FadeTransition (which would make the shuttle
              // fade in instead of flying).
              gifSection,

              const SizedBox(height: 16),

              // Text content and analytics fade in via the entry animation.
              EntranceFade(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Exercise Name & Metadata
                    Text(
                      exercise.name,
                      style: AppText.titleLarge(
                        color: surface.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      () {
                        final parent = MuscleTaxonomy.parentOf(exercise.target);
                        return parent == exercise.target || parent == 'Other'
                            ? exercise.equipment
                            : '$parent  •  ${exercise.equipment}';
                      }(),
                      style: AppText.body(
                        color: surface.textSecondary,
                      ).copyWith(
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Worked muscles: primary (accent) + secondary (muted) chips.
                    Builder(
                      builder: (_) {
                        final chips = <(String, bool)>[(exercise.target, true)];
                        try {
                          final sec =
                              (jsonDecode(exercise.secondaryMuscles ?? '[]')
                                      as List)
                                  .cast<String>();
                          for (final m in sec) {
                            if (m.trim().isNotEmpty) chips.add((m, false));
                          }
                        } catch (_) {/* malformed JSON — show primary only */}
                        final accent = context.accent;
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final (label, isPrimary) in chips)
                              MergeSemantics(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 11, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isPrimary
                                        ? accent.base.withValues(alpha: 0.12)
                                        : surface.surface3,
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.badge),
                                    border: Border.all(
                                      color: isPrimary
                                          ? accent.base.withValues(alpha: 0.35)
                                          : surface.borderSubtle,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    label,
                                    style: AppText.label(
                                      color: isPrimary
                                          ? accent.base
                                          : surface.textPrimary,
                                    ).copyWith(
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    historyAsync.when(
                      loading: () => _wrapPulse(
                        child: const Column(
                          children: [
                            SkeletonBox(height: 198, radius: AppRadius.card),
                            SizedBox(height: 24),
                            Row(
                              children: [
                                SkeletonBox(
                                    width: 120,
                                    height: 36,
                                    radius: AppRadius.buttonSecondary),
                                SizedBox(width: 8),
                                SkeletonBox(
                                    width: 100,
                                    height: 36,
                                    radius: AppRadius.buttonSecondary),
                                SizedBox(width: 8),
                                SkeletonBox(
                                    width: 90,
                                    height: 36,
                                    radius: AppRadius.buttonSecondary),
                              ],
                            ),
                            SizedBox(height: 24),
                            SkeletonBox(height: 150, radius: AppRadius.card),
                          ],
                        ),
                      ),
                      error: (err, _) => AsyncErrorState(
                        message: 'Failed to load analytics',
                        onRetry: () => ref.invalidate(exerciseAnalyticsProvider(
                            (widget.exerciseId, _selectedTimeRange))),
                      ),
                      data: (history) {
                        final isPremium = ref.watch(isPremiumProvider);
                        final visible = gateChartSamples(history, isPremium);
                        final mType = MeasurementType.fromString(
                            exercise.measurementType);
                        return Column(
                          children: [
                            _buildGraphSection(
                              visible,
                              mType: mType,
                              showProPill: !isPremium && history.length > 3,
                            ),
                            const SizedBox(height: 24),
                            _buildStatToggles(surface, mType),
                            if (history.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              _buildPersonalRecords(context, prs, mType),
                            ],
                            const SizedBox(height: 24),
                            _buildInstructions(exercise, surface),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPageSkeleton(BuildContext context) {
    final surface = context.surface;
    return Scaffold(
      backgroundColor: surface.bgBase,
      appBar: AppBar(
        backgroundColor: surface.bgBase,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: surface.textPrimary),
      ),
      body: _wrapPulse(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            SkeletonBox(height: 220, radius: AppRadius.card),
            SizedBox(height: 16),
            SkeletonBox(width: 180, height: 24, radius: AppRadius.card),
            SizedBox(height: 8),
            SkeletonBox(width: 120, height: 14, radius: AppRadius.card),
            SizedBox(height: 14),
            Row(
              children: [
                SkeletonBox(width: 80, height: 28, radius: AppRadius.badge),
                SizedBox(width: 8),
                SkeletonBox(width: 60, height: 28, radius: AppRadius.badge),
              ],
            ),
            SizedBox(height: 24),
            SkeletonBox(height: 198, radius: AppRadius.card),
            SizedBox(height: 24),
            Row(
              children: [
                SkeletonBox(
                    width: 120, height: 36, radius: AppRadius.buttonSecondary),
                SizedBox(width: 8),
                SkeletonBox(
                    width: 100, height: 36, radius: AppRadius.buttonSecondary),
                SizedBox(width: 8),
                SkeletonBox(
                    width: 90, height: 36, radius: AppRadius.buttonSecondary),
              ],
            ),
            SizedBox(height: 24),
            SkeletonBox(height: 150, radius: AppRadius.card),
          ],
        ),
      ),
    );
  }

  Widget _buildGraphSection(
    List<ExerciseHistoryData> history, {
    required MeasurementType mType,
    bool showProPill = false,
  }) {
    final toggles = _getToggleLabels(mType);
    final activeIndex =
        _activeToggleIndex < toggles.length ? _activeToggleIndex : 0;
    final activeLabel = toggles[activeIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                activeLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: RDStyles.sectionLabel,
              ),
            ),
            if (showProPill)
              const Padding(
                padding: EdgeInsets.only(right: 10),
                child: ProLockPill(label: 'FULL HISTORY'),
              ),
            TimeRangeFilter(
              value: _selectedTimeRange,
              onChanged: (range) => setState(() => _selectedTimeRange = range),
            ),
          ],
        ),
        const SizedBox(height: 12),
        RepaintBoundary(
          child: BrandedLineChart(
            key: ValueKey('$activeIndex|$_selectedTimeRange|${history.length}'),
            data: [
              for (final e in history)
                if (_metricForToggle(e, activeIndex, mType) != null)
                  ChartPoint(e.date, _metricForToggle(e, activeIndex, mType)!),
            ],
            valueFormatter: (v) => _formatChartValue(v, activeIndex, mType),
            emptyTitle: 'No data yet',
            emptySubtitle: 'Log this exercise to see your progress',
          ),
        ),
      ],
    );
  }

  String _formatChartValue(double v, int toggleIdx, MeasurementType mType) {
    switch (mType) {
      case MeasurementType.weightAndReps:
        if (toggleIdx == 3) return '${v.toInt()} reps';
        return '${v == v.truncateToDouble() ? v.toInt() : v.toStringAsFixed(1)} kg';
      case MeasurementType.repsOnly:
        return '${v.toInt()} reps';
      case MeasurementType.duration:
        final mins = v.toInt() ~/ 60;
        final secs = v.toInt() % 60;
        return '$mins:${secs.toString().padLeft(2, '0')}';
      case MeasurementType.distance:
        if (toggleIdx == 0) {
          final km = v / 1000.0;
          return km >= 1.0 ? '${km.toStringAsFixed(1)} km' : '${v.toInt()} m';
        } else if (toggleIdx == 1) {
          final mins = v.toInt() ~/ 60;
          final secs = v.toInt() % 60;
          return '$mins:${secs.toString().padLeft(2, '0')}';
        } else {
          final mins = v.toInt() ~/ 60;
          final secs = v.toInt() % 60;
          return '$mins:${secs.toString().padLeft(2, '0')} /km';
        }
    }
  }

  Widget _buildStatToggles(SurfaceTokens surface, MeasurementType mType) {
    final accent = context.accent;
    final toggles = _getToggleLabels(mType);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: toggles.asMap().entries.map((entry) {
          final isActive = entry.key == _activeToggleIndex;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Semantics(
              button: true,
              selected: isActive,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _activeToggleIndex = entry.key);
                },
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  alignment: Alignment.center,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    constraints: const BoxConstraints(minHeight: 48),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isActive ? accent.base : surface.bgSurface,
                      borderRadius:
                          BorderRadius.circular(AppRadius.buttonSecondary),
                    ),
                    child: Text(
                      entry.value,
                      style: AppText.statLabel(
                        color:
                            isActive ? accent.onAccent : surface.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPersonalRecords(
    BuildContext context,
    PersonalRecords prs,
    MeasurementType mType,
  ) {
    final surface = context.surface;
    final rows = <Widget>[];

    switch (mType) {
      case MeasurementType.weightAndReps:
        rows.addAll([
          _prRow(
              'Heaviest Weight',
              prs.maxWeight != null
                  ? '${prs.maxWeight == prs.maxWeight!.truncateToDouble() ? prs.maxWeight!.toInt() : prs.maxWeight!.toStringAsFixed(1)} kg'
                  : '—',
              surface),
          _prDivider(surface),
          _prRow(
              'Best 1RM',
              prs.max1RM != null
                  ? '${prs.max1RM == prs.max1RM!.truncateToDouble() ? prs.max1RM!.toInt() : prs.max1RM!.toStringAsFixed(1)} kg'
                  : '—',
              surface),
          _prDivider(surface),
          _prRow(
              'Max Session Volume',
              '${prs.maxVolume == prs.maxVolume.truncateToDouble() ? prs.maxVolume.toInt() : prs.maxVolume.toStringAsFixed(1)} kg',
              surface),
          _prDivider(surface),
          _prRow('Max Reps', '${prs.maxReps} reps', surface),
        ]);
        break;
      case MeasurementType.repsOnly:
        rows.addAll([
          _prRow('Max Reps', '${prs.maxReps} reps', surface),
          _prDivider(surface),
          _prRow('Max Session Reps', '${prs.maxReps} reps', surface),
        ]);
        break;
      case MeasurementType.duration:
        final secs = prs.maxDuration;
        final mins = secs ~/ 60;
        final s = secs % 60;
        final durStr = '$mins:${s.toString().padLeft(2, '0')}';
        rows.addAll([
          _prRow('Max Duration', durStr, surface),
        ]);
        break;
      case MeasurementType.distance:
        final dist = prs.maxDistance;
        final distKm = dist / 1000.0;
        final distStr = (distKm >= 1.0)
            ? '${distKm.toStringAsFixed(1)} km'
            : '${dist.toInt()} m';
        rows.addAll([
          _prRow('Max Distance', distStr, surface),
        ]);
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.emoji_events_rounded,
              color: AppColors.warning,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'Personal Records',
              style: AppText.cardTitle(
                color: surface.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: surface.bgSurface,
            borderRadius: AppRadius.cardAll,
          ),
          child: Column(children: rows),
        ),
      ],
    );
  }

  Widget _prRow(String label, String value, SurfaceTokens surface) {
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Text(
              label,
              style: AppText.body(
                color: surface.textSecondary,
              ).copyWith(
                fontSize: 14,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: AppText.rowLabel(
                color: surface.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _prDivider(SurfaceTokens surface) {
    return Divider(
      color: surface.borderSubtle,
      height: 1,
      indent: 16,
      endIndent: 16,
    );
  }

  Widget _buildInstructions(Exercise exercise, SurfaceTokens surface) {
    if (exercise.instructions == null || exercise.instructions!.isEmpty) {
      return const SizedBox.shrink();
    }

    List<String> steps;
    try {
      steps =
          (jsonDecode(exercise.instructions!) as List<dynamic>).cast<String>();
    } catch (_) {
      return const SizedBox.shrink();
    }

    if (steps.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.list_alt_rounded,
                color: surface.textSecondary, size: 20),
            const SizedBox(width: 8),
            Text(
              'How to Perform',
              style: AppText.cardTitle(
                color: surface.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: surface.bgSurface,
            borderRadius: AppRadius.cardAll,
          ),
          child: Column(
            children: steps.asMap().entries.map((entry) {
              final isLast = entry.key == steps.length - 1;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: surface.surface3,
                            borderRadius: AppRadius.badgeAll,
                          ),
                          child: Center(
                            child: Text(
                              '${entry.key + 1}',
                              style: AppText.badge(
                                color: surface.textSecondary,
                              ).copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: AppText.body(
                              color: surface.textPrimary,
                            ).copyWith(
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      color: surface.borderSubtle,
                      height: 1,
                      indent: 52,
                      endIndent: 16,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
