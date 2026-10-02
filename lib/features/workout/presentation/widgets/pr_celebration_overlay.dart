import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymlog/core/models/personal_record.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/core/utils/units.dart';
import 'package:gymlog/core/utils/formatters.dart';

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
  List<PrRecord> prs, {
  String weightUnit = 'kg',
}) {
  if (prs.isEmpty) return Future.value();
  HapticFeedback.heavyImpact();

  // Honor OS reduce-motion: no scale/fade entrance, no confetti.
  final reduceMotion = MediaQuery.disableAnimationsOf(context);

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Personal record celebration',
    barrierColor: context.surface.bgBase.withValues(alpha: 0.82),
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
    pageBuilder: (dialogCtx, _, __) => _PrCelebration(
        prs: prs, reduceMotion: reduceMotion, weightUnit: weightUnit),
  );
}

class _PrCelebration extends StatefulWidget {
  final List<PrRecord> prs;
  final bool reduceMotion;
  final String weightUnit;
  const _PrCelebration(
      {required this.prs, this.reduceMotion = false, required this.weightUnit});

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

  @override
  Widget build(BuildContext context) {
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
          child: PrCelebrationCard(
            prs: widget.prs,
            weightUnit: widget.weightUnit,
            onKeepGoing: () {
              HapticFeedback.mediumImpact();
              Navigator.of(context).pop();
            },
          ),
        ),
      ],
    );
  }
}

/// The celebration card itself. Public so goldens and widget tests can render
/// it directly, and so the fit logic lives in one place:
///
/// - Fits ANY viewport: `SafeArea` + a max-height constraint keep the card
///   inside the screen (insets included), so short phones, landscape, large
///   text scales and edge-to-edge 3-button nav bars can never clip it.
/// - The PR list scrolls inside a `Flexible` region; the "Keep Going" CTA is
///   pinned below it and always visible.
class PrCelebrationCard extends StatelessWidget {
  final List<PrRecord> prs;
  final VoidCallback onKeepGoing;
  final String weightUnit;

  const PrCelebrationCard({
    super.key,
    required this.prs,
    required this.onKeepGoing,
    this.weightUnit = 'kg',
  });

  String _weightUnit({bool spoken = false}) => spoken
      ? (weightUnit == 'lbs' ? 'pounds' : 'kilograms')
      : unitLabel(weightUnit);

  String _recordLabel(PrRecord pr) => switch (pr.type) {
        PersonalRecordType.estimatedOneRepMax => 'Estimated 1RM',
        PersonalRecordType.maxWeight => 'Max weight',
        PersonalRecordType.maxReps => 'Max reps',
        PersonalRecordType.maxDuration => 'Max hold',
        PersonalRecordType.maxDistance => 'Max distance',
        PersonalRecordType.bestPace => 'Best pace',
      };

  String _recordValue(PrRecord pr, double value, {bool spoken = false}) {
    if (pr.type == PersonalRecordType.bestPace) {
      return MeasurementFormatter.formatPaceFromSecondsPerMeter(value,
          spoken: spoken);
    }
    if (pr.type == PersonalRecordType.estimatedOneRepMax ||
        pr.type == PersonalRecordType.maxWeight) {
      return '${formatWeight(value, weightUnit)} ${_weightUnit(spoken: spoken)}';
    }
    return '${value == value.truncateToDouble() ? value.toInt() : value.toStringAsFixed(1)} ${pr.unit}';
  }

  String _loggedSet(PrRecord pr, {bool spoken = false}) {
    final reps = pr.loggedReps;
    final load = pr.loggedWeightKg;
    if (reps == null) return 'Logged set unavailable';
    if (pr.type == PersonalRecordType.maxDistance ||
        pr.type == PersonalRecordType.bestPace) {
      return 'Logged: ${load ?? 0} m · $reps s';
    }
    if (pr.type == PersonalRecordType.maxDuration) {
      return 'Logged: $reps s hold';
    }
    if (load == null) return 'Logged: $reps reps';
    return 'Logged: ${formatWeight(load, weightUnit)} ${_weightUnit(spoken: spoken)} ${spoken ? 'for' : '×'} $reps reps';
  }

  @override
  Widget build(BuildContext context) {
    final title = prs.length == 1
        ? 'New Personal Record!'
        : '${prs.length} New Personal Records!';
    final accent = context.accent;
    final surface = context.surface;

    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    // 20dp breathing room above and below the system insets.
    final maxCardHeight = size.height - padding.top - padding.bottom - 40;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        28,
        padding.top + 20,
        28,
        padding.bottom + 20,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxCardHeight),
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 380),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            decoration: BoxDecoration(
              gradient: surface.isLight
                  ? AppColors.cardGradientLight
                  : AppColors.cardGradient,
              borderRadius: AppRadius.cardAll,
              border: Border.all(
                color: surface.borderSubtle,
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
                    color: accent.base.withValues(alpha: 0.16),
                    border: Border.all(
                      color: accent.base.withValues(alpha: 0.4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.base.withValues(alpha: 0.28),
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
                  // Never let the headline blow up the card: at extreme text
                  // scales on narrow phones the card must still fit its
                  // viewport, so wrap to at most 3 lines.
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.sectionHeading(color: surface.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  'A new record in your logged history.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.meta(color: surface.textSecondary),
                ),
                const SizedBox(height: 20),

                // ── PR rows: the list area is flexible — when the viewport is
                //    short it shrinks and the list scrolls; when there's room
                //    it caps at 240px so the card stays compact. ConstrainedBox
                //    MUST sit outside the scroll view: bounded-inside-bounded
                //    would force the row column and overflow it. ─────────────
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 240),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          for (final pr in prs)
                            Semantics(
                              label:
                                  '${pr.exerciseName}: ${_recordLabel(pr)}, ${_recordValue(pr, pr.value, spoken: true)}. '
                                  '${_loggedSet(pr, spoken: true)}. '
                                  '${pr.previousValue != null ? 'Previous: ${_recordValue(pr, pr.previousValue!, spoken: true)}' : 'First recorded result'}',
                              excludeSemantics: true,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: surface.surface3,
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
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppText.rowLabel(
                                                  color: surface.textPrimary),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _loggedSet(pr),
                                              style: AppText.caption(
                                                  color: surface.textSecondary),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(_recordLabel(pr),
                                              style: AppText.caption(
                                                  color:
                                                      surface.textSecondary)),
                                          // The beaten 1RM — the headline
                                          // number — in active accent.
                                          Text(
                                            _recordValue(pr, pr.value),
                                            style: AppText.value(
                                                color: accent.base),
                                          ),
                                          Text(
                                            pr.previousValue != null
                                                ? 'prev ${_recordValue(pr, pr.previousValue!)}'
                                                : 'first record',
                                            style: AppText.caption(
                                                color: surface.textSecondary),
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
                ),
                const SizedBox(height: 8),

                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 52),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onKeepGoing,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent.base,
                        foregroundColor: accent.onAccent,
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 52),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.buttonPrimaryAll,
                        ),
                      ),
                      child: Text(
                        'Keep Going',
                        style: AppText.button(color: accent.onAccent)
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
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
