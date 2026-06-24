import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/dynamic_accent_theme.dart';

/// [secondary_button.dart]
/// Shared secondary button. Neutral by default (dark surface, white label —
/// used for "+ Add Exercise"); pass [accent] for the accent-outline variant
/// (palette muted fill + palette hairline + palette-light label), used for
/// "+ Add Set" / "New Routine". The accent variant tracks the active palette
/// (purple/copper/teal/red) via [BuildContext.accent] — never a hardcoded hue.
/// 48dp tall, [AppRadius.buttonSecondary] corners.
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
    final accentColors = context.accent;
    final fg = accent ? accentColors.light : AppColors.textPrimary;

    return SizedBox(
      height: 48,
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: accent ? accentColors.muted : AppColors.bgSurface,
          foregroundColor: fg,
          disabledBackgroundColor: AppColors.bgSurface,
          disabledForegroundColor: AppColors.textDisabled,
          elevation: 0,
          shadowColor: Colors.transparent,
          side: accent
              ? BorderSide(
                  color: accentColors.base.withValues(alpha: 0.45))
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
