import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// [brutal_bottom_sheet.dart]
/// Purpose: Brutalist-styled bottom sheet helper
/// Dependencies: flutter/material.dart, app_colors.dart, app_typography.dart
/// Last modified: Track 0, Step 0.4

class BrutalBottomSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    double? height,
    String? title,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.bgBase,
              border: Border(
                top: BorderSide(color: AppColors.border, width: 2),
                left: BorderSide(color: AppColors.border, width: 2),
                right: BorderSide(color: AppColors.border, width: 2),
              ),
              boxShadow: [
                BoxShadow(
                  offset: Offset(0, -4),
                  color: AppColors.accent,
                  blurRadius: 0,
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null) ...[
                    Text(
                      title,
                      style: AppTypography.heading(context),
                    ),
                    const SizedBox(height: 16),
                  ],
                  child,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
