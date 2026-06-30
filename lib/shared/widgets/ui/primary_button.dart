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
    final button = PressableScale(
      child: SizedBox(
        height: 52,
        width: isFullWidth ? double.infinity : null,
        child: ElevatedButton(
          onPressed: disabled
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  onPressed!();
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: accent.base,
            foregroundColor: accent.onAccent,
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

    return button;
  }
}
