import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:gymlog/core/models/pr_card_data.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/core/theme/theme_palette.dart';
import 'share_card_watermark.dart';

/// Variant B: "The Split Arc / Technical"
///
/// SPECIFICATION:
/// - Tonal surface background (#0D0D0D) with subtle gradient and technical grid language.
/// - Geometric progress arc in the user's reactive accent.
/// - Immutable gold (#E6C84A) on the PR trophy/badge.
/// - Structured data blocks for secondary witnesses (Delta, Volume, Plate breakdown).
class ShareCardTechnical extends StatelessWidget {
  final PrCardData data;

  const ShareCardTechnical({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final accent = context.accent;

    return Container(
      width: 360,
      height: 640,
      decoration: const BoxDecoration(
        color: AppColors.bgBase,
      ),
      child: Stack(
        children: [
          // Elevated inner technical plate
          Positioned(
            top: 60,
            left: 16,
            right: 16,
            bottom: 60,
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.cardGradient,
                borderRadius: AppRadius.cardAll,
                border: Border.all(
                  color: AppColors.borderSubtle,
                  width: 1,
                ),
              ),
            ),
          ),

          // Safe-zone bounded column
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 84, 28, 127),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ── Technical Top Header ───────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Immutable Gold PR Tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: kRewardGold.withValues(alpha: 0.15),
                        borderRadius: AppRadius.badgeAll,
                        border: Border.all(
                          color: kRewardGold.withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.military_tech_rounded,
                            size: 13,
                            color: kRewardGold,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            data.metricLabel.toUpperCase(),
                            style: AppText.badge(
                              color: kRewardGold,
                            ).copyWith(
                              fontSize: 9.5,
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Series / Date Marker
                    if (data.privacy.showDate)
                      Text(
                        data.formattedDate,
                        style: AppText.caption(
                          color: AppColors.textTertiary,
                        ).copyWith(
                          fontSize: 10,
                          letterSpacing: 0.8,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                  ],
                ),

                // ── Hero Section with Accent Arc ───────────────────────────
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer accent hairline arc
                    CustomPaint(
                      size: const Size(200, 200),
                      painter: _TechnicalArcPainter(
                        accentColor: accent.base,
                        trackColor: accent.muted,
                      ),
                    ),

                    // Centered stats block
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            data.exerciseName.toUpperCase(),
                            style: AppText.label(
                              color: AppColors.textSecondary,
                              letterSpacing: 1.2,
                            ).copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
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
                                    fontSize: 52,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    fontFeatures: [
                                      FontFeature.tabularFigures()
                                    ],
                                    letterSpacing: -1.0,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  data.heroUnit,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: accent.light,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            data.contextText,
                            style: AppText.caption(
                              color: AppColors.textSecondary,
                            ).copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // ── Technical Spec Grid / Witnesses ────────────────────────
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface3,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.borderSubtle,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Metric 1: Threshold / Milestone
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MILESTONE',
                              style: AppText.columnHeader(
                                color: AppColors.textTertiary,
                              ).copyWith(fontSize: 8.5),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              data.milestoneTag ?? 'PERSONAL BEST',
                              style: AppText.statValue(
                                color: AppColors.textPrimary,
                              ).copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 24,
                        width: 1,
                        color: AppColors.borderDefault,
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      // Metric 2: Volume / Streak / Context
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data.streakDays != null
                                  ? 'CONSISTENCY'
                                  : data.totalVolumeKg != null
                                      ? 'SESSION VOLUME'
                                      : 'CONTEXT',
                              style: AppText.columnHeader(
                                color: AppColors.textTertiary,
                              ).copyWith(fontSize: 8.5),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              data.streakDays != null
                                  ? '${data.streakDays} DAYS'
                                  : data.totalVolumeKg != null
                                      ? '${data.totalVolumeKg!.toInt()} KG'
                                      : (data.privacy.showBodyweight &&
                                              data.bodyweightKg != null)
                                          ? 'BW ${data.bodyweightKg!.toStringAsFixed(1)} KG'
                                          : 'LOGGED RECORD',
                              style: AppText.statValue(
                                color: accent.light,
                              ).copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── DELT Watermark Anchored in Safe Band ────────────────────────
          const Positioned(
            left: 0,
            right: 0,
            bottom: 132,
            child: ShareCardWatermark(
              subtitle: 'PERFORMANCE MATRIX',
            ),
          ),
        ],
      ),
    );
  }
}

class _TechnicalArcPainter extends CustomPainter {
  final Color accentColor;
  final Color trackColor;

  const _TechnicalArcPainter({
    required this.accentColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Track circle
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, radius, trackPaint);

    // Accent sweeping arc (270 degrees)
    final arcPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      1.5 * math.pi,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TechnicalArcPainter oldDelegate) {
    return oldDelegate.accentColor != accentColor ||
        oldDelegate.trackColor != trackColor;
  }
}
