import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';

/// Animated weekly-goal ring — fills smoothly as workouts land, turns
/// success-green the moment the goal completes. The in-progress arc and track
/// follow the active accent palette; completion green is semantic and fixed.
/// Respects reduced motion.
class GoalRing extends StatelessWidget {
  final double progress;
  final double size;

  const GoalRing({super.key, required this.progress, this.size = 18});

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final accent = context.accent;
    return Semantics(
      label:
          'Weekly goal ${(progress.clamp(0.0, 1.0) * 100).round()}% complete',
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
        duration: disableAnimations
            ? Duration.zero
            : const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
        builder: (_, animated, __) => SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _RingPainter(
              progress: animated,
              complete: progress >= 1,
              arcColor: accent.base,
              trackColor: accent.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final bool complete;
  final Color arcColor;
  final Color trackColor;

  const _RingPainter({
    required this.progress,
    required this.complete,
    required this.arcColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1.5;

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = trackColor;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      final arcPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = complete ? AppColors.success : arcColor;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.complete != complete ||
      oldDelegate.arcColor != arcColor ||
      oldDelegate.trackColor != trackColor;
}
