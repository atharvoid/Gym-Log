import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:gymlog/core/database/daos/routines_dao.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/tap_guard.dart';
import '../../../../shared/widgets/async_error_state.dart';
import '../../../../shared/widgets/ui/app_card.dart';
import '../../../../shared/widgets/ui/skeleton.dart';
import '../../../routines/presentation/widgets/routine_card.dart';
import '../../../routines/presentation/providers/routines_provider.dart';
import '../../domain/active_workout_state.dart';
import '../providers/active_workout_provider.dart';

/// [workout_screen.dart]
/// Routines tab — premium list of the user's saved routines.
/// State: hydratedRoutinesProvider (StreamProvider) — auto-refreshes on DB writes.
class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  bool _routinesExpanded = true;

  void _startRoutine(HydratedRoutine routine) {
    if (routine.exerciseIds.isEmpty) return;
    if (!tapGuard()) return; // no double-start / double-push
    HapticFeedback.mediumImpact();

    final exercises = routine.exerciseIds.asMap().entries.map((e) {
      return WorkoutExerciseState(
        id: const Uuid().v4(),
        exerciseId: e.value,
        name: routine.exerciseNames[e.key],
        sets: [WorkoutSetState.create()],
      );
    }).toList();

    ref.read(activeWorkoutProvider.notifier).startWorkout(
          routineId: routine.routine.id,
          name: routine.routine.name,
          initialExercises: exercises,
        );
    context.push('/workout/active');
  }

  void _push(String path) {
    if (!tapGuard()) return;
    HapticFeedback.lightImpact();
    context.push(path);
  }

  String _relative(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays < 1) return 'today';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    return '${(diff.inDays / 30).floor()} months ago';
  }

  String _summaryLine(List<HydratedRoutine> routines) {
    final count = routines.length;
    final label = count == 1 ? 'routine' : 'routines';
    DateTime? maxLast;
    for (final r in routines) {
      final d = r.lastTrained;
      if (d != null && (maxLast == null || d.isAfter(maxLast))) maxLast = d;
    }
    return maxLast == null
        ? '$count $label'
        : '$count $label  ·  Last trained ${_relative(maxLast)}';
  }

  @override
  Widget build(BuildContext context) {
    final routinesAsync = ref.watch(hydratedRoutinesProvider);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgBase,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Semantics(
          header: true,
          child: Text('Routines', style: AppText.screenTitle()),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Recency summary ──────────────────────────────────────────
            routinesAsync.maybeWhen(
              data: (routines) => routines.isEmpty
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(_summaryLine(routines), style: AppText.meta()),
                    ),
              orElse: () => const SizedBox.shrink(),
            ),

            // ── Action row: New (primary) + Explore (catalog) ────────────
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'New Routine',
                    icon: Icons.add_rounded,
                    primary: true,
                    onTap: () => _push('/routines/edit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    label: 'Explore',
                    icon: Icons.explore_rounded,
                    onTap: () => _push('/routines/explore'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // ── Collapsible section header ───────────────────────────────
            Semantics(
              button: true,
              expanded: _routinesExpanded,
              label: 'My Routines',
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _routinesExpanded = !_routinesExpanded);
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  // ~48dp tap target for the disclosure control.
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    children: [
                      AnimatedRotation(
                        turns: _routinesExpanded ? 0 : -0.25,
                        duration: reduceMotion
                            ? Duration.zero
                            : const Duration(milliseconds: 200),
                        child: const Icon(Icons.keyboard_arrow_down_rounded,
                            color: AppColors.textSecondary, size: 20),
                      ),
                      const SizedBox(width: 4),
                      routinesAsync.maybeWhen(
                        data: (r) => Text('My Routines (${r.length})',
                            style: AppText.exerciseName()),
                        orElse: () =>
                            Text('My Routines', style: AppText.exerciseName()),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // ── Routine list (animated collapse) ─────────────────────────
            AnimatedSize(
              duration:
                  reduceMotion ? Duration.zero : const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: !_routinesExpanded
                  ? const SizedBox(width: double.infinity)
                  : routinesAsync.when(
                      loading: () => const _RoutinesLoading(),
                      error: (e, _) => AsyncErrorState(
                        message: "Couldn't load your routines.",
                        onRetry: () =>
                            ref.invalidate(hydratedRoutinesProvider),
                      ),
                      data: (routines) {
                        if (routines.isEmpty) {
                          return _EmptyRoutines(onNew: () => _push('/routines/edit'));
                        }
                        return Column(
                          children: [
                            for (final routine in routines)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: RoutineCard(
                                  routineId: routine.routine.id,
                                  routineName: routine.routine.name,
                                  exerciseNames: routine.exerciseNames,
                                  muscleTags: routine.muscleTags,
                                  lastTrained: routine.lastTrained,
                                  onStartTap: () => _startRoutine(routine),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Top action button. `primary` = accent-outline (New Routine);
/// otherwise a neutral raised surface (Explore).
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = primary ? AppColors.accentText : AppColors.textPrimary;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: primary ? AppColors.indigoTint : AppColors.surface2,
        borderRadius: AppRadius.buttonSecondaryAll,
        border: primary
            ? Border.all(color: AppColors.accentPrimary.withValues(alpha: 0.45))
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 8),
                Text(label, style: AppText.button(color: fg)),
              ],
            ),
          ),
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
      decoration: AppCard.decoration(),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonBox(width: 44, height: 44, radius: 12),
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
              SkeletonBox(width: 64, height: 32, radius: 14),
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
    return AppCard(
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
              foregroundColor: AppColors.accentText,
            ),
            icon: const Icon(Icons.add_rounded, size: 18, color: AppColors.accentText),
            label: Text('New Routine', style: AppText.button(color: AppColors.accentText)),
          ),
        ],
      ),
    );
  }
}
