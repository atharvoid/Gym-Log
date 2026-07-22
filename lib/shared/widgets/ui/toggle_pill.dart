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
    return Semantics(
      container: true,
      button: true,
      selected: isActive,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
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
