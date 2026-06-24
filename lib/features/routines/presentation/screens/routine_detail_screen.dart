import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import 'package:gymlog/core/database/daos/routines_dao.dart';
import 'package:gymlog/core/database/daos/workouts_dao.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import 'package:gymlog/core/providers/premium_provider.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/utils/relative_time.dart';
import 'package:gymlog/core/utils/tap_guard.dart';
import 'package:gymlog/core/utils/units.dart';
import 'package:gymlog/features/workout/domain/active_workout_state.dart';
import 'package:gymlog/features/workout/presentation/providers/active_workout_provider.dart';
import 'package:gymlog/shared/widgets/async_error_state.dart';
import 'package:gymlog/shared/widgets/premium_paywall.dart';
import 'package:gymlog/shared/widgets/ui/action_bottom_sheet.dart';
import 'package:gymlog/shared/widgets/ui/app_card.dart';
import 'package:gymlog/shared/widgets/ui/app_dialog.dart';
import 'package:gymlog/shared/widgets/ui/secondary_button.dart';
import 'package:gymlog/shared/widgets/ui/skeleton.dart';
import 'package:gymlog/shared/widgets/ui/time_range_filter.dart';
import '../providers/routines_provider.dart';
import '../widgets/routine_exercise_block.dart';
import '../widgets/routine_volume_graph.dart';

/// Hoisted once — constructing a [DateFormat] parses its pattern, so it must not
/// be rebuilt per frame.
final DateFormat _monthDay = DateFormat('MMM d');

/// RoutineDetailScreen — the launchpad for a saved routine: one dominant Start
/// CTA, a personal stat line, a volume trend, and the exercise set tables.
class RoutineDetailScreen extends ConsumerStatefulWidget {
  final String routineId;

  const RoutineDetailScreen({super.key, required this.routineId});

  @override
  ConsumerState<RoutineDetailScreen> createState() =>
      _RoutineDetailScreenState();
}

