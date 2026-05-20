import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/ui/primary_button.dart';
import '../../../../shared/widgets/ui/tracker_card.dart';

class RoutineCard extends StatelessWidget {
  final String routineName;
  final List<String> exerciseNames;
  final DateTime? lastPerformed;
  final VoidCallback onStartTap;

  const RoutineCard({
    super.key,
    required this.routineName,
    required this.exerciseNames,
    this.lastPerformed,
    required this.onStartTap,
  });

  @override
  Widget build(BuildContext context) {
    final preview = exerciseNames.take(3).join(', ') +
        (exerciseNames.length > 3 ? '...' : '');

    return TrackerCard(
      padding: EdgeInsets.zero,
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
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.more_horiz,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: () => _showOptions(context),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Subtitle: exercise preview
            Text(
              preview,
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 16),

            // Footer: Start Routine
            PrimaryButton(
              label: 'Start Routine',
              onPressed: onStartTap,
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.textSecondary, size: 22),
              title: Text(
                'Edit Routine',
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/routines/edit', extra: {
                  'name': routineName,
                  'exercises': exerciseNames,
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error, size: 22),
              title: Text(
                'Delete Routine',
                style: GoogleFonts.inter(
                  color: AppColors.error,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                // TODO: Wire to RoutinesDao
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
