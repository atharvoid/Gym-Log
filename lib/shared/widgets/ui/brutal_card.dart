import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// [brutal_card.dart]
/// Purpose: Standard card container with neo brutalism styling
/// Dependencies: flutter/material.dart, app_colors.dart
/// Last modified: Track 0, Step 0.4

class BrutalCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final Color? shadowColor;
  final double borderWidth;
  final VoidCallback? onTap;

  const BrutalCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderColor,
    this.shadowColor,
    this.borderWidth = 2,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        border: Border.all(
          color: borderColor ?? AppColors.border,
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            offset: const Offset(3, 3),
            color: shadowColor ?? AppColors.accent,
            blurRadius: 0,
          ),
        ],
      ),
      padding: padding,
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: card,
      );
    }
    return card;
  }
}
