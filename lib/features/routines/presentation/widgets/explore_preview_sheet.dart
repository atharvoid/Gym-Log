import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/features/profile/presentation/providers/profile_provider.dart';
import 'package:gymlog/features/routines/presentation/data/explore_catalog.dart';
import 'package:gymlog/features/routines/presentation/data/routine_index.dart';
import 'package:gymlog/features/routines/presentation/providers/explore_providers.dart';
import 'package:gymlog/shared/widgets/body/muscle_map.dart';
import 'package:gymlog/shared/widgets/ui/primary_button.dart';

/// Opens the interactive routine preview bottom sheet.
Future<void> showRoutinePreviewSheet({
  required BuildContext context,
  required ExploreRoutine routine,
  required bool isOwned,
  required VoidCallback onAdd,
  VoidCallback? onView,
}) {
  HapticFeedback.selectionClick();
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => RoutinePreviewSheet(
      routine: routine,
      isOwned: isOwned,
      onAdd: onAdd,
      onView: onView,
    ),
  );
}

/// A comprehensive bottom sheet for inspecting an individual routine before
/// importing it: target muscles (front & back), exercise list with sets/reps,
/// duration, level, equipment, and a direct CTA.
class RoutinePreviewSheet extends ConsumerWidget {
  const RoutinePreviewSheet({
    super.key,
    required this.routine,
    required this.isOwned,
    required this.onAdd,
    this.onView,
  });

  final ExploreRoutine routine;
  final bool isOwned;
  final VoidCallback onAdd;
  final VoidCallback? onView;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surface = context.surface;
    final profile = ref.watch(routineMuscleProfileProvider(routine.slug));
    final userProfile = ref.watch(currentUserProfileProvider).valueOrNull;
    final gender = userProfile?.gender ?? 'male';

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.45,
      maxChildSize: 0.94,
      expand: false,
      builder: (context, scrollController) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [surface.surface2, surface.bgBase],
          ),
          borderRadius: AppRadius.sheetTop,
          border: Border(top: BorderSide(color: surface.borderSubtle)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: surface.borderEmphasis,
                borderRadius: AppRadius.badgeAll,
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x5,
                  AppSpacing.x4,
                  AppSpacing.x5,
                  AppSpacing.x4,
                ),
                children: [
                  // Routine Title & Subtitle
                  Text(
                    routine.name,
                    style: AppText.sectionHeading(
                      color: surface.textPrimary,
                      shadows: AppText.depthFor(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Day ${routine.dayNumber} of ${routine.programLabel}'
                    '${routine.focus.isNotEmpty ? ' · ${routine.focus}' : ''}',
                    style: AppText.meta(color: surface.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.x4),

                  // Metadata facts row
                  _RoutineFactRow(routine: routine),
                  const SizedBox(height: AppSpacing.x5),

                  // Muscles Worked Section
                  Semantics(
                    header: true,
                    child: Text(
                      'Muscles Worked',
                      style: AppText.cardTitle(color: surface.textPrimary),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 240),
                      child: MuscleMap(
                        primaryGroups: profile.primary,
                        secondaryGroups: profile.secondary,
                        gender: gender,
                        showBack: true,
                        showLegend: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x5),

                  // Exercises list header
                  Semantics(
                    header: true,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Exercises',
                          style: AppText.cardTitle(color: surface.textPrimary),
                        ),
                        Text(
                          '${routine.slots.length} total',
                          style: AppText.caption(color: surface.textTertiary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  Divider(height: 1, thickness: 1, color: surface.borderSubtle),
                  const SizedBox(height: 6),

                  // Exercise Rows
                  for (var i = 0; i < routine.slots.length; i++)
                    _ExerciseSlotRow(index: i + 1, slot: routine.slots[i]),
                ],
              ),
            ),

            // Sticky Bottom CTA Bar
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x5,
                  AppSpacing.x2,
                  AppSpacing.x5,
                  AppSpacing.x3,
                ),
                child: PrimaryButton(
                  label: isOwned ? 'View in My Routines' : 'Add to My Routines',
                  icon: isOwned ? Icons.check_rounded : Icons.download_rounded,
                  onPressed: () {
                    if (isOwned) {
                      Navigator.of(context).pop();
                      if (onView != null) onView!();
                    } else {
                      onAdd();
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutineFactRow extends StatelessWidget {
  const _RoutineFactRow({required this.routine});

  final ExploreRoutine routine;

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;

    return Wrap(
      spacing: AppSpacing.x2,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _FactPill(
          leading: Icon(
            Icons.schedule_rounded,
            size: 13,
            color: surface.textSecondary,
          ),
          label: '~${routine.estMinutes} min',
        ),
        _FactPill(
          leading: Icon(
            Icons.fitness_center_rounded,
            size: 13,
            color: surface.textSecondary,
          ),
          label: '${routine.exerciseCount} exercises',
        ),
        _FactPill(
          leading: Icon(
            Icons.speed_rounded,
            size: 13,
            color: surface.textSecondary,
          ),
          label: routine.levelLabel,
        ),
        _FactPill(
          leading: Icon(
            Icons.layers_rounded,
            size: 13,
            color: surface.textSecondary,
          ),
          label: routine.equipmentLabel,
        ),
      ],
    );
  }
}

class _FactPill extends StatelessWidget {
  const _FactPill({required this.leading, required this.label});

  final Widget leading;
  final String label;

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: surface.surface3,
        borderRadius: AppRadius.badgeAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: 5),
          Text(label, style: AppText.badge(color: surface.textSecondary)),
        ],
      ),
    );
  }
}

class _ExerciseSlotRow extends StatelessWidget {
  const _ExerciseSlotRow({required this.index, required this.slot});

  final int index;
  final TemplateSlot slot;

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '$index',
              style: AppText.statLabel(
                color: slot.isConditioningNote
                    ? surface.textTertiary
                    : surface.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.x2),
          Expanded(
            child: Text(
              slot.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.rowLabel(
                color: slot.isConditioningNote
                    ? surface.textSecondary
                    : surface.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.x2),
          if (slot.isConditioningNote)
            Tooltip(
              message: 'Not in your exercise library -- log this manually',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: surface.surface3,
                  borderRadius: AppRadius.badgeAll,
                ),
                child: Text(
                  'LOG MANUALLY',
                  style: AppText.badge(color: surface.textTertiary),
                ),
              ),
            )
          else
            Text(
              '${slot.sets} × ${slot.reps}',
              style: AppText.statLabel(color: surface.textSecondary),
            ),
        ],
      ),
    );
  }
}
