import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

/// [primary_button.dart]
/// Purpose: PrimaryButton - Electric purple, 48px height, 12px radius, bold text
/// Every primary action fires a medium impact — consistent app-wide feel.

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isFullWidth;
  final IconData? icon;

  /// Optional leading widget rendered before the label. Takes precedence over
  /// [icon] when both are provided — useful for brand image assets such as the
  /// Google "G" mark that cannot be expressed as an [IconData].
  final Widget? leading;

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
    this.leading,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = isLoading || onPressed == null;
    final button = SizedBox(
      height: 48,
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: disabled
            ? null
            : () {
                HapticFeedback.mediumImpact();
                onPressed!();
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentPrimary,
          foregroundColor: AppColors.textPrimary,
          // Busy state stays on-brand (dimmed purple), not the default gray
          // "disabled" look — it reads as "working", not "unavailable".
          disabledBackgroundColor:
              AppColors.accentPrimary.withValues(alpha: 0.6),
          disabledForegroundColor: AppColors.textPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.textPrimary),
                ),
              )
            : (leading != null || icon != null)
            ? Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (leading != null)
                    leading!
                  else if (icon != null)
                    Icon(icon, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              )
            : Text(
                label,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
      ),
    );

    return button;
  }
}
