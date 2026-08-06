import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/features/workout/presentation/providers/rest_timer_provider.dart';
import 'package:gymlog/features/workout/presentation/widgets/rest_timer_bar.dart';
import 'package:gymlog/shared/widgets/feedback/undoable_delete.dart';

/// Global snackbar helper providing standardized floating snackbar alerts.
///
/// Features:
/// - Floating behavior with 16dp horizontal margins and 14dp radius
/// - Maximum two lines of text with ellipsis
/// - Auto-adjusting bottom offset so it clears the active rest timer bar
///   (read from [restTimerProvider] via the optional [ref])
/// - Accent-tinted action button
/// - Does not dismiss a showing undoable-delete snackbar, so a rapid
///   double-action can never silently finalize a pending deletion
void showAppSnackBar(
  BuildContext context, {
  required String message,
  String? actionLabel,
  VoidCallback? onAction,
  WidgetRef? ref,
  Color? backgroundColor,
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
  final restBarVisible = ref?.read(restTimerProvider) != null;
  final restBarOffset = restBarVisible ? kRestTileHeight + 18 : 0;
  final bottomPadding =
      MediaQuery.viewPaddingOf(context).bottom + restBarOffset + 12;

  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: duration,
      elevation: 4,
      backgroundColor: backgroundColor ?? surface.surface3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.snackbar),
        side: BorderSide(color: surface.borderSubtle, width: 1.0),
      ),
      margin: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding),
      content: Text(
        message,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppText.body(color: surface.textPrimary),
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
