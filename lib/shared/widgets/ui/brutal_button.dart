import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// [brutal_button.dart]
/// Purpose: Primary action button with neo brutalism press effect
/// Dependencies: flutter/material.dart, app_colors.dart, app_typography.dart
/// Last modified: Track 0, Step 0.4

class BrutalButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final IconData? icon;
  final double height;

  const BrutalButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isPrimary = true,
    this.icon,
    this.height = 52,
  });

  @override
  State<BrutalButton> createState() => _BrutalButtonState();
}

class _BrutalButtonState extends State<BrutalButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final fgColor = widget.isPrimary ? AppColors.accentFg : AppColors.textPrimary;
    final bgColor = widget.isPrimary ? AppColors.accent : Colors.transparent;
    final borderColor = widget.isPrimary ? AppColors.border : AppColors.border;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        height: widget.height,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: 2),
          boxShadow: _pressed
              ? []
              : [
                  BoxShadow(
                    offset: const Offset(3, 3),
                    color: widget.isPrimary ? AppColors.accent.withOpacity(0.6) : AppColors.borderMuted,
                    blurRadius: 0,
                  ),
                ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, color: fgColor, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              widget.label,
              style: AppTypography.body(context).copyWith(
                color: fgColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
