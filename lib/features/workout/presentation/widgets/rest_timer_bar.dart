import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/features/workout/presentation/providers/rest_timer_provider.dart';

/// Compact floating rest-timer tile shown in the Active Workout's
/// `bottomNavigationBar`. It does NOT take over the screen — the content
/// height is HARD-BOUNDED to [kRestTileHeight] so it can never stretch,
/// no matter what constraints an ancestor passes down.
const double kRestTileHeight = 64;

class RestTimerBar extends ConsumerWidget {
  final RestTimerState state;

  const RestTimerBar({super.key, required this.state});

  String get _label {
    final m = state.remainingSeconds ~/ 60;
    final s = state.remainingSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(restTimerProvider.notifier);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        // Fixed height — the single guarantee that this tile stays a tile.
        child: SizedBox(
          height: kRestTileHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF15101D), Color(0xFF0B0B0D)],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.accentPrimary.withValues(alpha: 0.30),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  SizedBox(
                    width: 34,
                    height: 34,
                    child: CustomPaint(
                      painter: _RestRingPainter(progress: state.progress),
                      child: const Center(
                        child: Icon(Icons.timer_outlined,
                            size: 14, color: Color(0xFFCBB2FF)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'REST',
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        _label,
                        style: GoogleFonts.inter(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _RestAction(
                    label: '+15s',
                    onTap: () {
                      HapticFeedback.selectionClick();
                      notifier.addSeconds(15);
                    },
                  ),
                  const SizedBox(width: 8),
                  _RestAction(
                    label: 'Skip',
                    emphasized: true,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      notifier.skip();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RestAction extends StatelessWidget {
  final String label;
  final bool emphasized;
  final VoidCallback onTap;

  const _RestAction({
    required this.label,
    this.emphasized = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: emphasized
          ? AppColors.accentPrimary.withValues(alpha: 0.16)
          : Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color:
                  emphasized ? const Color(0xFFCBB2FF) : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _RestRingPainter extends CustomPainter {
  final double progress;
  _RestRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white.withValues(alpha: 0.10),
    );
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = AppColors.accentPrimary,
      );
    }
  }

  @override
  bool shouldRepaint(_RestRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
