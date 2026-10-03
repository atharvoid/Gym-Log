import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/dynamic_accent_theme.dart';
import '../../domain/hold_timer_state.dart';
import '../providers/hold_timer_provider.dart';

/// Floating hold-timer tile shown in Active Workout's `bottomNavigationBar`
/// when an isometric / duration exercise set is active.
///
/// Bounded strictly to [kHoldTileHeight] (84dp) matching [RestTimerBar] so it
/// never stretches or forces scroll jumps.
const double kHoldTileHeight = 84;

class HoldTimerBar extends ConsumerStatefulWidget {
  final HoldTimerState state;

  const HoldTimerBar({super.key, required this.state});

  @override
  ConsumerState<HoldTimerBar> createState() => _HoldTimerBarState();
}

class _HoldTimerBarState extends ConsumerState<HoldTimerBar> {
  double _scrubAccum = 0;
  bool _scrubbing = false;

  void _onScrubUpdate(DragUpdateDetails d) {
    _scrubAccum += d.delta.dx;
    const scrubPixelsPerStep = 15.0;
    const scrubStepSeconds = 5;
    final steps = (_scrubAccum / scrubPixelsPerStep).truncate();
    if (steps == 0) return;
    _scrubAccum -= steps * scrubPixelsPerStep;
    HapticFeedback.selectionClick();
    ref.read(holdTimerProvider.notifier).addSeconds(steps * scrubStepSeconds);
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(holdTimerProvider.notifier);
    final accent = context.accent.base;
    final surface = context.surface;
    final isPrep = widget.state.isPrep;
    final isPaused = widget.state.isPaused;
    final isOvertime = widget.state.isOvertime;
    final activeHue = isOvertime ? AppColors.rewardGold : accent;

    final headerText = isPrep
        ? 'GET READY'
        : widget.state.mode == HoldTimerMode.countdown
            ? 'TARGET ${widget.state.targetSeconds ?? 0}s'
            : 'HOLD · S${widget.state.setIndex + 1}';

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        child: Semantics(
          container: true,
          label:
              'Hold timer for ${widget.state.exerciseName}, set ${widget.state.setIndex + 1}, ${widget.state.formattedTime}.',
          child: GestureDetector(
            onHorizontalDragStart: (_) {
              _scrubAccum = 0;
              setState(() => _scrubbing = true);
            },
            onHorizontalDragUpdate: _onScrubUpdate,
            onHorizontalDragEnd: (_) {
              setState(() => _scrubbing = false);
              HapticFeedback.lightImpact();
            },
            onHorizontalDragCancel: () => setState(() => _scrubbing = false),
            child: _AmbientPulse(
              radius: AppRadius.cardAll,
              color: activeHue,
              child: SizedBox(
                height: kHoldTileHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color.alphaBlend(
                          activeHue.withValues(alpha: _scrubbing ? 0.26 : 0.16),
                          surface.bgBase,
                        ),
                        surface.bgBase,
                      ],
                    ),
                    borderRadius: AppRadius.cardAll,
                    border: Border.all(
                      color:
                          activeHue.withValues(alpha: _scrubbing ? 0.70 : 0.40),
                      width: 1.2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        // ── Left Ring Indicator ──
                        SizedBox(
                          width: 36,
                          height: 36,
                          child: CustomPaint(
                            painter: _HoldRingPainter(
                              progress: isPrep
                                  ? widget.state.prepSecondsRemaining / 3.0
                                  : widget.state.progress,
                              arcColor: activeHue,
                              trackColor: surface.borderDefault,
                            ),
                            child: Center(
                              child: isPrep
                                  ? Text(
                                      '${widget.state.prepSecondsRemaining}',
                                      style: AppText.value(
                                        color: accent,
                                      ).copyWith(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    )
                                  : Icon(
                                      Icons.timer_outlined,
                                      size: 16,
                                      color: activeHue,
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // ── Center Timer Label & Digits ──
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                headerText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.columnHeader(
                                  color: isOvertime
                                      ? AppColors.rewardGold
                                      : surface.textSecondary,
                                ),
                              ),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  widget.state.formattedTime,
                                  maxLines: 1,
                                  softWrap: false,
                                  style: AppText.timer(
                                    color: isOvertime
                                        ? AppColors.rewardGold
                                        : surface.textPrimary,
                                    shadows: AppText.depthFor(context),
                                  ).copyWith(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures()
                                    ],
                                    height: 1.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // ── Right Action Controls ──
                        if (isPrep) ...[
                          _HoldAction(
                            label: 'Skip',
                            emphasized: true,
                            accent: accent,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              notifier.skipPrep();
                            },
                          ),
                          const SizedBox(width: 6),
                          _HoldIconButton(
                            icon: Icons.close_rounded,
                            tooltip: 'Cancel timer',
                            onTap: () {
                              HapticFeedback.selectionClick();
                              notifier.cancel();
                            },
                          ),
                        ] else ...[
                          // Pause / Resume
                          _HoldIconButton(
                            icon: isPaused
                                ? Icons.play_arrow_rounded
                                : Icons.pause_rounded,
                            tooltip: isPaused ? 'Resume hold' : 'Pause hold',
                            accent: accent,
                            onTap: () {
                              if (isPaused) {
                                notifier.resume();
                              } else {
                                notifier.pause();
                              }
                            },
                          ),
                          const SizedBox(width: 6),
                          // Primary CTA: DONE
                          _HoldAction(
                            label: 'Done',
                            emphasized: true,
                            accent: activeHue,
                            onTap: () {
                              HapticFeedback.heavyImpact();
                              notifier.finishAndLog();
                            },
                          ),
                          const SizedBox(width: 6),
                          // Cancel
                          _HoldIconButton(
                            icon: Icons.close_rounded,
                            tooltip: 'Cancel timer',
                            onTap: () {
                              HapticFeedback.selectionClick();
                              notifier.cancel();
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HoldAction extends StatelessWidget {
  final String label;
  final bool emphasized;
  final VoidCallback onTap;
  final Color accent;

  const _HoldAction({
    required this.label,
    this.emphasized = false,
    required this.onTap,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: emphasized ? accent : context.surface.borderSubtle,
      borderRadius: BorderRadius.circular(AppRadius.buttonSecondary),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.buttonSecondary),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppText.statLabel(
              color: emphasized ? Colors.black : context.surface.textPrimary,
            ).copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _HoldIconButton extends StatelessWidget {
  final IconData icon;
  final String? tooltip;
  final VoidCallback onTap;
  final Color? accent;

  const _HoldIconButton({
    required this.icon,
    this.tooltip,
    required this.onTap,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    return Material(
      color: surface.borderSubtle,
      borderRadius: BorderRadius.circular(AppRadius.buttonSecondary),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.buttonSecondary),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 18,
            color: accent ?? surface.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _HoldRingPainter extends CustomPainter {
  final double progress;
  final Color arcColor;
  final Color trackColor;

  _HoldRingPainter({
    required this.progress,
    required this.arcColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 3.2;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track
    final trackPaint = Paint()
      ..color = trackColor.withValues(alpha: 0.25)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, trackPaint);

    // Active Arc
    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
    final arcPaint = Paint()
      ..color = arcColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _HoldRingPainter old) =>
      old.progress != progress ||
      old.arcColor != arcColor ||
      old.trackColor != trackColor;
}

class _AmbientPulse extends StatefulWidget {
  final Widget child;
  final BorderRadius radius;
  final Color color;

  const _AmbientPulse({
    required this.child,
    required this.radius,
    required this.color,
  });

  @override
  State<_AmbientPulse> createState() => _AmbientPulseState();
}

class _AmbientPulseState extends State<_AmbientPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: widget.radius,
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.16),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        child: widget.child,
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final alpha = 0.10 + 0.12 * _controller.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: widget.radius,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: alpha),
                blurRadius: 10 + 6 * _controller.value,
                spreadRadius: 0,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
