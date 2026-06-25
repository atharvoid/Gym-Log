import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../shared/widgets/ui/start_button.dart';
import '../../../../core/services/muscle_color_service.dart';
import '../../../../core/utils/tap_guard.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../shared/widgets/ui/action_bottom_sheet.dart';
import '../../../../shared/widgets/ui/app_dialog.dart';
import '../../../../shared/widgets/ui/muscle_glyph.dart';

/// Premium routine card for the Routines list.
/// - Tapping the body opens the routine detail (`/routines/:id`).
/// - The compact "Start" pill fires [onStartTap] (and won't trigger the body tap).
/// - Renders a muscle-group glyph, exercise count, last-trained, muscle tags,
///   and a 1-line preview.
class RoutineCard extends ConsumerWidget {
  final String routineId;
  final String routineName;
  final List<String> exerciseNames;
  final List<String> muscleTags;
  final DateTime? lastTrained;
  final VoidCallback onStartTap;

  const RoutineCard({
    super.key,
    required this.routineId,
    required this.routineName,
    required this.exerciseNames,
    required this.onStartTap,
    this.muscleTags = const [],
    this.lastTrained,
  });

  /// Dominant-muscle accent, sourced from the shared [MuscleColorService] so the
  /// routine glyph follows the same "dominant = brightest" rule as the muscle-
  /// split bar (replaces the previous ad-hoc per-name hashCode tint).
  Color get _glyphColor => MuscleColorService.glyphColorFor(
      muscleTags.isNotEmpty ? muscleTags.first : null);

  Widget _tag(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: const BoxDecoration(
          color: AppColors.surface3,
          borderRadius: AppRadius.badgeAll,
        ),
        child:
            Text(label, style: AppText.badge(color: AppColors.textSecondary)),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = exerciseNames.length;
    final exLabel = count == 1 ? 'exercise' : 'exercises';
    final meta = lastTrained == null
        ? '$count $exLabel'
        : '$count $exLabel · ${relativeDay(lastTrained!)}';

    final preview = exerciseNames.isEmpty
        ? 'No exercises yet'
        : exerciseNames.take(3).join(', ') +
            (count > 3 ? '  +${count - 3}' : '');

    final tags = muscleTags.take(3).toList();
    final extraTags = muscleTags.length - tags.length;

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: AppRadius.cardAll,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (!tapGuard()) return;
            HapticFeedback.selectionClick();
            context.push('/routines/$routineId');
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15, 14, 10, 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header: muscle glyph + name/meta + menu ──────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Muscle-group glyph for the dominant muscle, in a square
                    // tinted by the same muscle. Decorative — name carries it.
                    ExcludeSemantics(
                      child: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _glyphColor.withValues(alpha: 0.15),
                          borderRadius: AppRadius.buttonPrimaryAll,
                        ),
                        child: MuscleGlyph(
                          muscle: muscleTags.isNotEmpty
                              ? muscleTags.first
                              : 'fullbody',
                          size: 26,
                          color: _glyphColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              routineName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.cardTitle(),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              meta,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.caption(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // S13: standardized to more_horiz_rounded + showActionBottomSheet
                    IconButton(
                      tooltip: 'More options',
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 48, minHeight: 48),
                      iconSize: 20,
                      icon: const Icon(Icons.more_horiz_rounded,
                          color: AppColors.textSecondary),
                      onPressed: () => _showOptions(context, ref),
                    ),
                  ],
                ),

                // ── Muscle tags (aligned under the text column) ──────────
                if (tags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 57, top: 11),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final t in tags) _tag(t),
                        if (extraTags > 0) _tag('+$extraTags'),
                      ],
                    ),
                  ),

                // ── Divider ───────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(top: 13),
                  child: Container(height: 1, color: AppColors.borderSubtle),
                ),

                // ── Footer: preview + Start pill ────────────────────
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.caption(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      StartButton(
                        label: 'Start',
                        enabled: exerciseNames.isNotEmpty,
                        onPressed: () {
                          // 0-exercise routine: don't silently no-op — tell
                          // the user why nothing happened.
                          if (exerciseNames.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Add exercises to this routine first',
                                  style: AppText.body(
                                      color: AppColors.textPrimary),
                                ),
                                backgroundColor: AppColors.surface2,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }
                          onStartTap();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context, WidgetRef ref) {
    showActionBottomSheet(
      context: context,
      title: routineName,
      items: [
        ActionSheetItem(
          icon: Icons.edit_outlined,
          iconColor: AppColors.textSecondary,
          iconBackground: AppColors.bgBase,
          title: 'Edit Routine',
          onTap: (sheetContext) {
            Navigator.of(sheetContext).pop();
            HapticFeedback.selectionClick();
            context.push('/routines/edit?id=$routineId');
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
          onTap: (sheetContext) {
            Navigator.of(sheetContext).pop();
            _confirmDelete(context, ref);
          },
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final actions = ref.read(databaseProvider).routinesDao;
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Delete Routine?',
      message:
          'This routine will be permanently deleted. Your workout history stays.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (confirmed) {
      await actions.deleteRoutine(routineId);
    }
  }
}
