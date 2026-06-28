import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/utils/formatters.dart';
import 'package:gymlog/core/database/daos/workouts_dao.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import 'package:gymlog/shared/widgets/async_error_state.dart';
import 'package:gymlog/shared/widgets/ui/app_card.dart';
import 'package:gymlog/shared/widgets/ui/skeleton.dart';
import 'package:gymlog/shared/widgets/ui/action_bottom_sheet.dart';
import 'package:gymlog/shared/widgets/ui/app_dialog.dart';
import 'package:gymlog/features/workout/presentation/widgets/workout_detail/hero_sliver.dart';
import 'package:gymlog/features/workout/presentation/widgets/workout_detail/muscle_split_section.dart';
import 'package:gymlog/features/workout/presentation/widgets/workout_detail/detail_exercise_card.dart';
import '../providers/workout_detail_provider.dart';
import '../providers/workout_actions_provider.dart';
import '../providers/active_workout_provider.dart';
import 'package:gymlog/core/utils/tap_guard.dart';
import 'package:gymlog/shared/widgets/feedback/undoable_delete.dart';
import 'package:gymlog/shared/widgets/motion/entrance_fade.dart';

/// Hoisted, locale-stable date formatter ("Thu, 18 Jun 2026").
final _kDateFormat = DateFormat('EEE, d MMM yyyy');

/// [workout_detail_screen.dart]
/// Read-only detail of a completed workout. Composed from extracted widgets:
///   WorkoutHeroSliver → MuscleSplitSection → DetailExerciseCard list.
class WorkoutDetailScreen extends ConsumerWidget {
  final String sessionId;
  const WorkoutDetailScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutAsync = ref.watch(workoutDetailProvider(sessionId));
    final surface = context.surface;

