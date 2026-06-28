import 'package:flutter/widgets.dart';

/// [pressable_scale.dart]
/// PressableScale — the press-feedback half of the motion system (sibling to
/// EntranceFade). Wraps any tappable child and gently squeezes it while a
/// finger is held, then springs back on release.
///
/// PURELY VISUAL: it observes pointers via a [Listener] and never enters the
/// gesture arena, so the child's own InkWell / GestureDetector keeps full
/// ownership of the tap, ripple, and haptics — no double-handling.
///
/// Honors the OS "reduce motion" setting: the squeeze collapses to a no-op so
/// reduced-motion users get a perfectly still control.
class PressableScale extends StatefulWidget {
  final Widget child;

  /// Scale while pressed. 0.97 = a 3% squeeze (matches the original
  /// routine-launchpad feel).
  final double pressedScale;

  final Duration duration;
  final Curve curve;

  /// When false, the press-scale is disabled (e.g. a disabled button) — the
  /// child renders perfectly still.
  final bool enabled;

  const PressableScale({
    super.key,
    required this.child,
    this.pressedScale = 0.97,
    this.duration = const Duration(milliseconds: 150),
    this.curve = Curves.easeOutQuint,
    this.enabled = true,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    // Honor "reduce motion": no squeeze, no animation — a still control.
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final active = widget.enabled && !reduceMotion;
    final scale = active && _pressed ? widget.pressedScale : 1.0;

    return Listener(
      onPointerDown: active ? (_) => _setPressed(true) : null,
      onPointerUp: active ? (_) => _setPressed(false) : null,
      onPointerCancel: active ? (_) => _setPressed(false) : null,
      child: AnimatedScale(
        scale: scale,
        duration: reduceMotion ? Duration.zero : widget.duration,
        curve: widget.curve,
        child: widget.child,
      ),
    );
  }
}
