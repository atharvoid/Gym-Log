import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import 'package:gymlog/core/database/daos/routines_dao.dart';
import 'package:gymlog/core/database/daos/workouts_dao.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import 'package:gymlog/core/providers/premium_provider.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/core/utils/relative_time.dart';
import 'package:gymlog/core/utils/tap_guard.dart';
import 'package:gymlog/core/utils/units.dart';
import 'package:gymlog/features/workout/domain/active_workout_state.dart';
import 'package:gymlog/features/workout/presentation/providers/active_workout_provider.dart';
import 'package:gymlog/shared/widgets/async_error_state.dart';
import 'package:gymlog/shared/widgets/premium_paywall.dart';
import 'package:gymlog/shared/widgets/ui/action_bottom_sheet.dart';
import 'package:gymlog/shared/widgets/ui/app_dialog.dart';
import 'package:gymlog/shared/widgets/feedback/undoable_delete.dart';
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

  // ── Actions ─────────────────────────────────────────────────────────────────

  void _startRoutine(HydratedRoutineDetail routine) {
    if (!tapGuard()) return;
    if (routine.exercises.isEmpty) {
      context.push('/routines/edit?id=${widget.routineId}');
      return;
    }

    ref.read(activeWorkoutProvider.notifier).startWorkout(
          routineId: routine.routine.id,
          name: routine.routine.name,
          initialExercises: seedExercisesFromRoutine(routine),
        );
    context.push('/workout/active');
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
    final surface = context.surface;
    showActionBottomSheet(
      context: context,
      title: routine.routine.name,
      items: [
        ActionSheetItem(
          icon: Icons.edit_rounded,
          iconColor: surface.textSecondary,
          iconBackground: surface.bgBase,
          title: 'Edit Routine',
          onTap: (ctx) {
            Navigator.of(ctx).pop();
            _openEditor();
          },
        ),
        ActionSheetItem(
          icon: Icons.share_rounded,
          iconColor: surface.textSecondary,
          iconBackground: surface.bgBase,
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
    if (!tapGuard()) return;
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Delete Routine?',
      message:
          'This routine will be permanently deleted. Your workout history stays.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;

    final db = ref.read(databaseProvider);

    // Capture the JSON representation of the routine before delete
    final data = await db.routinesDao.exportRoutineJson(routineId);
    if (data == null) return;

    if (!mounted) return;

    // RD-4 discipline: capture messenger and router BEFORE popping
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    HapticFeedback.mediumImpact();

    await db.routinesDao.deleteRoutine(routineId);
    router.pop();

    showUndoableDelete(
      messenger: messenger,
      label: 'Routine deleted',
      onUndo: () async {
        await db.routinesDao.restoreRoutine(data);
      },
    );
  }

  Future<void> _onRefresh() async {
    ref.invalidate(routineDetailProvider(widget.routineId));
    ref.invalidate(routineDailyVolumeProvider);
    ref.invalidate(routineLastSetsProvider(widget.routineId));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

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

    final lastSetsMap =
        lastSetsAsync.valueOrNull ?? const <String, List<LastSessionSetData>>{};
    final isLoadingHistory =
        lastSetsAsync.isLoading && lastSetsAsync.valueOrNull == null;

    final exerciseCount = routine.exercises.length;
    final lastDate = ref.watch(
        routineDailyVolumeProvider((widget.routineId, '6M')).select(
            (asyncVal) =>
                asyncVal.valueOrNull == null || asyncVal.valueOrNull!.isEmpty
                    ? null
                    : asyncVal.valueOrNull!.last.day));
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final surface = context.surface;

    final seen = <int>{};
    final heroEnabledList = <bool>[];
    for (final exercise in routine.exercises) {
      heroEnabledList.add(seen.add(exercise.exercise.id));
    }

    return Scaffold(
      backgroundColor: surface.bgBase,
      body: RefreshIndicator(
        color: context.accent.base,
        backgroundColor: surface.surface2,
        onRefresh: _onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _appBar(routine),
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
                        enableHero: heroEnabledList[index],
                      ),
                    );
                  },
                  childCount: routine.exercises.length,
                ),
              ),
            ),
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
    final surface = context.surface;
    return SliverAppBar(
      pinned: true,
      toolbarHeight: 56,
      backgroundColor: surface.bgBase,
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
        // S3: text-depth shadow on routine detail title
        style: AppText.sectionHeading(shadows: AppText.depthFor(context)),
      ),
      leading: IconButton(
        tooltip: 'Back',
        icon: Icon(Icons.arrow_back_rounded,
            size: 24, color: surface.textPrimary),
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        onPressed: () => context.pop(),
      ),
      actions: [
        // S13: standardized to more_horiz_rounded + showActionBottomSheet
        IconButton(
          tooltip: 'More options',
          icon: Icon(Icons.more_horiz_rounded,
              size: 24, color: surface.textPrimary),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: () => _showActions(routine),
        ),
      ],
    );
  }

  Widget _entryFade({required Interval interval, required Widget child}) {
    final curvedAnimation = CurvedAnimation(
      parent: _entryController,
      curve: interval,
    );
    return FadeTransition(
      opacity: curvedAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: child,
      ),
    );
  }

  // ── Loading / error / not-found ──────────────────────────────────────────────

  Widget _buildSkeleton() {
    final surface = context.surface;
    return SkeletonPulse(
      child: Scaffold(
        backgroundColor: surface.bgBase,
        body: CustomScrollView(
          physics: const NeverScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              toolbarHeight: 56,
              backgroundColor: surface.bgBase,
              surfaceTintColor: Colors.transparent,
              scrolledUnderElevation: 0,
              elevation: 0,
              automaticallyImplyLeading: false,
              titleSpacing: 0,
              title: const SizedBox.shrink(),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SkeletonBox(width: 200, height: 16),
                    const SizedBox(height: 24),
                    const SkeletonBox(height: 198, radius: AppRadius.card),
                    const SizedBox(height: 24),
                    ...List.generate(
                      3,
                      (i) => const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: SkeletonBox(height: 120, radius: AppRadius.card),
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
            child: SkeletonBox(height: 52, radius: AppRadius.buttonPrimary),
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    final surface = context.surface;
    return Scaffold(
      backgroundColor: surface.bgBase,
      appBar: AppBar(
        backgroundColor: surface.bgBase,
        scrolledUnderElevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: Icon(Icons.arrow_back_rounded, color: surface.textPrimary),
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
  ConsumerState<_RoutineVolumeSection> createState() =>
      _RoutineVolumeSectionState();
}

class _RoutineVolumeSectionState extends ConsumerState<_RoutineVolumeSection> {
  String _selectedTimeRange = '6M';

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
            loading: () => const SkeletonPulse(
              child: SkeletonBox(
                height: 198,
                radius: AppRadius.card,
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

// ════════════════════════════════════════════════════════════════════════════
// Sub-widgets
// ══════════════════════════════════════════════════════════════════════════════

class _HeroStatStrip extends StatelessWidget {
  final RoutineSessionStats stats;
  const _HeroStatStrip({required this.stats});

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Row(
        children: [
          Expanded(
              child: _HeroStat(
                  value: '${stats.count}',
                  label: 'SESSIONS',
                  shadows: AppText.depthFor(context))),
          const _StatDivider(),
          Expanded(
              child: _HeroStat(
                  value: groupThousands(stats.bestVolumeKg),
                  label: 'BEST KG',
                  shadows: AppText.depthFor(context))),
          const _StatDivider(),
          Expanded(
              child: _HeroStat(
                  value: groupThousands(stats.avgVolumeKg),
                  label: 'AVG KG',
                  shadows: AppText.depthFor(context))),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 26, color: context.surface.borderSubtle);
}

class _HeroStat extends StatelessWidget {
  final String value;
  final String label;
  final List<Shadow>? shadows;
  const _HeroStat({required this.value, required this.label, this.shadows});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value,
              style: AppText.heroStat(shadows: shadows), maxLines: 1),
        ),
        const SizedBox(height: 3),
        Text(label,
            style: AppText.columnHeader(color: context.surface.textSecondary)),
      ],
    );
  }
}

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
      HapticFeedback.heavyImpact();
    }
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final empty = widget.empty;
    final surface = context.surface;
    final accent = context.accent;
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
            color: empty ? surface.surface3 : accent.base,
            borderRadius: AppRadius.buttonPrimaryAll,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(empty ? Icons.add_rounded : Icons.play_arrow_rounded,
                  color: empty ? surface.textSecondary : accent.onAccent,
                  size: 22),
              const SizedBox(width: 8),
              Text(
                empty ? 'Add an exercise' : 'Start Routine',
                style: AppText.button(
                    color: empty ? surface.textSecondary : accent.onAccent),
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
    final surface = context.surface;

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: surface.surface3,
            borderRadius: AppRadius.badgeAll,
            border: Border.all(
              color: surface.borderSubtle,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                size: 14,
                color: surface.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                isUp
                    ? 'Volume up $delta% since ${_monthDay.format(samples.first.day)}'
                    : 'Volume down ${-delta}% since ${_monthDay.format(samples.first.day)}',
                style: AppText.statLabel(color: surface.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
