import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

/// Branded replacement for Flutter's red/grey error screen in release mode.
/// Wired up via `ErrorWidget.builder` in main.dart.
///
/// Deliberately dependency-free and layout-safe: it can be inflated outside
/// a MaterialApp (no Directionality / Theme above it), so everything is
/// self-contained.
class AppErrorScreen extends StatelessWidget {
  const AppErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: AppColors.bgBase,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.accentPrimary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.fitness_center_rounded,
                    color: Color(0xFFB98CFF),
                    size: 26,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Something went wrong',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your workout data is safe on this device.\n'
                  'Head back or restart the app.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
