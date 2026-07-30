import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/dynamic_accent_theme.dart';
import '../motion/pressable_scale.dart';

/// [primary_button.dart]
/// Purpose: PrimaryButton — the app's primary CTA, on-spec with the design
/// system: 52px height, AppRadius.buttonPrimary (12px) radius, accent fill,
/// w600 label. Every primary action fires a medium impact — consistent
/// app-wide feel. The fill follows the active accent palette.

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isFullWidth;
  final IconData? icon;

  /// While true the button is disabled and shows a spinner — prevents the
  /// double-fire that triggers "Concurrent operations" on async actions
  /// (e.g. Google Sign-In, which only tolerates one pending call).
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isFullWidth = true,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = context.accent;
    final disabled = isLoading || onPressed == null;
    // ONE handler for the button and its semantics action, so a screen-reader
    // activation fires the same haptic and callback as a sighted tap.
    final VoidCallback? handlePress = disabled
        ? null
        : () {
            HapticFeedback.mediumImpact();
            onPressed!();
          };
    final button = PressableScale(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: 52,
          minWidth: isFullWidth ? double.infinity : 0.0,
        ),
        child: ElevatedButton(
          onPressed: handlePress,
          style: ElevatedButton.styleFrom(
            backgroundColor: accent.base,
            foregroundColor: accent.onAccent,
            minimumSize: Size(isFullWidth ? double.infinity : 88, 52),
            // Busy state stays on-brand (dimmed accent), not the default gray
            // "disabled" look — it reads as "working", not "unavailable".
            disabledBackgroundColor: accent.base.withValues(alpha: 0.6),
            disabledForegroundColor: accent.onAccent,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.buttonPrimaryAll,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(accent.onAccent),
                  ),
                )
              : icon != null
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, size: 20),
                        const SizedBox(width: 8),
                        Text(label,
                            style: AppText.button(color: accent.onAccent)),
                      ],
                    )
                  : Text(
                      label,
                      style: AppText.button(color: accent.onAccent)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
        ),
      ),
    );

    // ACCESSIBILITY: the accessible name normally comes from the child Text —
    // but that Text is REPLACED by a spinner while [isLoading]. So the app's
    // primary CTA lost its name at precisely the moment a screen-reader user
    // needs to know which action is running: "button, dimmed", nothing else.
    //
    // Naming it from the outside fixes that and also collapses the icon+label
    // Row into a single traversal stop. excludeSemantics discards the
    // ElevatedButton's own tap action, so onTap is re-declared here.
    return Semantics(
      container: true,
      button: true,
      enabled: !disabled,
      label: isLoading ? '$label, in progress' : label,
      excludeSemantics: true,
      onTap: handlePress,
      child: button,
    );
  }
}
