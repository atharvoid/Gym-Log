import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/dynamic_accent_theme.dart';

/// [active_workout_bar.dart]
/// Purpose: High-Density Tracker - Active workout indicator with an accent pulse
/// Dependencies: flutter/material.dart, go_router, app_colors.dart, app_text.dart
/// Last modified: Phase 7 — gradient wash, glow, and play dot follow the active
/// accent palette (purple/copper/teal/red) via [BuildContext.accent].

class ActiveWorkoutBar extends StatefulWidget {
  const ActiveWorkoutBar({super.key});

  @override
  State<ActiveWorkoutBar> createState() => _ActiveWorkoutBarState();
}

class _ActiveWorkoutBarState extends State<ActiveWorkoutBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _glowAnim = Tween<double>(begin: 0.10, end: 0.28).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    if (reduceMotion) {
      return _buildBar(context, glowAlpha: 0.19, blurRadius: 18);
    }

    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (context, child) =>
          _buildBar(context, glowAlpha: _glowAnim.value, blurRadius: 12 + _glowAnim.value * 50),
    );
  }

  Widget _buildBar(BuildContext context,
      {required double glowAlpha, required double blurRadius}) {
    final accent = context.accent;
    return GestureDetector(
      onTap: () => context.push('/workout/active'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [accent.muted, AppColors.surface2],
          ),
          borderRadius: BorderRadius.circular(AppRadius.buttonSecondary),
          border: Border.all(color: AppColors.borderDefault, width: 1),
          boxShadow: [
            BoxShadow(
              color: accent.base.withValues(alpha: glowAlpha),
              blurRadius: blurRadius,
              spreadRadius: 0,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Filled accent play button dot
            Container(
              decoration: BoxDecoration(
                color: accent.base,
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.play_arrow_rounded,
                color: accent.onAccent,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            // Two-line label block
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Workout in progress', style: AppText.cardTitle()),
                  Text('Tap to resume',
                      style: AppText.meta(color: AppColors.textSecondary)),
                ],
              ),
            ),
            // Right chevron
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
