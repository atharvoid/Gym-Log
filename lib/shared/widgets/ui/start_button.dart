import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/dynamic_accent_theme.dart';
import '../motion/pressable_scale.dart';

/// [start_button.dart]
/// Calm "Start" control (Option A — neutral-raised). Emphasis comes from
/// SURFACE ELEVATION + a bold neutral label, NOT a saturated fill. The accent
/// appears only on the leading glyph, so the control reads identically calm on
/// every palette (incl. neon Cyan/Higgsfield) and is immune to the White
/// on-accent contrast problem. Reserve full `accent.base` fills for LIVE states
/// (active-workout bar, rest timer), never for entry buttons.
class StartButton extends StatelessWidget {
  final String label;
  final IconData icon;

  /// Tap handler. When [enabled] is false the button still calls this (so a
  /// 0-exercise routine can explain why nothing happened) but renders muted.
  final VoidCallback? onPressed;

  /// true  → full-width (Home screen Quick Start)
  /// false → compact inline (routine card footer)
  final bool expand;

  final bool enabled;

  const StartButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.play_arrow_rounded,
    this.expand = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final accent = context.accent;
    final on = enabled && onPressed != null;

    // Neutral-raised surface — one elevation step above the card background.
    // Full-saturation accent.base is reserved for LIVE states (active workout
    // bar, rest timer), NOT entry buttons.
    final bg = on ? AppColors.surface3 : AppColors.surface2;
    final labelColor = on ? AppColors.textPrimary : AppColors.textTertiary;
    final glyphColor = on ? accent.base : AppColors.textTertiary;

    final button = SizedBox(
      height: expand ? 52 : 48,
      width: expand ? double.infinity : null,
      child: Material(
        color: bg,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: AppColors.borderDefault),
          borderRadius: AppRadius.buttonPrimaryAll,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: on
              ? () {
                  HapticFeedback.mediumImpact();
                  onPressed!();
                }
              : onPressed, // disabled-but-tappable path: let caller show explainer
          // Branded press feedback as a faint wash — never a flood.
          overlayColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.pressed)
                ? accent.base.withValues(alpha: 0.10)
                : null,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: expand ? 0 : 68),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: expand ? 24 : 16),
              child: Row(
                mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20, color: glyphColor),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: AppText.button(color: labelColor)
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return PressableScale(
      enabled: on,
      child: button,
    );
  }
}
