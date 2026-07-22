import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../shared/widgets/ui/start_button.dart';
import '../../../../core/utils/tap_guard.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../shared/widgets/ui/action_bottom_sheet.dart';
import '../../../../shared/widgets/ui/app_dialog.dart';

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

  Widget _tag(
    BuildContext context,
    String label, {
    Color? backgroundColor,
    Color? textColor,
  }) {
    final surface = context.surface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor ?? surface.surface3,
        borderRadius: AppRadius.badgeAll,
      ),
      child: Text(label,
          style: AppText.badge(color: textColor ?? surface.textSecondary)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = context.accent;
    final surface = context.surface;
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
        gradient: surface.isLight
            ? AppColors.cardGradientLight
            : AppColors.cardGradient,
        borderRadius: AppRadius.cardAll,
        border: Border.all(color: surface.borderSubtle),
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
                // ── Header: title/meta + menu ─────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(routineName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.cardTitle()),
                            const SizedBox(height: 3),
                            Text(meta,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.caption()),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'More options',
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 48, minHeight: 48),
                      iconSize: 20,
                      icon: Icon(Icons.more_horiz_rounded,
                          color: surface.textSecondary),
                      onPressed: () => _showOptions(context, ref),
                    ),
                  ],
                ),

                // ── Muscle tags (first accent, rest neutral) ───────────────
                if (tags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _tag(context, tags.first,
                            backgroundColor: accent.muted,
                            textColor: accent.base),
                        for (final t in tags.skip(1)) _tag(context, t),
                        if (extraTags > 0) _tag(context, '+$extraTags'),
                      ],
                    ),
                  ),

                // ── Divider ───────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(top: 13),
                  child: Container(height: 1, color: surface.borderSubtle),
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
                                  style:
                                      AppText.body(color: surface.textPrimary),
                                ),
                                backgroundColor: surface.surface2,
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
          iconColor: context.surface.textSecondary,
          iconBackground: context.surface.bgBase,
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
