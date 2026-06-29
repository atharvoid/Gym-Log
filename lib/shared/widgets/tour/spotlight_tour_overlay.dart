import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/features/auth/presentation/providers/tour_provider.dart';

class SpotlightTourOverlay extends ConsumerStatefulWidget {
  final GlobalKey targetKey;
  final String title;
  final String description;
  final int step;
  final Axis balloonPosition; // Force balloon to be top or bottom if needed

  const SpotlightTourOverlay({
    super.key,
    required this.targetKey,
    required this.title,
    required this.description,
    required this.step,
    this.balloonPosition = Axis.vertical,
  });

  @override
  ConsumerState<SpotlightTourOverlay> createState() =>
      _SpotlightTourOverlayState();
}

class _SpotlightTourOverlayState extends ConsumerState<SpotlightTourOverlay> {
  Rect? _targetRect;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateRect());
  }

  void _updateRect() {
    if (!mounted) return;
    final context = widget.targetKey.currentContext;
    if (context == null) {
      Future.delayed(const Duration(milliseconds: 100), _updateRect);
      return;
    }
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      final offset = renderBox.localToGlobal(Offset.zero);
      setState(() {
        _targetRect = offset & renderBox.size;
      });
    } else {
      Future.delayed(const Duration(milliseconds: 100), _updateRect);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeStep = ref.watch(firstRunTourProvider);
    if (activeStep != widget.step || _targetRect == null) {
      return const SizedBox.shrink();
    }

    final surface = context.surface;
    final accent = context.accent;
    final size = MediaQuery.sizeOf(context);

    // Padding inflation around target
    final target = _targetRect!.inflate(6);

    // Determine vertical balloon placement
    final targetCenterY = target.center.dy;
    final isBalloonBelow = targetCenterY < size.height * 0.55;

    return Stack(
      children: [
        // Custom Painter for the dark mask and circular cut-out
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _SpotlightMaskPainter(
                targetRect: target,
                overlayColor: Colors.black.withValues(alpha: 0.75),
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
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
          ),
        ),
        // Touch interceptor: bottom block
        Positioned(
          left: 0,
          right: 0,
          top: target.bottom < size.height ? target.bottom : size.height,
          bottom: 0,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
          ),
        ),
        // Touch interceptor: left block
        Positioned(
          left: 0,
          width: target.left > 0 ? target.left : 0,
          top: target.top,
          height: target.height,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
          ),
        ),
        // Touch interceptor: right block
        Positioned(
          left: target.right < size.width ? target.right : size.width,
          right: 0,
          top: target.top,
          height: target.height,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
          ),
        ),

        // Balloon Card Positioned
        Positioned(
          left: 20,
          right: 20,
          top: isBalloonBelow ? target.bottom + 16 : null,
          bottom: !isBalloonBelow ? (size.height - target.top) + 16 : null,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: surface.surface2,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: accent.light.withValues(alpha: 0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'STEP ${widget.step + 1} OF 3',
                        style: AppText.caption(color: accent.light).copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
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
                  const SizedBox(height: 8),
                  Text(
                    widget.title,
                    style: AppText.body(color: surface.textPrimary).copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.description,
                    style: AppText.caption(color: surface.textSecondary)
                        .copyWith(height: 1.35),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SpotlightMaskPainter extends CustomPainter {
  final Rect targetRect;
  final Color overlayColor;

  const _SpotlightMaskPainter({
    required this.targetRect,
    required this.overlayColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(null, Paint());

    // 1. Draw solid overlay
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = overlayColor,
    );

    // 2. Cut out rounded rectangle representing target
    final rrect = RRect.fromRectAndRadius(
      targetRect,
      const Radius.circular(8),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..blendMode = BlendMode.dstOut
        ..color = Colors.white,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SpotlightMaskPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.overlayColor != overlayColor;
  }
}
