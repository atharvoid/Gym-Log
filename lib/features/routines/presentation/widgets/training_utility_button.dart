import 'package:flutter/material.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/shared/widgets/motion/pressable_scale.dart';

/// Raised utility action. Labels wrap rather than shrinking at large text.
class TrainingUtilityButton extends StatelessWidget {
  const TrainingUtilityButton(
      {super.key, required this.label, required this.onPressed, this.icon});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => PressableScale(
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: context.surface.surface3,
            foregroundColor: context.surface.textPrimary,
            minimumSize: const Size(double.infinity, 52),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            side: BorderSide(color: context.surface.borderDefault),
            shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.buttonPrimaryAll),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (icon != null) ...[
              Icon(icon,
                  color: onPressed == null
                      ? context.surface.textDisabled
                      : context.accent.base,
                  size: 20),
              const SizedBox(width: 8),
            ],
            Flexible(
                child: Text(label,
                    textAlign: TextAlign.center,
                    style: AppText.button(
                        color: onPressed == null
                            ? context.surface.textDisabled
                            : context.surface.textPrimary))),
          ]),
        ),
      );
}
