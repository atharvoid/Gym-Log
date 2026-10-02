import 'package:flutter/material.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';

/// Standardized DELT watermark for social share cards.
///
/// SPECIFICATION:
/// - 60% white (`AppColors.textSecondary`) for legibility post-compression.
/// - Distinctive geometric glyph (solid delta triangle) + DELT wordmark.
/// - Renders at ~28-32px cap-height in 1080×1920 (approx 10-11pt logical).
/// - Positioned strictly above the 126.7pt (380px) bottom Instagram exclusion zone.
class ShareCardWatermark extends StatelessWidget {
  final String subtitle;

  const ShareCardWatermark({
    super.key,
    this.subtitle = 'IRON RECORD',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Distinctive brand delta mark
            const CustomPaint(
              size: Size(12, 10),
              painter: _DeltaGlyphPainter(color: AppColors.textSecondary),
            ),
            const SizedBox(width: 6),
            Text(
              'DELT',
              style: AppText.label(
                color: AppColors.textSecondary,
                letterSpacing: 2.5,
              ).copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: AppText.caption(
            color: AppColors.textTertiary,
          ).copyWith(
            fontSize: 8.5,
            letterSpacing: 1.8,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DeltaGlyphPainter extends CustomPainter {
  final Color color;
  const _DeltaGlyphPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DeltaGlyphPainter oldDelegate) =>
      oldDelegate.color != color;
}
