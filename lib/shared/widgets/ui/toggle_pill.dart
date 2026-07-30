import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/dynamic_accent_theme.dart';

/// [toggle_pill.dart]
/// Purpose: TogglePill - Pill-shaped toggle, active=accent bg, inactive=dark grey.
/// The active fill follows the user's chosen accent palette (purple/copper/
/// teal/red) via [BuildContext.accent] — never a hardcoded hue.
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
    // ONE handler, shared by the visual InkWell and the semantics action below.
    // They must not drift: if the semantics path skipped the haptic, activating
    // this pill with a screen reader would feel different from tapping it.
    final VoidCallback? handleTap = onTap == null
        ? null
        : () {
            HapticFeedback.lightImpact();
            onTap!();
          };
    return Semantics(
      container: true,
      button: true,
      selected: isActive,
      enabled: handleTap != null,
      label: label,
      // The wrapper owns the name, so the inner Text must not publish a second
      // node carrying the same string — that is two focus stops and a doubled
      // announcement. excludeSemantics drops the whole subtree, INCLUDING
      // InkWell's tap action, which is why onTap is re-declared here.
      excludeSemantics: true,
      onTap: handleTap,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: handleTap,
          child: AnimatedContainer(
            duration: motion,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color:
                  isActive ? context.accent.base : context.surface.borderSubtle,
              borderRadius: BorderRadius.circular(999),
            ),
            child: AnimatedDefaultTextStyle(
              duration: motion,
              style: AppText.rowLabel(
                color: isActive
                    ? context.accent.onAccent
                    : context.surface.textSecondary,
              ).copyWith(
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }
}
