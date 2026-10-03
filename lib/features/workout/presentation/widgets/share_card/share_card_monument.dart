import 'package:flutter/material.dart';
import 'package:gymlog/core/models/pr_card_data.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/core/theme/theme_palette.dart';
import 'share_card_watermark.dart';

/// Variant A: "The Iron Record / Minimal Monument"
///
/// SPECIFICATION:
/// - Stark OLED true black (#000000).
/// - Content strictly centered within safe area (top 84pt, bottom 127pt).
/// - Gold (#E6C84A) used exclusively for the PR badge / trophy marker.
/// - Reactive accent (`context.accent`) for kicker and atmospheric tints.
/// - Massive tabular figures with unit scaled to ~38% cap-height.
class ShareCardMonument extends StatelessWidget {
  final PrCardData data;

  const ShareCardMonument({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final accent = context.accent;

    return Container(
      width: 360,
      height: 640,
      color: AppColors.bgBase,
      child: Stack(
        children: [
          // Subtle atmospheric background glow from the reactive accent
          Positioned(
            top: 140,
            left: 60,
            right: 60,
            height: 240,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.glow,
                ),
              ),
            ),
          ),

          // Safe-zone bounded column
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 84, 24, 127),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ── Top Header / Milestone Kicker ──────────────────────────
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // PR Badge with immutable Gold
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: kRewardGold.withValues(alpha: 0.15),
                        borderRadius: AppRadius.badgeAll,
                        border: Border.all(
                          color: kRewardGold.withValues(alpha: 0.40),
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
                          const SizedBox(width: 6),
                          Text(
                            data.metricLabel.toUpperCase(),
                            style: AppText.badge(
                              color: kRewardGold,
                            ).copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (data.milestoneTag != null)
                      Text(
                        data.milestoneTag!,
                        style: AppText.label(
                          color: accent.light,
                          letterSpacing: 1.5,
                        ).copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),

                // ── Central Monument: Exercise Name & Massive Numeral ───────
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      data.exerciseName.toUpperCase(),
                      style: AppText.label(
                        color: AppColors.textSecondary,
                        letterSpacing: 1.4,
                      ).copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),

                    // Hero Stat with Tabular Figures
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
                              fontSize: 64,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              fontFeatures: [FontFeature.tabularFigures()],
                              letterSpacing: -1.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            data.heroUnit,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              fontFeatures: [FontFeature.tabularFigures()],
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Delta Context
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surface3,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        data.contextText,
                        style: AppText.caption(
                          color: accent.light,
                        ).copyWith(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),

                // ── Bottom Witness Row & Watermark ─────────────────────────
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (data.privacy.showDate)
                          Text(
                            data.formattedDate,
                            style: AppText.caption(
                              color: AppColors.textTertiary,
                            ).copyWith(
                              fontSize: 10.5,
                              letterSpacing: 0.8,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                        if (data.privacy.showDate &&
                            (data.privacy.showBodyweight &&
                                    data.bodyweightKg != null ||
                                data.privacy.showName &&
                                    data.lifterName != null))
                          const Text(
                            '·',
                            style: TextStyle(color: AppColors.textTertiary),
                          ),
                        if (data.privacy.showBodyweight &&
                            data.bodyweightKg != null)
                          Text(
                            'BW ${data.bodyweightKg!.toStringAsFixed(1)} KG',
                            style: AppText.caption(
                              color: AppColors.textTertiary,
                            ).copyWith(
                              fontSize: 10.5,
                              letterSpacing: 0.8,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                        if (data.privacy.showName &&
                            data.lifterName != null) ...[
                          const Text(
                            '·',
                            style: TextStyle(color: AppColors.textTertiary),
                          ),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 160),
                            child: Text(
                              data.lifterName!.toUpperCase(),
                              style: AppText.caption(
                                color: AppColors.textTertiary,
                              ).copyWith(
                                fontSize: 10.5,
                                letterSpacing: 0.8,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(
                      color: AppColors.borderSubtle,
                      height: 1,
                      thickness: 1,
                    ),
                    const SizedBox(height: 14),
                    const ShareCardWatermark(
                      subtitle: 'IRON RECORD',
                    ),
                  ],
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
