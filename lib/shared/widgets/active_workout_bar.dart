import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

/// [active_workout_bar.dart]
/// Purpose: High-Density Tracker - Active workout indicator (monochrome)
/// Dependencies: flutter/material.dart, go_router, google_fonts, app_colors.dart
/// Last modified: High-Density Tracker Overhaul

class ActiveWorkoutBar extends StatelessWidget {
  const ActiveWorkoutBar({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/workout/active'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.borderSubtle, width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_circle_filled, color: AppColors.textPrimary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Workout in progress — tap to resume',
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
