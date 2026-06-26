import 'package:flutter/material.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';

/// Shared helper to show a SnackBar with an "Undo" action for reversible deletes.
///
/// It must be called with a captured [ScaffoldMessengerState] before any async/pop.
ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showUndoableDelete({
  required ScaffoldMessengerState messenger,
  required String label,
  required VoidCallback onUndo,
  VoidCallback? onCommitDelete,
  Duration? duration,
}) {
  final context = messenger.context;
  final surface = context.surface;
  final accent = context.accent;

  final snackBar = SnackBar(
    content: Text(
      label,
      style: AppText.meta(color: surface.textPrimary),
    ),
    backgroundColor: surface.surface3,
    behavior: SnackBarBehavior.floating,
    duration: duration ?? const Duration(seconds: 4),
    action: SnackBarAction(
      label: 'Undo',
      textColor: accent.base,
      onPressed: onUndo,
    ),
    persist: false,
  );

  messenger.hideCurrentSnackBar();
  final controller = messenger.showSnackBar(snackBar);

  controller.closed.then((reason) {
    if (reason != SnackBarClosedReason.action) {
      onCommitDelete?.call();
    }
  });

  return controller;
}
