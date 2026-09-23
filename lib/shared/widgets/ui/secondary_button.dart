import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/dynamic_accent_theme.dart';
import '../motion/pressable_scale.dart';
import 'app_button_shell.dart';

/// [secondary_button.dart]
/// Shared secondary button. Neutral by default (dark surface, white label —
/// used for "Add Exercise"); pass [accent] for the accent-outline variant
/// (palette muted fill + palette hairline + palette-light label), used for
/// "Add Set". Pass [solid] for a single solid accent CTA (palette base fill +
/// palette onAccent label — used for "New Routine"). The accent variants track
/// the active palette (purple/copper/teal/red) via [BuildContext.accent] —
/// never a hardcoded hue. 48dp tall floor, [AppRadius.buttonSecondary] corners.
///
/// GEOMETRY — why this widget does not build its own content row:
/// It used to. The icon variant was a `Row(mainAxisSize: min)` of [Icon] + gap
/// + [Text] with no [Flexible] around the label, inside 20dp of horizontal
/// padding each side. Safe at full width, broken at half width: two of these
/// in `Row[Expanded, gap, Expanded]` on a 360dp screen get 158dp each, 40dp of
/// which went to padding, leaving 118dp for content needing ~124dp — "A
/// RenderFlex overflowed by 6.7 pixels on the right".
///
/// [AppButtonShell] owns the row now. The label lives in Flexible + ellipsis
/// so horizontal pressure truncates instead of overflowing, and its minHeight
/// is a floor that can GROW rather than a fixed height that clips the label at
/// large OS text scale. Layout invariant for this file: a button may declare a
/// minimum height, never an exact one.
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

    return PressableScale(
      child: ConstrainedBox(
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
            // Horizontal inset only, and 14 rather than 20 — the label needs
            // those 12dp back when this button is one of two Expanded
            // siblings. Vertical padding is deliberately absent: the shell's
            // minHeight below IS the height floor, and stacking 12dp of
            // vertical padding on top of it would make every SecondaryButton
            // in the app 72dp tall.
            padding: const EdgeInsets.symmetric(horizontal: 14),
          ),
          child: AppButtonShell(
            label: label,
            style: AppText.button(color: fg),
            icon: icon,
            // AppButtonShell defaults to 20; the row this replaces drew 18.
            // Explicit so a no-visual-change refactor stays one.
            iconSize: 18,
            iconColor: fg,
            minHeight: 48,
            expand: isFullWidth,
          ),
        ),
      ),
    );
  }
}