    return Scaffold(
      backgroundColor: surface.bgBase,
      body: workoutAsync.when(
        loading: () => _buildLoading(context),
        error: (e, _) => _buildError(context, ref),
        data: (workout) {
          if (workout == null) return _buildNotFound();
          return _buildScrollView(context, ref, workout);
        },
      ),
    );
  }

  // ── State shells ───────────────────────────────────────────────────────────

  Widget _buildLoading(BuildContext context) => Scaffold(
        backgroundColor: context.surface.bgBase,
        appBar: AppBar(
          backgroundColor: context.surface.bgBase,
          scrolledUnderElevation: 0,
          leading: BackButton(color: context.surface.textPrimary),
        ),
        body: SkeletonPulse(
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: const [
              SkeletonBox(width: 180, height: 24),
              SizedBox(height: 8),
              SkeletonBox(width: 120, height: 13),
              SizedBox(height: 24),
              SkeletonBox(height: 8, radius: AppRadius.badge),
              SizedBox(height: 20),
              _DetailCardSkeleton(),
              SizedBox(height: 12),
              _DetailCardSkeleton(),
            ],
          ),
        ),
      );

  Widget _buildError(BuildContext context, WidgetRef ref) => Scaffold(
        backgroundColor: context.surface.bgBase,
        appBar: AppBar(
          backgroundColor: context.surface.bgBase,
          scrolledUnderElevation: 0,
          leading: BackButton(color: context.surface.textPrimary),
        ),
        body: AsyncErrorState(
          message:
              "Couldn't load this workout. Your data is safe on this device.",
          onRetry: () {
            HapticFeedback.lightImpact();
            ref.invalidate(workoutDetailProvider(sessionId));
          },
        ),
      );

  Widget _buildNotFound() => const AppNotFoundScreen(
        title: 'Workout not found',
        message: 'It may have been deleted.',
      );

  // ── Main scroll view ─────────────────────────────────────────────────────────

  Widget _buildScrollView(
    BuildContext context,
    WidgetRef ref,
    HydratedWorkout workout,
  ) {
    final session = workout.session;
    final name = getWorkoutNameFallback(session.startedAt, session.name);
    final durationStr =
        formatWorkoutDuration(session.startedAt, session.endedAt);
    final totalSets =
        workout.exercises.fold<int>(0, (s, e) => s + e.sets.length);
    final volumeStr = _formatVolume(session.totalVolumeKg);
    final dateStr = _kDateFormat.format(session.startedAt);

    // Muscle split — sets-per-target share.
    final muscleSetCounts = <String, int>{};
    for (final ex in workout.exercises) {
      final target = ex.exerciseMetadata.target;
      muscleSetCounts[target] = (muscleSetCounts[target] ?? 0) + ex.sets.length;
    }

    final seen = <int>{};
    final heroEnabledList = <bool>[];
    for (final ex in workout.exercises) {
      heroEnabledList.add(seen.add(ex.exerciseMetadata.id));
    }

    // ConstrainedBox keeps the column readable on tablets/foldables (this
    // screen is pushed outside the shell, which caps width at 600 elsewhere).
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        // Physics intentionally unset → platform-aware via ScrollConfiguration
        // (iOS bounce, Android stretch). Was hardcoded BouncingScrollPhysics.
        child: CustomScrollView(
          slivers: [
            WorkoutHeroSliver(
              name: name,
              dateStr: dateStr,
              durationStr: durationStr,
              volumeStr: volumeStr,
              totalSets: totalSets,
              onMoreTap: () => _showActions(context, ref, workout),
            ),
            SliverToBoxAdapter(
              child: EntranceFade(
                index: 0,
                child: MuscleSplitSection(muscleSetCounts: muscleSetCounts),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverList(
              delegate: SliverChildListDelegate([
                for (int i = 0; i < workout.exercises.length; i++)
                  EntranceFade(
                    key: ValueKey(workout.exercises[i].workoutExercise.id),
                    index: 1 + i,
                    child: DetailExerciseCard(
                      hydratedExercise: workout.exercises[i],
                      enableHero: heroEnabledList[i],
                    ),
                  ),
              ]),
            ),
            SliverToBoxAdapter(
              child:
                  SizedBox(height: 24 + MediaQuery.paddingOf(context).bottom),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  static final _volumeFormat = NumberFormat('#,##0.##');

  static String _formatVolume(double kg) {
    return '${_volumeFormat.format(kg)} kg';
  }

  void _saveAsRoutine(
    BuildContext context,
    WidgetRef ref,
    HydratedWorkout workout,
  ) async {
    final defaultName = '${workout.session.name ?? 'Custom'} Routine';
    await ref
        .read(workoutActionsProvider.notifier)
        .saveWorkoutAsRoutine(workout, defaultName);
    if (context.mounted) {
      final surface = context.surface;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved as "$defaultName"',
              style: AppText.body(color: surface.textPrimary)),
          backgroundColor: surface.surface2,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showActions(
    BuildContext context,
    WidgetRef ref,
    HydratedWorkout workout,
  ) {
    final title = getWorkoutNameFallback(
      workout.session.startedAt,
      workout.session.name,
    );

    showActionBottomSheet(
      context: context,
      title: title,
      items: [
        ActionSheetItem(
          icon: Icons.bookmark_outline_rounded,
          iconColor: context.surface.textSecondary,
          iconBackground: context.surface.surface3,
          title: 'Save as Template',
          subtitle: 'Add to your routine library',
          onTap: (sheetContext) {
            Navigator.of(sheetContext).pop();
            _saveAsRoutine(context, ref, workout);
          },
        ),
        ActionSheetItem(
          icon: Icons.edit_outlined,
          iconColor: context.surface.textSecondary,
          iconBackground: context.surface.bgBase,
          title: 'Edit Workout',
          subtitle: 'Rename or adjust notes',
          onTap: (sheetContext) async {
            Navigator.of(sheetContext).pop();
            final db = ref.read(databaseProvider);
            final hydrated =
                await db.workoutsDao.getHydratedWorkout(workout.session.id);
            if (hydrated == null) return;
            if (!context.mounted) return;
            HapticFeedback.lightImpact();
            ref.read(activeWorkoutProvider.notifier).loadForEdit(hydrated);
            context.push('/workout/active');
          },
        ),
        ActionSheetItem(
          icon: Icons.delete_outline_rounded,
          iconColor: AppColors.error,
          iconBackground: AppColors.error.withValues(alpha: 0.12),
          title: 'Delete Workout',
          titleColor: AppColors.error,
          subtitle: 'This cannot be undone',
          subtitleColor: AppColors.error.withValues(alpha: 0.7),
          onTap: (sheetContext) {
            Navigator.of(sheetContext).pop();
            _confirmDelete(context, ref);
          },
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    if (!tapGuard()) return;
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Delete Workout?',
      message: 'This workout will be permanently removed from your history.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;

    final db = ref.read(databaseProvider);
    final actions = ref.read(workoutActionsProvider.notifier);

    // Capture the JSON representation of the session before delete
    final data = await db.workoutsDao.exportSessionJson(sessionId);
    if (data == null) return;

    if (!context.mounted) return;

    // RD-4 discipline: capture messenger and router BEFORE popping
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    HapticFeedback.mediumImpact();

    await actions.deleteSession(sessionId);
    router.pop();

    showUndoableDelete(
      messenger: messenger,
      label: 'Workout deleted',
      onUndo: () async {
        await actions.restoreSession(data);
      },
    );
  }
}

/// Loading placeholder mirroring the hero + a couple of exercise cards, so the
/// screen doesn't pop from a centered spinner into a dense layout.
class _DetailCardSkeleton extends StatelessWidget {
  const _DetailCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppCard.decoration(radius: AppRadius.card),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonBox(width: 52, height: 52, radius: AppRadius.thumbnail),
              SizedBox(width: 12),
              Expanded(child: SkeletonBox(height: 16, width: 160)),
            ],
          ),
          SizedBox(height: 16),
          SkeletonBox(height: 13, width: 200),
          SizedBox(height: 10),
          SkeletonBox(height: 13, width: 170),
        ],
      ),
    );
  }
}
