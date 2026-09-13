import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';

/// [DeltLogo]
/// The official brand mark for Delt: Pure Delta Wings (Δ).
/// Three athletic deltoid facets forming an upward progression Delta.
class DeltLogo extends StatelessWidget {
  final double size;
  final bool useAccentColor;
  final Color? color;

  const DeltLogo({
    super.key,
    this.size = 48,
    this.useAccentColor = false,
    this.color,
  });

  static String _hex(Color c) {
    final a = c.toARGB32();
    return '#${(a & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final String startColor;
    final String endColor;

    if (color != null) {
      startColor = _hex(color!);
      endColor = _hex(color!);
    } else if (useAccentColor) {
      final accent = context.accent;
      startColor = _hex(accent.light);
      endColor = _hex(accent.base);
    } else {
      startColor = '#E2FF4A';
      endColor = '#AEE800';
    }

    final svgString = '''<svg viewBox="0 0 100 100" fill="none" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="vGradB" x1="50" y1="18" x2="50" y2="82" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="$startColor"/>
      <stop offset="100%" stop-color="$endColor"/>
    </linearGradient>
  </defs>
  <!-- Top Apex -->
  <path d="M50 16L68 44H32L50 16Z" fill="url(#vGradB)"/>
  <!-- Heavy Left Wing -->
  <path d="M29 48L13 78C12 80 13.5 82 15.8 82H37C38.5 82 39.8 81 40.5 79.5L50 56.5L34 49C32.5 48.2 30.5 48.2 29 48Z" fill="url(#vGradB)"/>
  <!-- Heavy Right Wing -->
  <path d="M71 48L87 78C88 80 86.5 82 84.2 82H63C61.5 82 60.2 81 59.5 79.5L50 56.5L66 49C67.5 48.2 69.5 48.2 71 48Z" fill="url(#vGradB)"/>
</svg>''';

    return SvgPicture.string(
      svgString,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
