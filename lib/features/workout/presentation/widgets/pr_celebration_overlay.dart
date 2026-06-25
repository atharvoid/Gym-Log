import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymlog/core/database/daos/workouts_dao.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';

/// Full-screen celebration shown when a finished workout contains PRs.
/// Turns a silent `is_pr = 1` database write into the app's best moment:
/// strong haptic, festive confetti, and the actual numbers that were beaten.
///
/// COLOR: a PR is a FIXED celebration identity — it does NOT follow the brand
/// accent. The badge ring, ambient halo, CTA and confetti use the immutable
/// reward gold (#E6C84A), while the trophy and the beaten 1RM numbers use the
/// same gold. A personal record always reads as a clean, triumphant gold
/// moment, in every palette.
///
/// Dependency-free — confetti is a lightweight CustomPainter, not a package.
Future<void> showPrCelebration(
  BuildContext context,
  List<PrRecord> prs,
) {
  if (prs.isEmpty) return Future.value();
  HapticFeedback.heavyImpact();

  // Honor OS reduce-motion: no scale/fade entrance, no confetti.
  final reduceMotion = MediaQuery.disableAnimationsOf(context);

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Personal record celebration',
    barrierColor: AppColors.bgBase.withValues(alpha: 0.82),
    transitionDuration:
        reduceMotion ? Duration.zero : const Duration(milliseconds: 260),
    transitionBuilder: reduceMotion
        ? (_, __, ___, child) => child
        : (_, animation, __, child) {
            final curved =
                CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: curved, child: child),
            );
          },
    pageBuilder: (dialogCtx, _, __) =>
        _PrCelebration(prs: prs, reduceMotion: reduceMotion),
  );
}

class _PrCelebration extends StatefulWidget {
  final List<PrRecord> prs;
  final bool reduceMotion;
  const _PrCelebration({required this.prs, this.reduceMotion = false});

  @override
  State<_PrCelebration> createState() => _PrCelebrationState();
}

class _PrCelebrationState extends State<_PrCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _confetti = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  @override
  void initState() {
    super.initState();
    // Reduce-motion: skip the confetti animation entirely.
    if (!widget.reduceMotion) _confetti.forward();
    // Double-pulse: the entry heavy impact is followed by a medium tap as
    // the card settles — the "rep lockout" feel.
    Future.delayed(const Duration(milliseconds: 240), () {
      if (mounted) HapticFeedback.mediumImpact();
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  String _fmtKg(double kg) => kg == kg.truncateToDouble()
      ? kg.toInt().toString()
      : kg.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final prs = widget.prs;
    final title = prs.length == 1
        ? 'New Personal Record!'
        : '${prs.length} New Personal Records!';

    return Stack(
      children: [
        // ── Confetti layer (skipped entirely under reduce-motion) ──────────
        if (!widget.reduceMotion)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _confetti,
                builder: (_, __) => CustomPaint(
                  painter: _ConfettiPainter(progress: _confetti.value),
                ),
              ),
            ),
          ),

        // ── Card ───────────────────────────────────────────────
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 380),
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                decoration: BoxDecoration(
                  gradient: AppColors.cardGradient,
                  borderRadius: AppRadius.cardAll,
                  border: Border.all(
                    color: AppColors.borderSubtle,
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        // Fixed reward magenta ring + ambient magenta halo —
                        // the celebration identity, palette-independent.
                        color: AppColors.accentReward.withValues(alpha: 0.16),
                        border: Border.all(
                          color: AppColors.accentReward.withValues(alpha: 0.4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppColors.accentReward.withValues(alpha: 0.28),
                            blurRadius: 28,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      // The trophy stays immutable gold — the achievement color.
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        color: AppColors.rewardGold,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AppText.sectionHeading(),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Stronger than every session before it.',
                      style: AppText.meta(),
                    ),
                    const SizedBox(height: 20),

                    // ── PR rows (max 4 visible, scrolls beyond) ───────────
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 240),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            for (final pr in prs)
                              Semantics(
                                label: '${pr.exerciseName}: '
                                    '${_fmtKg(pr.weightKg)} kilograms for ${pr.reps} reps, '
                                    'estimated one-rep max ${_fmtKg(pr.estimated1rm)} kilograms'
                                    '${pr.previousBest1rm > 0 ? ', up from ${_fmtKg(pr.previousBest1rm)} kilograms' : ', first record'}',
                                excludeSemantics: true,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 12),
                                    decoration: const BoxDecoration(
                                      color: AppColors.borderDefault,
                                      borderRadius: AppRadius.badgeAll,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                pr.exerciseName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppText.rowLabel(),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${_fmtKg(pr.weightKg)} kg × ${pr.reps} reps',
                                                style: AppText.caption(),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            // The beaten 1RM — the headline number
                                            // — in immutable achievement gold.
                                            Text(
                                              '${_fmtKg(pr.estimated1rm)} kg',
                                              style: AppText.value(
                                                  color: AppColors.rewardGold),
                                            ),
                                            Text(
                                              pr.previousBest1rm > 0
                                                  ? 'prev ${_fmtKg(pr.previousBest1rm)} kg'
                                                  : 'first 1RM',
                                              style: AppText.caption(),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.rewardGold,
                          foregroundColor: const Color(0xFF1C1C1E),
                          elevation: 0,
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.buttonPrimaryAll,
                          ),
                        ),
                        child: Text(
                          'Keep Going',
                          style: AppText.button(color: const Color(0xFF1C1C1E)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Confetti ─────────────────────────────────────────────

class _ConfettiPainter extends CustomPainter {
  final double progress;

  _ConfettiPainter({required this.progress});

  // Deterministic particle field — same seed every build, zero allocations
  // beyond the paint object per frame. The palette is intentionally
  // palette-INDEPENDENT (immutable celebration gold, white, and pale gold
  // highlight): a PR should read as a clean gold burst no matter which brand
  // accent the user picked.
  static final List<_Particle> _particles = _generate();

  static List<_Particle> _generate() {
    final rng = math.Random(7);
    const palette = [
      AppColors.rewardGold,
      AppColors.textPrimary,
      AppColors.rewardGold,
      Color(0xFFFFF1B8), // pale gold highlight
      AppColors.rewardGold,
      AppColors.textPrimary,
    ];
    return List.generate(64, (i) {
      return _Particle(
        x: rng.nextDouble(),
        delay: rng.nextDouble() * 0.35,
        speed: 0.65 + rng.nextDouble() * 0.55,
        drift: (rng.nextDouble() - 0.5) * 0.22,
        size: 4 + rng.nextDouble() * 5,
        spin: (rng.nextDouble() - 0.5) * 14,
        color: palette[i % palette.length],
        isCircle: i % 4 == 0,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in _particles) {
      final t = ((progress - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (t <= 0) continue;

      final opacity = t < 0.75 ? 1.0 : (1 - (t - 0.75) / 0.25);
      final dy = -0.05 + t * p.speed * 1.15;
      if (dy > 1.05) continue;

      final dx = p.x + math.sin(t * math.pi * 2) * p.drift;
      paint.color = p.color.withValues(alpha: opacity.clamp(0.0, 1.0));

      canvas.save();
      canvas.translate(dx * size.width, dy * size.height);
      canvas.rotate(t * p.spin);
      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset.zero, width: p.size, height: p.size * 0.62),
            const Radius.circular(1.5),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _Particle {
  final double x, delay, speed, drift, size, spin;
  final Color color;
  final bool isCircle;

  const _Particle({
    required this.x,
    required this.delay,
    required this.speed,
    required this.drift,
    required this.size,
    required this.spin,
    required this.color,
    required this.isCircle,
  });
}
