import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/dynamic_accent_theme.dart';

/// [secondary_button.dart]
/// Shared secondary button. Neutral by default (dark surface, white label —
/// used for "Add Exercise"); pass [accent] for the accent-outline variant
/// (palette muted fill + palette hairline + palette-light label), used for
/// "Add Set". Pass [solid] for a single solid accent CTA (palette base fill +
/// palette onAccent label — used for "New Routine"). The accent variants track
/// the active palette (purple/copper/teal/red) via [BuildContext.accent] —
/// never a hardcoded hue. 48dp tall, [AppRadius.buttonSecondary] corners.
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isFullWidth;
  final IconData? icon;
  final bool accent;

  /// Solid accent fill + onAccent label — a single focal CTA per view
  /// (e.g. "New Routine" beside a neutral "Explore"). Rule B: one solid-accent
  /// action per view; everything else is neutral-raised or tinted.
  final bool solid;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isFullWidth = true,
    this.icon,
    this.accent = false,
    this.solid = false,
  });

  @override
  Widget build(BuildContext context) {
    final accentColors = context.accent;

    final Color bg = solid
        ? accentColors.base
        : (accent ? accentColors.muted : context.surface.bgSurface);
    final Color fg = solid
        ? accentColors.onAccent
        : (accent ? accentColors.light : context.surface.textPrimary);
    final BorderSide side = (accent && !solid)
        ? BorderSide(color: accentColors.base.withValues(alpha: 0.45))
        : BorderSide.none;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: 48,
        minWidth: isFullWidth ? double.infinity : 0.0,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          minimumSize: Size(isFullWidth ? double.infinity : 88, 48),
          disabledBackgroundColor: solid
              ? accentColors.base.withValues(alpha: 0.6)
              : context.surface.bgSurface,
          disabledForegroundColor:
              solid ? accentColors.onAccent : context.surface.textDisabled,
          elevation: 0,
          shadowColor: Colors.transparent,
          side: side,
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
