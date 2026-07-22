import 'package:flutter/material.dart';

/// Three-tier screen classification matching Material 3 breakpoints.
///
/// | Class    | Width range  | Typical device                    |
/// |----------|-------------|-----------------------------------|
/// | compact  | < 360       | Small phones (iPhone SE, etc.)    |
/// | medium   | 360–600     | Large phones, phablets            |
/// | expanded | > 600       | Tablets, landscape, foldables     |
enum ScreenClass { compact, medium, expanded }

/// Responsive layout tokens derived from the current screen width.
class AdaptiveTokens {
  const AdaptiveTokens({
    required this.screenClass,
    required this.contentMaxWidth,
    required this.horizontalInset,
    required this.textScaleFactor,
  });

  final ScreenClass screenClass;
  final double contentMaxWidth;
  final double horizontalInset;
  final double textScaleFactor;

  bool get isCompact => screenClass == ScreenClass.compact;
  bool get isMedium => screenClass == ScreenClass.medium;
  bool get isExpanded => screenClass == ScreenClass.expanded;
}

/// Extension on [BuildContext] that provides responsive layout and
/// text-scaling primitives. Access via `context.adaptive.*`.
extension AdaptiveContext on BuildContext {
  AdaptiveTokens get adaptive {
    final width = MediaQuery.sizeOf(this).width;
    final textScale = MediaQuery.textScalerOf(this).scale(1.0);

    ScreenClass screenClass;
    double contentMaxWidth;
    double horizontalInset;

    if (width < 360) {
      screenClass = ScreenClass.compact;
      horizontalInset = 12;
      contentMaxWidth = width - horizontalInset * 2;
    } else if (width < 600) {
      screenClass = ScreenClass.medium;
      horizontalInset = 16;
      contentMaxWidth = 600 - horizontalInset * 2;
    } else {
      screenClass = ScreenClass.expanded;
      horizontalInset = 24;
      contentMaxWidth = (width - horizontalInset * 2).clamp(600, 800);
    }

    // Clamp text scale to a safe range — 1.4 is the max supported by all
    // production layouts. The OS can request up to 2.0 or higher, but above
    // 1.4 layouts break (clipped buttons, overflowing text fields).
    final clampedTextScale = textScale.clamp(1.0, 1.4);

    return AdaptiveTokens(
      screenClass: screenClass,
      contentMaxWidth: contentMaxWidth,
      horizontalInset: horizontalInset,
      textScaleFactor: clampedTextScale,
    );
  }
}
