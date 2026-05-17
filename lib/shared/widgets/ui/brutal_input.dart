import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// [brutal_input.dart]
/// Purpose: Text/number input with neo brutalism styling
/// Dependencies: flutter/material.dart, app_colors.dart, app_typography.dart
/// Last modified: Track 0, Step 0.4

class BrutalInput extends StatefulWidget {
  final String? hint;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool readOnly;
  final double width;

  const BrutalInput({
    super.key,
    this.hint,
    this.initialValue,
    this.onChanged,
    this.keyboardType,
    this.controller,
    this.focusNode,
    this.readOnly = false,
    this.width = double.infinity,
  });

  @override
  State<BrutalInput> createState() => _BrutalInputState();
}

class _BrutalInputState extends State<BrutalInput> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) => setState(() => _focused = hasFocus),
      child: Container(
        width: widget.width == double.infinity ? null : widget.width,
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          border: Border.all(
            color: _focused ? AppColors.accent : AppColors.border,
            width: 2,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          keyboardType: widget.keyboardType,
          onChanged: widget.onChanged,
          readOnly: widget.readOnly,
          style: AppTypography.mono(context),
          decoration: InputDecoration.collapsed(
            hintText: widget.hint,
            hintStyle: AppTypography.mono(context).copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
