import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/features/auth/presentation/providers/tour_provider.dart';
import 'package:gymlog/shared/widgets/motion/pressable_scale.dart';

class SpotlightTourOverlay extends ConsumerStatefulWidget {
  final GlobalKey targetKey;
  final String title;
  final String description;
  final int step;
  final Axis balloonPosition; // Force balloon to be top or bottom if needed

  /// Radius of the rounded cut-out around the target. Match the target widget
  /// (e.g. [AppRadius.card] for cards) so the spotlight reads as a crisp focus.
  final double borderRadius;

  const SpotlightTourOverlay({
    super.key,
    required this.targetKey,
    required this.title,
    required this.description,
    required this.step,
    this.balloonPosition = Axis.vertical,
    this.borderRadius = 12,
  });

  @override
  ConsumerState<SpotlightTourOverlay> createState() =>
      _SpotlightTourOverlayState();
}

class _SpotlightTourOverlayState extends ConsumerState<SpotlightTourOverlay>
    with SingleTickerProviderStateMixin {
  Rect? _targetRect;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  int _resolveAttempts = 0;
  int _loadingAttempts = 0;
  bool _scrolledToVisible = false;
  bool _isLooping = false;

  /// True once the anchor has failed to resolve for [_maxResolveAttempts].
  ///
  /// This used to call `nextStep()` instead, which is how the tour deleted its
  /// own steps: an anchor that is simply not on this shelf (the Explore anchor
  /// lives on the Routines list; arrive on Programs and it never mounts) burned
  /// step 1, then step 2 on the same missing anchor, and dropped the user into
  /// Settings about a second after they arrived. A step that cannot point at
  /// anything degrades to a centered card — it never disappears.
  bool _unresolved = false;

  /// Consecutive frames the resolved target rect has been unchanged.
  int _stableFrameCount = 0;

  static const _maxResolveAttempts = 10;

  /// Once the target rect has been stable for this many consecutive frames,
  /// stop re-measuring on every single frame and fall back to polling every
  /// [_slowPollInterval] instead. Re-running findRenderObject/localToGlobal/
  /// globalToLocal on every frame for the entire (potentially indefinite)
  /// lifetime of a tour step is unnecessary CPU/battery cost once layout has
  /// settled — most targets (cards, buttons) never move again after the
  /// initial scroll-into-view settles.
  static const _fastPollStableFrames = 12;
  static const _slowPollInterval = Duration(milliseconds: 400);

  /// Whether this overlay's own route is the one the user is looking at.
  ///
  /// Defaults to true when there is no enclosing [ModalRoute] (widget tests
  /// that pump the overlay directly), so this guard can only ever suppress a
  /// genuinely backgrounded overlay.
  bool get _hostRouteIsCurrent => ModalRoute.of(context)?.isCurrent ?? true;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _startLoopIfNeeded();
  }

  @override
  void didUpdateWidget(SpotlightTourOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    final activeStep = ref.read(firstRunTourProvider);
    if (activeStep == widget.step) {
      _startLoopIfNeeded();
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _startLoopIfNeeded() {
    if (!_isLooping && mounted) {
      _isLooping = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loop());
    }
  }

  void _loop() {
    if (!mounted) {
      _isLooping = false;
      return;
    }

    final activeStep = ref.read(firstRunTourProvider);
    if (activeStep != widget.step) {
      _scrolledToVisible = false;
      _resolveAttempts = 0;
      _stableFrameCount = 0;
      _unresolved = false;
      if (_targetRect != null) {
        setState(() {
          _targetRect = null;
        });
      }
      if (activeStep > widget.step) {
        _isLooping = false;
        return; // Stop looping when tour completed past this step
      }
      if (activeStep == -1) {
        _loadingAttempts++;
        if (_loadingAttempts >= 5) {
          _isLooping = false;
          return; // Stop looping after 500ms of actual -1 (completed/skipped)
        }
        Future.delayed(const Duration(milliseconds: 100), _loop);
        return;
      }
      _isLooping = false;
      return;
    }

    // Reset loading attempts when active
    _loadingAttempts = 0;

    // A pushed route (program detail, routine detail, a modal sheet) owns the
    // screen. Measuring, scroll-into-viewing or advancing from a backgrounded
    // host fights the route the user is actually looking at — and it is what
    // let two hosts drive the same step at once.
    if (!_hostRouteIsCurrent) {
      Future.delayed(_slowPollInterval, _loop);
      return;
    }

    final targetCtx = widget.targetKey.currentContext;
    if (targetCtx != null) {
      if (!_scrolledToVisible) {
        _scrolledToVisible = true;
        final disableAnim = MediaQuery.disableAnimationsOf(targetCtx);
        Scrollable.ensureVisible(
          targetCtx,
          duration:
              disableAnim ? Duration.zero : const Duration(milliseconds: 250),
          alignment: 0.5,
        );
      }
    }

    final targetBox = targetCtx?.findRenderObject() as RenderBox?;
    final selfBox = context.findRenderObject() as RenderBox?;
    if (targetBox != null &&
        targetBox.hasSize &&
        selfBox != null &&
        selfBox.hasSize) {
      // The anchor showed up after all (tab switch, list finished building):
      // upgrade the fallback card back into a real spotlight in place.
      _unresolved = false;

      final globalTopLeft = targetBox.localToGlobal(Offset.zero);
      final localTopLeft = selfBox.globalToLocal(globalTopLeft);
      final newRect = localTopLeft & targetBox.size;
      if (newRect != _targetRect) {
        _stableFrameCount = 0;
        setState(() {
          _targetRect = newRect;
        });
        _fadeIn();
      } else {
        _stableFrameCount++;
      }

      if (_stableFrameCount < _fastPollStableFrames) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _loop());
      } else {
        // Layout has settled — poll infrequently instead of re-measuring on
        // every single frame for as long as this step stays on screen.
        Future.delayed(_slowPollInterval, _loop);
      }
    } else {
      _resolveAttempts++;
      if (_resolveAttempts >= _maxResolveAttempts) {
        // Do NOT advance. Show the step without a cut-out and keep watching:
        // silently eating the step is strictly worse than pointing at nothing.
        if (!_unresolved) {
          setState(() {
            _unresolved = true;
          });
          _fadeIn();
        }
        Future.delayed(_slowPollInterval, _loop);
        return;
      }
      Future.delayed(const Duration(milliseconds: 100), _loop);
    }
  }

  void _fadeIn() {
    if (_fadeCtrl.status != AnimationStatus.dismissed) return;
    if (!MediaQuery.disableAnimationsOf(context)) {
      _fadeCtrl.forward();
    } else {
      _fadeCtrl.value = 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeStep = ref.watch(firstRunTourProvider);
    if (activeStep == widget.step) {
      _startLoopIfNeeded();
    }
    if (activeStep != widget.step) {
      return const SizedBox.shrink();
    }

    // Only the route the user is on may draw a tour layer. Previously a host
    // sitting underneath a pushed route kept its scrim and its four full-bleed
    // touch interceptors alive, so opening a program detail from Explore gave
    // two stacked dark layers and taps that landed on the wrong balloon.
    if (!_hostRouteIsCurrent) {
      return const SizedBox.shrink();
    }

    if (_targetRect == null && !_unresolved) {
      return const SizedBox.shrink();
    }

    final size = MediaQuery.sizeOf(context);
    final isLastStep = widget.step >= FirstRunTourNotifier.totalSteps - 1;

    // No anchor on this screen: keep the step, drop the cut-out. The user
    // still gets the copy, the step counter and Next — just no false
    // highlight around a widget that is not there.
    if (_targetRect == null) {
      return Semantics(
        container: true,
        liveRegion: true,
        label: '${widget.title}. ${widget.description}',
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Stack(
            children: [
              Positioned.fill(
                child: ExcludeSemantics(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.55),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _balloon(isLastStep: isLastStep),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final accent = context.accent;

    // Padding inflation around target
    final target = _targetRect!.inflate(8);

    // Determine vertical balloon placement
    final targetCenterY = target.center.dy;
    final isBalloonBelow = targetCenterY < size.height * 0.55;

    // Semantics: the interceptors below have no visible content and must not
    // leave stray, unlabeled tappable nodes in the accessibility tree (a
    // screen-reader user swiping through the screen would otherwise land on
    // silent "buttons" that do nothing). The whole region is announced as a
    // single live-region label instead, matching the Semantics conventions
    // already used elsewhere in this codebase (see e.g. _ImportPill,
    // _FeaturedCard) which this file previously had none of.
    return Semantics(
      container: true,
      liveRegion: true,
      label: '${widget.title}. ${widget.description}',
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Stack(
          children: [
            // Custom Painter for the dark mask and circular cut-out
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _SpotlightMaskPainter(
                    targetRect: target,
                    overlayColor: Colors.black.withValues(alpha: 0.55),
                    borderRadius: widget.borderRadius,
                    accentColor: accent.base,
                  ),
                ),
              ),
            ),

            // Touch interceptor: top block
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: target.top > 0 ? target.top : 0,
              child: ExcludeSemantics(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {},
                ),
              ),
            ),
            // Touch interceptor: bottom block
            Positioned(
              left: 0,
              right: 0,
              top: target.bottom < size.height ? target.bottom : size.height,
              bottom: 0,
              child: ExcludeSemantics(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {},
                ),
              ),
            ),
            // Touch interceptor: left block
            Positioned(
              left: 0,
              width: target.left > 0 ? target.left : 0,
              top: target.top,
              height: target.height,
              child: ExcludeSemantics(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {},
                ),
              ),
            ),
            // Touch interceptor: right block
            Positioned(
              left: target.right < size.width ? target.right : size.width,
              right: 0,
              top: target.top,
              height: target.height,
              child: ExcludeSemantics(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {},
                ),
              ),
            ),

            // Balloon Card
            Positioned(
              left: 20,
              right: 20,
              top: isBalloonBelow ? target.bottom + 16 : null,
              bottom: !isBalloonBelow ? (size.height - target.top) + 16 : null,
              child: _balloon(isLastStep: isLastStep),
            ),
          ],
        ),
      ),
    );
  }

  /// The step card. Shared by the spotlight layout and the no-anchor fallback
  /// so the two can never drift apart.
  Widget _balloon({required bool isLastStep}) {
    final surface = context.surface;
    final accent = context.accent;

    return PressableScale(
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: surface.surface2,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: accent.light.withValues(alpha: 0.22),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 32,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: accent.glow.withValues(alpha: 0.08),
                blurRadius: 48,
                spreadRadius: -4,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Top row: step pill + Skip ──────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Step indicator pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accent.base.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      'STEP ${widget.step + 1} OF ${FirstRunTourNotifier.totalSteps}',
                      style:
                          AppText.caption(color: accent.light).copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  // Skip tour
                  TextButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      ref.read(firstRunTourProvider.notifier).skipOrEnd();
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Skip tour',
                      style: AppText.caption(color: surface.textTertiary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Title ──────────────────────────────────────────────
              Text(
                widget.title,
                style: AppText.body(color: surface.textPrimary).copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 6),

              // ── Description ───────────────────────────────────────
              Text(
                widget.description,
                style: AppText.caption(color: surface.textSecondary)
                    .copyWith(height: 1.40),
              ),
              const SizedBox(height: 16),

              // ── Next / Got it button ───────────────────────────────
              // Semantics(button: true) added explicitly: unlike
              // TextButton above, a raw Material+InkWell does not
              // expose a button role to screen readers on its own.
              Semantics(
                button: true,
                label: isLastStep ? 'Got it' : 'Next',
                child: SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: Material(
                    color: accent.base,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref.read(firstRunTourProvider.notifier).nextStep();
                      },
                      child: Center(
                        child: Text(
                          isLastStep ? 'Got it' : 'Next',
                          style: AppText.button(color: accent.onAccent)
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpotlightMaskPainter extends CustomPainter {
  final Rect targetRect;
  final Color overlayColor;
  final double borderRadius;
  final Color accentColor;

  const _SpotlightMaskPainter({
    required this.targetRect,
    required this.overlayColor,
    required this.borderRadius,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Bound the offscreen layer to the widget size to avoid the unbounded
    // saveLayer perf/flicker foot-gun.
    canvas.saveLayer(Offset.zero & size, Paint());

    // 1. Draw solid overlay
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = overlayColor,
    );

    // 2. Cut out rounded rectangle representing target
    final rrect = RRect.fromRectAndRadius(
      targetRect,
      Radius.circular(borderRadius),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..blendMode = BlendMode.dstOut
        ..color = Colors.white,
    );

    // 3. Subtle accent ring around the spotlight edge so the highlighted
    // element is obvious even against a lighter scrim.
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = accentColor
        ..strokeWidth = 2,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SpotlightMaskPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.overlayColor != overlayColor ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.accentColor != accentColor;
  }
}
