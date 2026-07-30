import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymlog/core/database/daos/routines_dao.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/dynamic_accent_theme.dart';
import '../../../../core/utils/tap_guard.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../shared/providers/bottom_chrome_provider.dart';
import '../../../../shared/widgets/async_error_state.dart';
import '../../../../shared/widgets/ui/app_card.dart';
import '../../../../shared/widgets/ui/secondary_button.dart';
import '../../../../shared/widgets/ui/skeleton.dart';
import '../../../../shared/widgets/motion/entrance_fade.dart';
import '../../../routines/presentation/widgets/routine_card.dart';
import '../../../routines/presentation/providers/routines_provider.dart';
import '../../domain/active_workout_state.dart';
import '../providers/active_workout_provider.dart';

/// [workout_screen.dart]
/// Routines tab — the user's saved routines (reactive via hydratedRoutinesProvider).
///
/// HEADER DISCIPLINE: this screen earns its vertical space or gives it up. The
/// previous version spent ~100dp on gaps plus a collapsible "My Routines (n)"
/// section header before the first card. That header duplicated the screen
/// title and the count already in the subtitle, and its collapse toggle could
/// only ever collapse the single list on the page — i.e. blank the screen. Both
/// are gone; the list starts immediately after the action row.
class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  void _startRoutine(HydratedRoutine routine) async {
    if (routine.exerciseIds.isEmpty) {
      return; // guarded again in the card (with feedback)
    }
    if (!tapGuard()) return;
    HapticFeedback.mediumImpact();

    final detail = await ref
        .read(databaseProvider)
        .routinesDao
        .getHydratedRoutineDetail(routine.routine.id);
    if (detail == null || !mounted) return;

    ref.read(activeWorkoutProvider.notifier).startWorkout(
          routineId: routine.routine.id,
          name: routine.routine.name,
          initialExercises: seedExercisesFromRoutine(detail),
        );
    context.push('/workout/active');
  }

  void _push(String path) {
    if (!tapGuard()) return;
    HapticFeedback.lightImpact();
    context.push(path);
  }

  List<HydratedRoutine>? _prevRoutines;
  String? _cachedSummary;

  String _summaryLine(List<HydratedRoutine> routines) {
    if (identical(_prevRoutines, routines) && _cachedSummary != null) {
      return _cachedSummary!;
    }
    final count = routines.length;
    final label = count == 1 ? 'routine' : 'routines';
    DateTime? maxLast;
    for (final r in routines) {
      final d = r.lastTrained;
      if (d != null && (maxLast == null || d.isAfter(maxLast))) maxLast = d;
    }
    _prevRoutines = routines;
    _cachedSummary = maxLast == null
        ? '$count $label'
        : '$count $label  ·  Last trained ${relativeDay(maxLast)}';
    return _cachedSummary!;
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
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Identity header (replaces AppBar — matches Home's chrome) ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: EntranceFade(
                  index: 0,
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
                                child: Text(_summaryLine(routines),
                                    style: AppText.body(
                                        color: surface.textSecondary)),
                              ),
                        orElse: () => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Action row: New (solid accent CTA) + Explore (neutral) ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: EntranceFade(
                  index: 1,
                  child: Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          label: 'New Routine',
                          icon: Icons.add_rounded,
                          solid:
                              true, // solid accent fill + onAccent label — the one focal CTA
                          onPressed: () => _push('/routines/edit'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SecondaryButton(
                          label: 'Explore',
                          icon: Icons.explore_rounded,
                          onPressed: () => _push('/routines/explore'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── The list itself — no section header, no disclosure toggle ──
            ...routinesAsync.when(
              loading: () => [
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
                  sliver: SliverToBoxAdapter(child: _RoutinesLoading()),
                ),
              ],
              error: (e, _) => [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: Semantics(
                      liveRegion: true,
                      child: AsyncErrorState(
                        message: "Couldn't load your routines.",
                        onRetry: () => ref.invalidate(hydratedRoutinesProvider),
                      ),
                    ),
                  ),
                ),
              ],
              data: (routines) {
                if (routines.isEmpty) {
                  return [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: _EmptyRoutines(
                            onNew: () => _push('/routines/edit')),
                      ),
                    ),
                  ];
                }
                return [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => EntranceFade(
                          index: 2 + i,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: RoutineCard(
                              routineId: routines[i].routine.id,
                              routineName: routines[i].routine.name,
                              exerciseNames: routines[i].exerciseNames,
                              muscleTags: routines[i].muscleTags,
                              lastTrained: routines[i].lastTrained,
                              onStartTap: () => _startRoutine(routines[i]),
                            ),
                          ),
                        ),
                        childCount: routines.length,
                      ),
                    ),
                  ),
                ];
              },
            ),

            SliverToBoxAdapter(child: SizedBox(height: bottomInset + 16)),
          ],
        ),
      ),
    );
  }
}

/// Skeleton feed shown while routines load — mirrors the real card proportions.
class _RoutinesLoading extends StatelessWidget {
  const _RoutinesLoading();

  @override
  Widget build(BuildContext context) {
    return const SkeletonPulse(
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
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: AppCard.decoration(radius: AppRadius.card),
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

/// Calm empty state with an inline CTA (not just a text void).
class _EmptyRoutines extends StatelessWidget {
  final VoidCallback onNew;
  const _EmptyRoutines({required this.onNew});

  @override
  Widget build(BuildContext context) {
    final accent = context.accent;
    return AppCard(
      radius: AppRadius.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('No routines yet', style: AppText.exerciseName()),
          const SizedBox(height: 4),
          Text('Save a workout as a routine, or create one above.',
              style: AppText.meta()),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onNew,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 44),
              foregroundColor: accent.light,
            ),
            icon: Icon(Icons.add_rounded, size: 18, color: accent.light),
            label:
                Text('New Routine', style: AppText.button(color: accent.light)),
          ),
        ],
      ),
    );
  }
}
