import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../shared/widgets/ui/primary_button.dart';
import '../../../../shared/widgets/ui/tracker_card.dart';
import '../../../../shared/widgets/ui/action_bottom_sheet.dart';

/// [routine_card.dart]
/// Purpose: Tappable routine card. Tap anywhere on the card → detail screen.
/// The 3-dot menu handles edit/delete actions without triggering navigation.

class RoutineCard extends ConsumerWidget {
  final String routineId;
  final String routineName;
  final List<String> exerciseNames;
  final VoidCallback onStartTap;

  const RoutineCard({
    super.key,
    required this.routineId,
    required this.routineName,
    required this.exerciseNames,
    required this.onStartTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preview = exerciseNames.take(3).join(', ') +
        (exerciseNames.length > 3 ? '...' : '');

    return TrackerCard(
      padding: EdgeInsets.zero,
      // Tap the card body to open routine detail
      onTap: () => context.push('/routines/$routineId'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Name + more_vert
            Row(
              children: [
                Expanded(
                  child: Text(
                    routineName,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // 3-dot stops tap propagation naturally (button handles its own gesture)
                IconButton(
                  icon: const Icon(
                    Icons.more_horiz,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: () => _showOptions(context, ref),
                  padding: const EdgeInsets.all(12),
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // Subtitle: exercise preview
            if (preview.isNotEmpty)
              Text(
                preview,
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

            const SizedBox(height: 16),

            // Footer: Start Routine button
            PrimaryButton(
              label: 'Start Routine',
              onPressed: onStartTap,
            ),
          ],
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Coming soon',
                  style: GoogleFonts.inter(color: AppColors.textPrimary),
                ),
                backgroundColor: AppColors.bgSurface,
                behavior: SnackBarBehavior.floating,
              ),
            );
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
            _confirmDeleteRoutine(context, ref, routineId, routineName);
          },
        ),
      ],
    );
  }

  void _confirmDeleteRoutine(
    BuildContext context,
    WidgetRef ref,
    String routineId,
    String routineName,
  ) {
    showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Delete Routine?',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'This routine will be permanently deleted.',
          style: GoogleFonts.inter(
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              final db = ref.read(databaseProvider);
              await db.routinesDao.deleteRoutine(routineId);
            },
            child: Text(
              'Delete',
              style: GoogleFonts.inter(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


