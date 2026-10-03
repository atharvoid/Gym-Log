import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/dynamic_accent_theme.dart';

/// [AppStatusTag]
/// Tier 2 of the Three-Tier Visual Grammar (Passive Readouts / Status Badges).
///
/// Use this for non-interactive status badges, categorizations, and passive readouts:
/// - Flat background tint
/// - Strictly NO border (enforces "Border = Clickable" invariant)
/// - NO affordance bait (no fake status dots or press ripples)
/// - Light-mode contrast aware
///
/// Examples:
/// - Muscle group tag: `Chest`
/// - Status badge: `Verified Match`, `Defaulted sets`
/// - Measurement readout: `100 kg` (when non-interactive)
class AppStatusTag extends StatelessWidget {
  /// The label displayed in the tag.
  final String label;

  /// Optional leading icon (e.g., checkmark for verified, alert for warning).
  final IconData? leadingIcon;

  /// Whether the tag uses the active theme's accent palette.
  final bool isAccented;

  /// Custom background color override. If null, automatically resolves based on
  /// [isAccented] and current [SurfaceTokens].
  final Color? backgroundColor;

  /// Custom text color override. If null, automatically resolves based on
  /// [isAccented] and current [SurfaceTokens].
  final Color? textColor;

  /// Optional custom padding. Defaults to `horizontal: 8, vertical: 3`.
  final EdgeInsetsGeometry padding;

  /// Optional custom border radius. Defaults to [AppRadius.badgeAll] (8px).
  final BorderRadiusGeometry borderRadius;

  const AppStatusTag({
    super.key,
    required this.label,
    this.leadingIcon,
    this.isAccented = false,
    this.backgroundColor,
    this.textColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    this.borderRadius = AppRadius.badgeAll,
  });

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    final accent = context.accent;

    final Color resolvedBg;
    final Color resolvedFg;

    if (backgroundColor != null && textColor != null) {
      resolvedBg = backgroundColor!;
      resolvedFg = textColor!;
    } else if (isAccented) {
      if (surface.isLight) {
        resolvedBg = backgroundColor ?? accent.base.withValues(alpha: 0.22);
        resolvedFg = textColor ?? accent.dark;
      } else {
        resolvedBg = backgroundColor ?? accent.base.withValues(alpha: 0.14);
        resolvedFg = textColor ?? accent.light;
      }
    } else {
      resolvedBg = backgroundColor ?? surface.surface3;
      resolvedFg = textColor ?? surface.textSecondary;
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: resolvedBg,
        borderRadius: borderRadius,
        // STRICT INVARIANT: Never declare a border on AppStatusTag.
        border: null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leadingIcon != null) ...[
            Icon(
              leadingIcon,
              size: 12,
              color: resolvedFg,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppText.badge(color: resolvedFg),
          ),
        ],
      ),
    );
  }
}
