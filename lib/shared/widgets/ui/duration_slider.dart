import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/dynamic_accent_theme.dart';

/// [duration_slider.dart]
/// A physical-feeling duration scrubber for rest periods.
///
/// WHY NOT `Slider`: Material's slider ships a 32dp pressed overlay, a value
/// indicator balloon, and its own theming surface — all of which have to be
/// fought back to neutral to match this app. More importantly it gives no
/// per-step haptic, and the detent haptic IS the interaction here: the reason a
/// slider beats a preset list is that your thumb can feel 5-second increments
/// without your eyes leaving the bar.
///
/// Contract:
/// - [valueSeconds] is snapped to [stepSeconds] by the caller's own state; this
///   widget always emits already-snapped values.
/// - [onChanged] fires continuously while dragging (cheap: it is just an int).
/// - [onChangeEnd] fires once on release — persist there, not in [onChanged],
///   so a single drag does not write to the DB 60 times.
class DurationSlider extends StatefulWidget {
  final int valueSeconds;
  final ValueChanged<int> onChanged;
  final ValueChanged<int>? onChangeEnd;
  final int minSeconds;
  final int maxSeconds;
  final int stepSeconds;

  /// Shown when the value is [minSeconds] and [minSeconds] is 0.
  final String zeroLabel;

  const DurationSlider({
    super.key,
    required this.valueSeconds,
    required this.onChanged,
    this.onChangeEnd,
    this.minSeconds = 0,
    this.maxSeconds = 600,
    this.stepSeconds = 5,
    this.zeroLabel = 'Off',
  });

  @override
  State<DurationSlider> createState() => _DurationSliderState();
}

class _DurationSliderState extends State<DurationSlider> {
  static const double _trackHeight = 6;
  static const double _thumbSize = 28;
  static const double _hitHeight = 56;

  bool _dragging = false;

  /// Horizontal inset the track is painted with, so the thumb never clips at
  /// either extreme. The usable track is (width - 2 * _thumbSize / 2).
  double get _inset => _thumbSize / 2;

  int get _span => widget.maxSeconds - widget.minSeconds;

  double get _fraction =>
      _span == 0 ? 0 : (widget.valueSeconds - widget.minSeconds) / _span;

  int _snap(int raw) {
    final steps = (raw / widget.stepSeconds).round();
    final snapped = steps * widget.stepSeconds;
    return snapped.clamp(widget.minSeconds, widget.maxSeconds);
  }

  void _emitFromDx(double dx, double width) {
    final usable = math.max(1.0, width - _inset * 2);
    final frac = ((dx - _inset) / usable).clamp(0.0, 1.0);
    final raw = widget.minSeconds + (frac * _span);
    final next = _snap(raw.round());
    if (next != widget.valueSeconds) {
      // One tick per detent crossed — this is the whole point of the control.
      HapticFeedback.selectionClick();
      widget.onChanged(next);
    }
  }

