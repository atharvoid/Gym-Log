import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/shared/widgets/feedback/undoable_delete.dart';

/// Semantic meaning of a snackbar. Feedback color is information, not
/// decoration: success and failure must never render in the same neutral
/// grey as a purely informational note.
enum AppSnackBarVariant { neutral, success, error }

/// Resolved visuals for an [AppSnackBarVariant]. Shape-first: the icon
/// carries the meaning so the signal survives colour-blindness and the
/// light theme; the tint and hairline are reinforcement, not the message.
class _SnackBarStyle {
  final Color background;
  final Color border;
  final IconData? icon;
  final Color? iconColor;

  const _SnackBarStyle({
    required this.background,
    required this.border,
    this.icon,
    this.iconColor,
  });
}

/// Global snackbar helper providing standardized floating snackbar alerts.
///
/// Features:
/// - Floating behavior with 16dp horizontal margins and 14dp radius
/// - Semantic variants: success (accent tint + check glyph) and error
///   (error tint + error glyph) layered on the neutral default
/// - Maximum two lines of text with ellipsis
/// - Accent-tinted action button
/// - Does not dismiss a showing undoable-delete snackbar, so a rapid
///   double-action can never silently finalize a pending deletion
///
/// BOTTOM OFFSET IS THE FRAMEWORK'S JOB. A floating SnackBar is laid out by
/// Scaffold, which already lifts it above the bottomNavigationBar, above a
/// FAB and above the keyboard. On the active workout screen the rest timer
/// bar IS the bottomNavigationBar, so the hand-rolled `kRestTileHeight + 18`
/// this helper used to add was a second lift of the same bar — that is how
/// "Set removed" ended up floating mid-screen when a set was deleted with the
/// rest timer running. Only the system inset and a 12dp gap are ours to add.
///
/// [ref] is retained because ~30 call sites pass it and a future variant may
/// need workout state; it deliberately no longer influences placement.
void showAppSnackBar(
  BuildContext context, {
  required String message,
  String? actionLabel,
  VoidCallback? onAction,
  WidgetRef? ref,
  Color? backgroundColor,
  AppSnackBarVariant variant = AppSnackBarVariant.neutral,
  Duration duration = const Duration(seconds: 4),
}) {
  final messenger = ScaffoldMessenger.of(context);
  // An active undo snackbar must survive until its window elapses or the
  // user presses Undo — clearing it would finalize the pending deletion.
  if (!hasActiveUndoSnackBar) {
    messenger.clearSnackBars();
  }

  final accent = context.accent;
  final surface = context.surface;
  final bottomPadding = MediaQuery.viewPaddingOf(context).bottom + 12;

  final style = switch (variant) {
    // Saturation ladder: large tinted fills at 14%/12%, borders at 35%/45%,
    // small marks at 100% — mirrors the opacity policy in app_colors.dart.
    AppSnackBarVariant.success => _SnackBarStyle(
        background: Color.alphaBlend(
          accent.base.withValues(alpha: 0.14),
          surface.surface3,
        ),
        border: accent.base.withValues(alpha: 0.35),
        icon: Icons.check_circle_rounded,
        iconColor: accent.base,
      ),
    AppSnackBarVariant.error => _SnackBarStyle(
        background: Color.alphaBlend(
          AppColors.error.withValues(alpha: 0.12),
          surface.surface3,
        ),
        border: AppColors.error.withValues(alpha: 0.45),
        icon: Icons.error_rounded,
        iconColor: AppColors.error,
      ),
    AppSnackBarVariant.neutral => _SnackBarStyle(
        background: surface.surface3,
        border: surface.borderSubtle,
      ),
  };
  final icon = style.icon;

  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: duration,
      elevation: 4,
      backgroundColor: backgroundColor ?? style.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.snackbar),
        side: BorderSide(color: style.border, width: 1.0),
      ),
      margin: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding),
      content: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: style.iconColor),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.body(color: surface.textPrimary),
            ),
          ),
        ],
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
