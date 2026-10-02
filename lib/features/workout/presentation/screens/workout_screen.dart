import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymlog/core/database/daos/routines_dao.dart';
import 'package:gymlog/core/database/daos/program_grouping.dart';
import 'package:gymlog/features/routines/presentation/widgets/training_launchpad.dart';
import 'package:gymlog/features/workout/presentation/providers/active_workout_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/dynamic_accent_theme.dart';
import '../../../../core/utils/tap_guard.dart';
import '../../../../shared/providers/bottom_chrome_provider.dart';
import '../../../../shared/widgets/ui/action_bottom_sheet.dart';
import '../../../../shared/widgets/ui/app_card.dart';
import '../../../../shared/widgets/ui/skeleton.dart';
import '../../../routines/presentation/widgets/routine_card.dart';
import '../../../routines/presentation/providers/routines_provider.dart';
import 'package:gymlog/shared/layout/adaptive.dart';

/// [workout_screen.dart]
/// Routines tab — the user's saved routines (reactive via hydratedRoutinesProvider).
///
/// The saved training choice leads the library. Creation stays available as a
/// utility; source-program groups organize the other saved routines below it.
class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  void _startRoutine(HydratedRoutine routine) =>
      launchTraining(context, ref, routine.routine.id);

  void _push(String path) {
    if (!tapGuard()) return;
    HapticFeedback.lightImpact();
    context.push(path);
  }

  void _openCreateRoutineSheet() {
    final accent = context.accent;
    showActionBottomSheet(
      context: context,
      title: 'New Routine',
      items: [
        ActionSheetItem(
          icon: Icons.edit_note_rounded,
          iconColor: accent.base,
          iconBackground: accent.base.withValues(alpha: 0.15),
          title: 'Create from Scratch',
          subtitle: 'Build a custom routine exercise by exercise',
          onTap: (ctx) {
            Navigator.pop(ctx);
            _push('/routines/edit');
          },
        ),
        ActionSheetItem(
          icon: Icons.auto_awesome_rounded,
          iconColor: accent.base,
          iconBackground: accent.base.withValues(alpha: 0.15),
          title: 'AI Import from Image or Text',
          subtitle: 'Scan a gym notebook, whiteboard, or paste notes',
          onTap: (ctx) {
            Navigator.pop(ctx);
            _push('/routines/ai-import');
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final routinesAsync = ref.watch(hydratedRoutinesProvider);
    final surface = context.surface;
    // Reserve room for the nav bar and, when a session is live, the floating
    // mini player. Replaces the old hardcoded 24dp bottom padding, which hid
    // the last card behind the mini player mid-workout.
    final bottomInset = ref.watch(bottomChromeInsetProvider);

    return Scaffold(
      backgroundColor: surface.bgBase,
      body: AdaptiveContent(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // ── Identity header (replaces AppBar — matches Home's chrome) ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          'Routines',
                          style: AppText.screenTitle(color: surface.textPrimary)
                              .copyWith(letterSpacing: -0.5),
                        ),
                      ),
                      routinesAsync.maybeWhen(
                        data: (routines) => routines.isEmpty
                            ? const SizedBox.shrink()
                            : Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                    '${routines.length} saved ${routines.length == 1 ? 'routine' : 'routines'}',
                                    style: AppText.body(
                                        color: surface.textSecondary)),
                              ),
                        orElse: () => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                  child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Wrap(spacing: AppSpacing.x4, children: [
                        TextButton(
                            onPressed: _openCreateRoutineSheet,
                            style: TextButton.styleFrom(
                                foregroundColor: surface.textSecondary),
                            child: const Text('New routine')),
                        TextButton(
                            onPressed: () => _push('/routines/explore'),
                            style: TextButton.styleFrom(
                                foregroundColor: surface.textSecondary),
                            child: const Text('Explore')),
                      ]))),
              const SliverToBoxAdapter(
                  child: Padding(
                      padding: EdgeInsets.all(16),
                      child: AppCard(
                          radius: AppRadius.card,
                          child: TrainingLaunchpad(compact: true)))),

              // Source-program groups and standalone saved plans.
              ...routinesAsync.when(
                loading: () => [
                  const SliverPadding(
                    padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
                    sliver: SliverToBoxAdapter(child: _RoutinesLoading()),
                  ),
                ],
                // The launchpad already owns this read failure and its Retry action.
                error: (e, _) => [],
                data: (routines) {
                  if (routines.isEmpty) {
                    return [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                        sliver: SliverToBoxAdapter(
                          child: Text(
                              'Browse programs or use New routine to add your own plan.',
                              style:
                                  AppText.body(color: surface.textSecondary)),
                        ),
                      ),
                    ];
                  }
                  final grouping = groupProgramRoutines(routines
                      .map((r) => ProgramRoutineRef.fromRoutine(r.routine))
                      .toList());
                  final byId = {for (final r in routines) r.routine.id: r};
                  return [
                    for (final group in grouping.programs) ...[
                      SliverToBoxAdapter(
                          child: Padding(
                              key: ValueKey('program-${group.key}'),
                              padding:
                                  const EdgeInsets.fromLTRB(16, 16, 16, 12),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(group.name,
                                        style: AppText.sectionHeading(
                                            color: surface.textPrimary)),
                                    Text(
                                        'Source program · ${group.routines.length} saved routines',
                                        style: AppText.meta(
                                            color: surface.textSecondary)),
                                  ]))),
                      _routineList(
                          group.routines.map((r) => byId[r.id]!).toList()),
                    ],
                    if (grouping.standalone.isNotEmpty) ...[
                      SliverToBoxAdapter(
                          child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text('Standalone routines',
                                  style: AppText.sectionHeading(
                                      color: surface.textPrimary)))),
                      _routineList(
                          grouping.standalone.map((r) => byId[r.id]!).toList()),
                    ],
                  ];
                },
              ),

              SliverToBoxAdapter(child: SizedBox(height: bottomInset + 16)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _routineList(List<HydratedRoutine> routines) => SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
              (context, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: RoutineCard(
                      routineId: routines[i].routine.id,
                      routineName: routines[i].routine.name,
                      exerciseNames: routines[i].exerciseNames,
                      muscleTags: routines[i].muscleTags,
                      lastTrained: routines[i].lastTrained,
                      workoutInProgress:
                          ref.watch(activeWorkoutProvider) != null,
                      onStartTap: () => _startRoutine(routines[i]))),
              childCount: routines.length)));
}

/// Skeleton feed shown while routines load — mirrors the real card proportions.
class _RoutinesLoading extends StatelessWidget {
  const _RoutinesLoading();

  @override
  Widget build(BuildContext context) {
    return const SkeletonPulse(
      label: 'Loading your routines',
      child: Column(
        children: [
          _RoutineCardSkeleton(),
          SizedBox(height: 12),
          _RoutineCardSkeleton(),
          SizedBox(height: 12),
          _RoutineCardSkeleton(),
        ],
      ),
    );
  }
}

class _RoutineCardSkeleton extends StatelessWidget {
  const _RoutineCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration:
          AppCard.decoration(radius: AppRadius.card, isLight: surface.isLight),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonBox(
                  width: 44, height: 44, radius: AppRadius.buttonPrimary),
              SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 140, height: 16),
                    SizedBox(height: 8),
                    SkeletonBox(width: 90, height: 12),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          SkeletonBox(height: 1, width: double.infinity),
          SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: SkeletonBox(height: 12)),
              SizedBox(width: 12),
              SkeletonBox(
                  width: 68, height: 32, radius: AppRadius.buttonPrimary),
            ],
          ),
        ],
      ),
    );
  }
}
