import 'dart:async';
import 'package:flutter/material.dart';

/// One-shot entrance: a subtle fade + upward slide. Packages the app's
/// established entry idiom (see exercise_detail_screen.dart `_entryFade`):
/// easeOutCubic, Offset(0, 0.05) → zero, ~320ms, run once.
///
/// Reduced-motion safe: when MediaQuery.disableAnimations is true, the child is
/// shown at its final state on the first frame (FadeTransition.opacity == 1.0,
/// no slide, no delay).
///
/// [index] staggers items in a *bounded* list (delay = index * stagger, clamped
/// at maxStaggerIndex). The animation runs once and does NOT replay, so do not
/// wrap items inside a virtualized ListView.builder (they'd replay on scroll) —
/// use a single EntranceFade around the whole list instead.
class EntranceFade extends StatefulWidget {
  const EntranceFade({
    super.key,
    required this.child,
    this.index = 0,
    this.duration = const Duration(milliseconds: 320),
    this.stagger = const Duration(milliseconds: 60),
    this.maxStaggerIndex = 6,
    this.offset = const Offset(0, 0.05),
  });

  final Widget child;
  final int index;
  final Duration duration;
  final Duration stagger;
  final int maxStaggerIndex;
  final Offset offset;

  @override
  State<EntranceFade> createState() => _EntranceFadeState();
}

class _EntranceFadeState extends State<EntranceFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _curved =
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
  bool _started = false;
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1.0;
      return;
    }
    final clamped = widget.index < widget.maxStaggerIndex
        ? widget.index
        : widget.maxStaggerIndex;
    final delay = widget.stagger * clamped;
    if (delay == Duration.zero) {
      _controller.forward();
    } else {
      _timer = Timer(delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curved,
      child: SlideTransition(
        position: Tween<Offset>(begin: widget.offset, end: Offset.zero)
            .animate(_curved),
        child: widget.child,
      ),
    );
  }
}
