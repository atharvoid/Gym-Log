import 'package:flutter/material.dart';
import 'package:gymlog/core/models/pr_card_data.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/core/theme/theme_palette.dart';
import 'share_card_watermark.dart';

/// Variant C: "The Gym Photo Sticker"
///
/// SPECIFICATION:
/// - Fully transparent background (alpha = 0) designed to export as an alpha PNG.
/// - Concentrated, high-contrast dark plate / pill that floats over gym videos or mirror selfies.
/// - Gold (#E6C84A) trophy badge with reactive accent on hero highlight.
/// - Integrated DELT attribution within the sticker geometry so it travels with the sticker.
class ShareCardSticker extends StatelessWidget {
  final PrCardData data;

  const ShareCardSticker({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final accent = context.accent;

    return Container(
      width: 360,
      height: 640,
      color: Colors
          .transparent, // Crucial: transparent alpha canvas for sticker export
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Centered compact sticker capsule inside the safe zone
          Container(
            width: 300,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            decoration: BoxDecoration(
              color: const Color(
                  0xF20D0D0D), // 95% opacity near-black for punchy contrast
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 32,
                  spreadRadius: 4,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Top Bar: Gold PR Tag + Accent Kicker ───────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: kRewardGold.withValues(alpha: 0.18),
                        borderRadius: AppRadius.badgeAll,
                        border: Border.all(
                          color: kRewardGold.withValues(alpha: 0.45),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CustomPaint(
                            size: Size(13, 13),
                            painter: _TrophyGlyphPainter(color: kRewardGold),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            data.metricLabel.toUpperCase(),
                            style: AppText.badge(
                              color: kRewardGold,
                            ).copyWith(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (data.milestoneTag != null)
                      Text(
                        data.milestoneTag!,
                        style: AppText.label(
                          color: accent.light,
                          letterSpacing: 1.0,
                        ).copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Exercise Title ─────────────────────────────────────────
                Text(
                  data.exerciseName.toUpperCase(),
                  style: AppText.label(
                    color: AppColors.textSecondary,
                    letterSpacing: 1.2,
                  ).copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),

                // ── Hero Stat ──────────────────────────────────────────────
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        data.heroValue,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 54,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          fontFeatures: [FontFeature.tabularFigures()],
                          letterSpacing: -1.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        data.heroUnit,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: accent.light,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // ── Delta Badge ────────────────────────────────────────────
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surface3,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.borderSubtle,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    data.contextText,
                    style: AppText.caption(
                      color: AppColors.textPrimary,
                    ).copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Integrated Micro-Watermark ─────────────────────────────
                const Divider(
                  color: AppColors.borderSubtle,
                  height: 1,
                  thickness: 1,
                ),
                const SizedBox(height: 10),
                const ShareCardWatermark(
                  subtitle: 'LOGGED RESULT',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrophyGlyphPainter extends CustomPainter {
  final Color color;
  const _TrophyGlyphPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.2, h * 0.15)
      ..lineTo(w * 0.8, h * 0.15)
      ..quadraticBezierTo(w * 0.8, h * 0.65, w * 0.55, h * 0.7)
      ..lineTo(w * 0.55, h * 0.85)
      ..lineTo(w * 0.75, h * 0.85)
      ..lineTo(w * 0.75, h * 1.0)
      ..lineTo(w * 0.25, h * 1.0)
      ..lineTo(w * 0.25, h * 0.85)
      ..lineTo(w * 0.45, h * 0.85)
      ..lineTo(w * 0.45, h * 0.7)
      ..quadraticBezierTo(w * 0.2, h * 0.65, w * 0.2, h * 0.15)
      ..close();

    canvas.drawPath(path, paint);

    final handlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final leftHandle = Path()
      ..moveTo(w * 0.22, h * 0.25)
      ..cubicTo(w * 0.05, h * 0.25, w * 0.05, h * 0.55, w * 0.3, h * 0.55);
    canvas.drawPath(leftHandle, handlePaint);

    final rightHandle = Path()
      ..moveTo(w * 0.78, h * 0.25)
      ..cubicTo(w * 0.95, h * 0.25, w * 0.95, h * 0.55, w * 0.7, h * 0.55);
    canvas.drawPath(rightHandle, handlePaint);
  }

  @override
  bool shouldRepaint(covariant _TrophyGlyphPainter oldDelegate) =>
      oldDelegate.color != color;
}