class _RoutineDetailScreenState extends ConsumerState<RoutineDetailScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryController;
  bool _entryStarted = false;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entryStarted) return;
    _entryStarted = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _entryController.value = 1.0;
    } else {
      _entryController.forward();
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  void _startRoutine(HydratedRoutineDetail routine) {
    if (!tapGuard()) return; // no double-push / double session reset
    if (routine.exercises.isEmpty) {
      // Empty routine: route to the editor to add exercises rather than start a
      // contentless workout. Push directly — tapGuard was already consumed.
      context.push('/routines/edit?id=${widget.routineId}');
      return;
    }
    final exercises = routine.exercises.map((he) {
      final config = he.config;
      final sets = List.generate(
        config.defaultSets,
        (_) => WorkoutSetState(
          id: const Uuid().v4(),
          weightKg: config.defaultWeightKg ?? 0.0,
          reps: config.defaultReps ?? 0,
        ),
      );
      return WorkoutExerciseState(
        id: const Uuid().v4(),
        exerciseId: he.exercise.id,
        name: he.exercise.name,
        sets: sets.isEmpty ? [WorkoutSetState.create()] : sets,
      );
    }).toList();

    ref.read(activeWorkoutProvider.notifier).startWorkout(
          routineId: routine.routine.id,
          name: routine.routine.name,
          initialExercises: exercises,
        );
    context.push('/workout/active');
  }

  Future<void> _deleteRoutine(String routineId) async {
    final db = ref.read(databaseProvider);
    context.pop(); // pop screen immediately
    await db.routinesDao.deleteRoutine(routineId);
  }

  void _openEditor() {
    if (!tapGuard()) return;
    HapticFeedback.selectionClick();
    context.push('/routines/edit?id=${widget.routineId}');
  }

  Future<void> _addExercise() async {
    if (!tapGuard()) return;
    HapticFeedback.lightImpact();
    final selected = await context.push<Exercise>('/exercises/select');
    if (selected == null || !mounted) return;
    await ref
        .read(databaseProvider)
        .routinesDao
        .addExerciseToRoutine(widget.routineId, selected.id);
  }

  Future<void> _shareRoutine(HydratedRoutineDetail routine) async {
    final b = StringBuffer()
      ..writeln(routine.routine.name)
      ..writeln();
    for (final he in routine.exercises) {
      final c = he.config;
      final reps = c.defaultReps != null ? ' × ${c.defaultReps}' : '';
      b.writeln('• ${he.exercise.name} — ${c.defaultSets} sets$reps');
    }
    b
      ..writeln()
      ..write('Shared from GymLog');
    await SharePlus.instance.share(
      ShareParams(text: b.toString(), subject: routine.routine.name),
    );
  }

  void _showActions(HydratedRoutineDetail routine) {
    showActionBottomSheet(
      context: context,
      title: routine.routine.name,
      items: [
        ActionSheetItem(
          icon: Icons.edit_rounded,
          iconColor: AppColors.textSecondary,
          iconBackground: AppColors.bgBase,
          title: 'Edit Routine',
          onTap: (ctx) {
            Navigator.of(ctx).pop();
            _openEditor();
          },
        ),
        ActionSheetItem(
          icon: Icons.share_rounded,
          iconColor: AppColors.textSecondary,
          iconBackground: AppColors.bgBase,
          title: 'Share Routine',
          onTap: (ctx) {
            Navigator.of(ctx).pop();
            _shareRoutine(routine);
          },
        ),
        ActionSheetItem(
          icon: Icons.delete_outline_rounded,
          iconColor: AppColors.error,
          iconBackground: AppColors.error.withValues(alpha: 0.12),
          title: 'Delete Routine',
          titleColor: AppColors.error,
          subtitle: 'This cannot be undone',
          subtitleColor: AppColors.error.withValues(alpha: 0.7),
          onTap: (ctx) {
            Navigator.of(ctx).pop();
            _confirmDelete(routine.routine.id);
          },
        ),
      ],
    );
  }

  Future<void> _confirmDelete(String routineId) async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Delete Routine?',
      message:
          'This routine will be permanently deleted. Your workout history stays.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (confirmed) {
      HapticFeedback.heavyImpact();
      await _deleteRoutine(routineId);
    }
  }

  Future<void> _onRefresh() async {
    ref.invalidate(routineDetailProvider(widget.routineId));
    ref.invalidate(routineDailyVolumeProvider);
    ref.invalidate(routineLastSetsProvider(widget.routineId));
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final routineAsync = ref.watch(routineDetailProvider(widget.routineId));
    return routineAsync.when(
      loading: _buildSkeleton,
      error: (_, __) => _buildError(),
      data: (routine) =>
          routine == null ? _buildNotFound() : _buildLoaded(routine),
    );
  }

  Widget _buildLoaded(HydratedRoutineDetail routine) {
    final lastSetsAsync = ref.watch(routineLastSetsProvider(widget.routineId));
    final isPremium = ref.watch(isPremiumProvider);
    final sessionStats =
        ref.watch(routineSessionStatsProvider(widget.routineId)).valueOrNull;

    final lastSetsMap = lastSetsAsync.valueOrNull ??
        const <String, List<LastSessionSetData>>{};
    final isLoadingHistory =
        lastSetsAsync.isLoading && lastSetsAsync.valueOrNull == null;

    final exerciseCount = routine.exercises.length;
    final lastDate = ref.watch(routineDailyVolumeProvider((widget.routineId, 'All Time'))
        .select((asyncVal) => asyncVal.valueOrNull == null || asyncVal.valueOrNull!.isEmpty
            ? null
            : asyncVal.valueOrNull!.last.day));
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: RefreshIndicator(
        color: AppColors.textPrimary,
        backgroundColor: AppColors.surface2,
        onRefresh: _onRefresh,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            _appBar(routine),

            // Attribution + stat line (without Start CTA).
            SliverToBoxAdapter(
              child: _entryFade(
                interval: const Interval(0.0, 0.32, curve: Curves.easeOutExpo),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$exerciseCount exercise${exerciseCount != 1 ? 's' : ''}'
                        '${lastDate != null ? ' · Last performed ${relativeDay(lastDate)}' : ''}',
                        style: AppText.meta(),
                      ),
                      if (sessionStats != null && sessionStats.count > 0) ...[
                        const SizedBox(height: 16),
                        _HeroStatStrip(stats: sessionStats),
                      ],
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),

            // Volume trend.
            SliverToBoxAdapter(
              child: _entryFade(
                interval: const Interval(0.2, 0.5, curve: Curves.easeOutExpo),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _RoutineVolumeSection(
                    routineId: widget.routineId,
                    isPremium: isPremium,
                  ),
                ),
              ),
            ),

            // Exercises.
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final exercise = routine.exercises[index];
                    final sets = lastSetsMap[exercise.exercise.id.toString()];
                    final delay = index.clamp(0, 3) * 0.05;
                    return _entryFade(
                      interval: Interval(
                        (0.4 + delay).clamp(0.0, 0.9),
                        (0.6 + delay).clamp(0.0, 1.0),
                        curve: Curves.easeOutExpo,
                      ),
                      child: RoutineExerciseBlock(
                        hydratedExercise: exercise,
                        lastSets: sets,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          context.push(
                            '/exercise/detail/${exercise.exercise.id}',
                            extra: exercise.exercise,
                          );
                        },
                        isLoadingHistory: isLoadingHistory,
                        isLast: index == routine.exercises.length - 1,
                      ),
                    );
                  },
                  childCount: routine.exercises.length,
                ),
              ),
            ),

            // Add exercise.
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: SecondaryButton(
                  label: 'Add Exercise',
                  icon: Icons.add_rounded,
                  onPressed: _addExercise,
                ),
              ),
            ),

            SliverToBoxAdapter(child: SizedBox(height: 80 + bottomInset)),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Semantics(
            button: true,
            label: routine.exercises.isEmpty
                ? 'Add an exercise to start'
                : 'Start Routine',
            child: _StartRoutineButton(
              empty: routine.exercises.isEmpty,
              onTap: () => _startRoutine(routine),
            ),
          ),
        ),
      ),
    );
  }

  Widget _appBar(HydratedRoutineDetail routine) {
    return SliverAppBar(
      pinned: true,
      toolbarHeight: 56,
      backgroundColor: AppColors.bgBase,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      centerTitle: false,
      title: Text(
        routine.routine.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppText.sectionHeading(),
      ),
      leading: IconButton(
        tooltip: 'Back',
        icon: const Icon(Icons.arrow_back_rounded,
            size: 24, color: AppColors.textPrimary),
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          tooltip: 'Routine options',
          icon: const Icon(Icons.more_horiz_rounded,
              size: 24, color: AppColors.textPrimary),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: () => _showActions(routine),
        ),
      ],
    );
  }

  /// Shared fade + rise entry. Composited using FadeTransition and SlideTransition
  /// to avoid expensive saveLayer rendering on every animation frame.
  Widget _entryFade({required Interval interval, required Widget child}) {
    final curvedAnimation = CurvedAnimation(
      parent: _entryController,
      curve: interval,
    );
    return FadeTransition(
      opacity: curvedAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.05), // Translate 5% down
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: child,
      ),
    );
  }

  // ── Loading / error / not-found (each owns ONE Scaffold — no nesting) ──────

  Widget _buildSkeleton() {
    return SkeletonPulse(
      child: Scaffold(
        backgroundColor: AppColors.bgBase,
        body: CustomScrollView(
          physics: const NeverScrollableScrollPhysics(),
          slivers: [
            const SliverAppBar(
              pinned: true,
              toolbarHeight: 56,
              backgroundColor: AppColors.bgBase,
              surfaceTintColor: Colors.transparent,
              scrolledUnderElevation: 0,
              elevation: 0,
              automaticallyImplyLeading: false,
              titleSpacing: 0,
              title: SizedBox.shrink(),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SkeletonBox(width: 200, height: 16),
                    const SizedBox(height: 24),
                    const SkeletonBox(height: 198, radius: 6),
                    const SizedBox(height: 24),
                    ...List.generate(
                      3,
                      (i) => const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: SkeletonBox(height: 120, radius: 6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: const SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: SkeletonBox(height: 52, radius: 6),
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgBase,
        scrolledUnderElevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textPrimary),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: () => context.pop(),
        ),
      ),
      body: AsyncErrorState(
        message: "Couldn't load this routine.",
        onRetry: _onRefresh,
      ),
    );
  }

  Widget _buildNotFound() {
    return const AppNotFoundScreen(
      title: 'Routine not found',
      message: 'It may have been deleted.',
    );
  }
}

class _RoutineVolumeSection extends ConsumerStatefulWidget {
  final String routineId;
  final bool isPremium;

  const _RoutineVolumeSection({
    required this.routineId,
    required this.isPremium,
  });

  @override
  ConsumerState<_RoutineVolumeSection> createState() => _RoutineVolumeSectionState();
}

class _RoutineVolumeSectionState extends ConsumerState<_RoutineVolumeSection> {
  String _selectedTimeRange = 'All Time';

  @override
  Widget build(BuildContext context) {
    final volumeAsync = ref.watch(
        routineDailyVolumeProvider((widget.routineId, _selectedTimeRange)));
    final allSamples = volumeAsync.valueOrNull ?? const <DailyVolumeSample>[];
    final visible = gateChartSamples(allSamples, widget.isPremium);
    final hasTrend = allSamples.length >= 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Semantics(
                header: true,
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: 'Total Volume ', style: AppText.cardTitle()),
                    TextSpan(text: '(kg)', style: AppText.meta()),
                  ]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (hasTrend)
              Row(
                children: [
                  if (!widget.isPremium && allSamples.length > 3)
                    const Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: ProLockPill(label: 'FULL HISTORY'),
                    ),
                  TimeRangeFilter(
                    value: _selectedTimeRange,
                    onChanged: (range) =>
                        setState(() => _selectedTimeRange = range),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 12),
        RepaintBoundary(
          child: volumeAsync.when(
            loading: () => Container(
              height: 198,
              decoration: AppCard.decoration(radius: AppRadius.card),
              child: const Center(
                child:
                    CircularProgressIndicator(color: AppColors.textSecondary),
              ),
            ),
            error: (_, __) => const RoutineVolumeGraph(data: []),
            data: (_) => AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: RoutineVolumeGraph(
                key: ValueKey('$_selectedTimeRange${visible.length}'),
                data: visible,
              ),
            ),
          ),
        ),
        _RoutineProgressPill(samples: visible),
        const SizedBox(height: 28),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Sub-widgets
// ══════════════════════════════════════════════════════════════════════════════

/// Personal "scoreboard" for this routine — sessions, best and average volume.
/// Aggregates (counts), distinct from the chart's per-session trend.
class _HeroStatStrip extends StatelessWidget {
  final RoutineSessionStats stats;
  const _HeroStatStrip({required this.stats});

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Row(
        children: [
          Expanded(
              child: _HeroStat(value: '${stats.count}', label: 'SESSIONS')),
          const _StatDivider(),
          Expanded(
              child: _HeroStat(
                  value: groupThousands(stats.bestVolumeKg), label: 'BEST KG')),
          const _StatDivider(),
          Expanded(
              child: _HeroStat(
                  value: groupThousands(stats.avgVolumeKg), label: 'AVG KG')),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();
  @override
  Widget build(BuildContext context) => Container(
      width: 1, height: 26, color: AppColors.borderSubtle);
}

class _HeroStat extends StatelessWidget {
  final String value;
  final String label;
  const _HeroStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, style: AppText.heroStat(), maxLines: 1),
        ),
        const SizedBox(height: 3),
        Text(label, style: AppText.columnHeader(color: AppColors.textSecondary)),
      ],
    );
  }
}

