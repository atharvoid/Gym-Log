import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

/// [AppInfoText]
/// Tier 1 of the Three-Tier Visual Grammar (Inert Static Facts).
///
/// Use this for passive metadata and descriptions:
/// - Zero background
/// - Strictly NO border
/// - Zero padding (or typographic layout only)
/// - Joins multiple items with a typographic separator (default: ` · `)
///
/// Examples:
/// - `4 exercises · 45 mins`
/// - `Chest · Triceps · Shoulders`
/// - `Day 1 of PPL`
class AppInfoText extends StatelessWidget {
  /// The list of text segments to display.
  final List<String> items;

  /// Separator string placed between non-empty items. Defaults to `' · '`.
  final String separator;

  /// Optional text style override. If omitted, uses [AppText.meta] tinted with
  /// `context.surface.textSecondary`.
  final TextStyle? style;

  /// Maximum lines to show before clipping/ellipsis.
  final int? maxLines;

  /// Overflow behavior.
  final TextOverflow overflow;

  const AppInfoText({
    super.key,
    required this.items,
    this.separator = ' · ',
    this.style,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
  });

  /// Single text convenience constructor.
  AppInfoText.single(
    String text, {
    super.key,
    this.style,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
  })  : items = [text],
        separator = '';

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    final effectiveStyle = style ?? AppText.meta(color: surface.textSecondary);

    final cleanItems = items
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList(growable: false);

    if (cleanItems.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayText = cleanItems.join(separator);

    return Text(
      displayText,
      maxLines: maxLines,
      overflow: overflow,
      style: effectiveStyle,
    );
  }
}
