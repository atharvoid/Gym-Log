import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// [brutal_badge.dart]
/// Purpose: Small type indicator (W, D, F for set types)
/// Dependencies: flutter/material.dart, app_colors.dart, app_typography.dart
/// Last modified: Track 0, Step 0.4

class BrutalBadge extends StatelessWidget {
  final String label;
  final Color? borderColor;
  final Color? textColor;
  final VoidCallback? onTap;

  const BrutalBadge({
    super.key,
    required this.label,
    this.borderColor,
    this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: AppColors.bgBase,
        border: Border.all(
          color: borderColor ?? AppColors.border,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: AppTypography.label(context).copyWith(
            color: textColor ?? AppColors.textPrimary,
            fontSize: 10,
            letterSpacing: 0,
          ),
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: badge,
      );
    }
    return badge;
  }
}
