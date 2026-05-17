import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// [brutal_chip.dart]
/// Purpose: Filter chip with selected/unselected states
/// Dependencies: flutter/material.dart, app_colors.dart, app_typography.dart
/// Last modified: Track 0, Step 0.4

class BrutalChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const BrutalChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.transparent,
          border: Border.all(
            color: selected ? AppColors.border : AppColors.border,
            width: 2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    offset: const Offset(2, 2),
                    color: AppColors.accent.withOpacity(0.4),
                    blurRadius: 0,
                  ),
                ]
              : [],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          label,
          style: AppTypography.label(context).copyWith(
            color: selected ? AppColors.accentFg : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
