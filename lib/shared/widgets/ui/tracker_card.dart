import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// [tracker_card.dart]
/// Purpose: TrackerCard - Solid dark grey card, 12px radius, zero shadow/border
/// Dependencies: flutter/material.dart, app_colors.dart
/// Last modified: High-Density Tracker Overhaul

class TrackerCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const TrackerCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: card,
        ),
      );
    }

    return card;
  }
}