/// The single dominant CTA — bespoke for its signature glow + press-scale, but
/// on-system (52dp, [AppRadius.buttonPrimary]). Falls back to "Add exercise"
/// for an empty routine instead of starting a contentless workout.
class _StartRoutineButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool empty;

  const _StartRoutineButton({required this.onTap, required this.empty});

  @override
  State<_StartRoutineButton> createState() => _StartRoutineButtonState();
}

class _StartRoutineButtonState extends State<_StartRoutineButton> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails _) => setState(() => _scale = 0.97);
  void _onTapUp(TapUpDetails _) => setState(() => _scale = 1.0);
  void _onTapCancel() => setState(() => _scale = 1.0);

  void _onTap() {
    if (widget.empty) {
      HapticFeedback.lightImpact();
    } else {
      // Peak-intent moment — a heavier confirmation than a normal tap.
      HapticFeedback.heavyImpact();
    }
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final empty = widget.empty;
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: _onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutQuint,
        child: Container(
          height: 52,
          width: double.infinity,
          decoration: BoxDecoration(
            color: empty ? AppColors.surface3 : AppColors.accentPrimary,
            borderRadius: AppRadius.buttonPrimaryAll,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(empty ? Icons.add_rounded : Icons.play_arrow_rounded,
                  color: empty ? AppColors.textSecondary : AppColors.textPrimary,
                  size: 22),
              const SizedBox(width: 8),
              Text(
                empty ? 'Add an exercise' : 'Start Routine',
                style: AppText.button(
                    color: empty ? AppColors.textSecondary : AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoutineProgressPill extends StatelessWidget {
  final List<DailyVolumeSample> samples;

  const _RoutineProgressPill({required this.samples});

  @override
  Widget build(BuildContext context) {
    if (samples.length < 2) return const SizedBox.shrink();

    final first = samples.first.volume;
    final latest = samples.last.volume;
    if (first == 0) return const SizedBox.shrink();

    final delta = ((latest - first) / first * 100).round();
    final isUp = delta >= 0;

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surface3,
            borderRadius: BorderRadius.circular(AppRadius.badge),
            border: Border.all(
              color: AppColors.borderSubtle,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                isUp
                    ? 'Volume up $delta% since ${_monthDay.format(samples.first.day)}'
                    : 'Volume down ${-delta}% since ${_monthDay.format(samples.first.day)}',
                style: AppText.statLabel(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
