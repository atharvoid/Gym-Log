import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

/// [secondary_button.dart]
/// Shared secondary button. Neutral by default (dark surface, white label —
/// used for "+ Add Set" / "+ Add Exercise"); pass [accent] for the
/// accent-outline variant (indigo tint + violet hairline + violet label),
/// used for "New Routine". 48dp tall, [AppRadius.buttonSecondary] corners.
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isFullWidth;
  final IconData? icon;
  final bool accent;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isFullWidth = true,
    this.icon,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = accent ? AppColors.accentText : AppColors.textPrimary;

    return SizedBox(
      height: 48,
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: accent ? AppColors.indigoTint : AppColors.bgSurface,
          foregroundColor: fg,
          disabledBackgroundColor: AppColors.bgSurface,
          disabledForegroundColor: AppColors.textDisabled,
          elevation: 0,
          shadowColor: Colors.transparent,
          side: accent
              ? BorderSide(
                  color: AppColors.accentPrimary.withValues(alpha: 0.45))
              : BorderSide.none,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.buttonSecondaryAll,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        child: icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18, color: fg),
                  const SizedBox(width: 8),
                  Text(label, style: AppText.button(color: fg)),
                ],
              )
            : Text(label, style: AppText.button(color: fg)),
      ),
    );
  }
}