  void _nudge(int deltaSteps) {
    final next =
        _snap(widget.valueSeconds + deltaSteps * widget.stepSeconds);
    if (next != widget.valueSeconds) {
      HapticFeedback.selectionClick();
      widget.onChanged(next);
      widget.onChangeEnd?.call(next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.accent;
    final surface = context.surface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Live readout. Tabular figures so the number does not jitter while
        // dragging past a digit-width change (e.g. 9:55 -> 10:00).
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              formatDurationLabel(widget.valueSeconds,
                  zeroLabel: widget.zeroLabel),
              style: AppText.statNumber(color: surface.textPrimary).copyWith(
                color: widget.valueSeconds == 0
                    ? surface.textSecondary
                    : surface.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            if (widget.valueSeconds > 0)
              Text('min:sec',
                  style: AppText.caption(color: surface.textTertiary)),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return Semantics(
              slider: true,
              value: formatDurationLabel(widget.valueSeconds,
                  zeroLabel: widget.zeroLabel),
              increasedValue: formatDurationLabel(
                  _snap(widget.valueSeconds + widget.stepSeconds),
                  zeroLabel: widget.zeroLabel),
              decreasedValue: formatDurationLabel(
                  _snap(widget.valueSeconds - widget.stepSeconds),
                  zeroLabel: widget.zeroLabel),
              onIncrease: () => _nudge(1),
              onDecrease: () => _nudge(-1),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (d) => _emitFromDx(d.localPosition.dx, width),
                onTapUp: (_) => widget.onChangeEnd?.call(widget.valueSeconds),
                onHorizontalDragStart: (d) {
                  setState(() => _dragging = true);
                  _emitFromDx(d.localPosition.dx, width);
                },
                onHorizontalDragUpdate: (d) =>
                    _emitFromDx(d.localPosition.dx, width),
                onHorizontalDragEnd: (_) {
                  setState(() => _dragging = false);
                  HapticFeedback.lightImpact();
                  widget.onChangeEnd?.call(widget.valueSeconds);
                },
                onHorizontalDragCancel: () =>
                    setState(() => _dragging = false),
                child: SizedBox(
                  height: _hitHeight,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _TrackPainter(
                      fraction: _fraction,
                      accent: accent.base,
                      trackColor: surface.borderDefault,
                      tickColor: surface.textTertiary,
                      thumbBorder: surface.bgBase,
                      trackHeight: _trackHeight,
                      thumbSize: _thumbSize,
                      inset: _inset,
                      pressed: _dragging,
                      minorTickEvery: 30,
                      majorTickEvery: 60,
                      minSeconds: widget.minSeconds,
                      maxSeconds: widget.maxSeconds,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        // Scale endpoints — cheap orientation without cluttering the track.
        Padding(
          padding: EdgeInsets.symmetric(horizontal: _inset),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.minSeconds == 0
                    ? widget.zeroLabel
                    : formatDurationLabel(widget.minSeconds),
                style: AppText.caption(color: surface.textTertiary),
              ),
              Text(
                formatDurationLabel(widget.maxSeconds),
                style: AppText.caption(color: surface.textTertiary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// `90 -> "1:30"`, `0 -> zeroLabel`, `600 -> "10:00"`.
String formatDurationLabel(int seconds, {String zeroLabel = 'Off'}) {
  if (seconds <= 0) return zeroLabel;
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

class _TrackPainter extends CustomPainter {
  final double fraction;
  final Color accent;
  final Color trackColor;
  final Color tickColor;
  final Color thumbBorder;
  final double trackHeight;
  final double thumbSize;
  final double inset;
  final bool pressed;
  final int minorTickEvery;
  final int majorTickEvery;
  final int minSeconds;
  final int maxSeconds;

  _TrackPainter({
    required this.fraction,
    required this.accent,
    required this.trackColor,
    required this.tickColor,
    required this.thumbBorder,
    required this.trackHeight,
    required this.thumbSize,
    required this.inset,
    required this.pressed,
    required this.minorTickEvery,
    required this.majorTickEvery,
    required this.minSeconds,
    required this.maxSeconds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final left = inset;
    final right = size.width - inset;
    final usable = math.max(1.0, right - left);
    final thumbX = left + usable * fraction.clamp(0.0, 1.0);
    final radius = Radius.circular(trackHeight / 2);

    // Inactive track
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left, cy - trackHeight / 2, usable, trackHeight),
        radius,
      ),
      Paint()..color = trackColor,
    );

    // Detent ticks, drawn UNDER the active fill so the filled region reads as
    // one solid bar rather than a dotted one.
    final span = maxSeconds - minSeconds;
    if (span > 0) {
      for (int s = minSeconds; s <= maxSeconds; s += minorTickEvery) {
        final isMajor = s % majorTickEvery == 0;
        final x = left + usable * ((s - minSeconds) / span);
        final h = isMajor ? 9.0 : 5.0;
        canvas.drawLine(
          Offset(x, cy + trackHeight / 2 + 5),
          Offset(x, cy + trackHeight / 2 + 5 + h),
          Paint()
            ..color = tickColor.withValues(alpha: isMajor ? 0.55 : 0.28)
            ..strokeWidth = isMajor ? 1.5 : 1,
        );
      }
    }

    // Active fill
    if (thumbX > left) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
              left, cy - trackHeight / 2, thumbX - left, trackHeight),
          radius,
        ),
        Paint()..color = accent,
      );
    }

    // Pressed halo — confirms the grab without a Material overlay.
    if (pressed) {
      canvas.drawCircle(
        Offset(thumbX, cy),
        thumbSize * 0.85,
        Paint()..color = accent.withValues(alpha: 0.18),
      );
    }

    // Thumb: accent disc with a bgBase ring so it stays legible where it
    // overlaps its own active fill.
    canvas.drawCircle(
      Offset(thumbX, cy),
      thumbSize / 2,
      Paint()..color = thumbBorder,
    );
    canvas.drawCircle(
      Offset(thumbX, cy),
      thumbSize / 2 - 3,
      Paint()..color = accent,
    );
  }

  @override
  bool shouldRepaint(_TrackPainter old) =>
      old.fraction != fraction ||
      old.accent != accent ||
      old.pressed != pressed ||
      old.trackColor != trackColor;
}
