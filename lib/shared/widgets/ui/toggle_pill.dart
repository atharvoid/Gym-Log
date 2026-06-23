import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

/// [toggle_pill.dart]
/// Purpose: TogglePill - Pill-shaped toggle, active=purple bg, inactive=dark grey
/// Selection fires a light impact, per the app-wide haptic map.

class TogglePill extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const TogglePill({
    super.key,
    required this.label,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Honor the OS "reduce motion" setting — collapse the pill/text transitions.
    final motion = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 200);
    return GestureDetector(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.lightImpact();
              onTap!();
            },
      child: AnimatedContainer(
        duration: motion,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accentPrimary : AppColors.borderSubtle,
          borderRadius: BorderRadius.circular(999),
        ),
        child: AnimatedDefaultTextStyle(
          duration: motion,
          style: AppText.rowLabel(
            color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
          ).copyWith(
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
