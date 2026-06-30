import 'package:flutter/material.dart';

/// A press feedback wrapper that scales its child down while the pointer is
/// down, then springs back on release.
///
/// Uses a [Listener] so the wrapped widget keeps its own tap handler, ripple,
/// and haptics. When the user has reduced motion enabled, the scale animation
/// is disabled and the child stays at 1.0.
class PressableScale extends StatefulWidget {
  final Widget child;

  /// The scale applied while the pointer is down.
  final double pressedScale;

  /// When false the child stays at 1.0 and pointer events are ignored.
  final bool enabled;

  final Duration duration;
  final Curve curve;

  const PressableScale({
    super.key,
    required this.child,
    this.pressedScale = 0.96,
    this.enabled = true,
    this.duration = const Duration(milliseconds: 110),
    this.curve = Curves.easeOut,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disabled = MediaQuery.disableAnimationsOf(context);
    return Listener(
      onPointerDown:
          widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onPointerUp:
          widget.enabled ? (_) => setState(() => _pressed = false) : null,
      onPointerCancel:
          widget.enabled ? (_) => setState(() => _pressed = false) : null,
      behavior: HitTestBehavior.translucent,
      child: AnimatedScale(
        scale: _pressed && !disabled ? widget.pressedScale : 1.0,
        duration: disabled ? Duration.zero : widget.duration,
        curve: widget.curve,
        child: widget.child,
      ),
    );
  }
}
