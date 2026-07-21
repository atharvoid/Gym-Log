import 'package:flutter/material.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';

/// Global snackbar helper providing standardized floating snackbar alerts.
///
/// Features:
/// - Floating behavior with 16dp horizontal margins and 14dp radius
/// - Maximum two lines of text with ellipsis
/// - Auto-adjusting bottom offset so it clears the active rest timer bar
/// - Accent-tinted action button
void showAppSnackBar(
  BuildContext context, {
  required String message,
  String? actionLabel,
  VoidCallback? onAction,
  double additionalBottomOffset = 0,
  Duration duration = const Duration(seconds: 4),
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();

  final accent = context.accent;
  final bottomPadding =
      MediaQuery.viewPaddingOf(context).bottom + additionalBottomOffset + 12;

  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: duration,
      elevation: 4,
      backgroundColor: AppColors.surface3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.borderSubtle, width: 1.0),
      ),
      margin: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding),
      content: Text(
        message,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      action: actionLabel != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: accent.light,
              onPressed: onAction ?? () {},
            )
          : null,
    ),
  );
}
