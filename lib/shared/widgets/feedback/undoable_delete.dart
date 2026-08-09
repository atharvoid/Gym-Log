import 'package:flutter/material.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';

/// Number of undoable-delete snackbars currently queued/visible.
///
/// [showAppSnackBar] consults this before calling `clearSnackBars`, so a
/// generic toast can never dismiss an in-flight undo window (which would
/// silently finalize the pending deletion via [onCommitDelete]).
int _activeUndoSnackbars = 0;

/// Whether an undoable-delete snackbar is on-screen or queued.
bool get hasActiveUndoSnackBar => _activeUndoSnackbars > 0;

/// Shared helper to show a SnackBar with an "Undo" action for reversible deletes.
///
/// It must be called with a captured [ScaffoldMessengerState] before any async/pop.
///
/// DOCKING: this is a floating snackbar, so Scaffold already lifts it above
/// the bottomNavigationBar (which is where the rest timer bar lives) and
/// above the keyboard. The only margin we add is the system inset plus 12dp —
/// identical to showAppSnackBar — so an undo toast and any other toast sit at
/// the same height. Never add a hand-rolled rest-bar offset here; that double
/// count is what threw deletion toasts toward mid-screen.
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
    // Dock like every other toast: inset + 12dp, nothing hand-rolled on top.
    margin: EdgeInsets.fromLTRB(
      16,
      0,
      16,
      MediaQuery.viewPaddingOf(context).bottom + 12,
    ),
    duration: duration ?? const Duration(seconds: 4),
    action: SnackBarAction(
      label: 'Undo',
      textColor: accent.base,
      onPressed: onUndo,
    ),
    persist: false,
  );

  // Only evict a *non-undo* snackbar. A rapid second delete must queue behind
  // the first so its undo window stays open instead of being force-finalized.
  if (!hasActiveUndoSnackBar) {
    messenger.hideCurrentSnackBar();
  }
  _activeUndoSnackbars++;
  final controller = messenger.showSnackBar(snackBar);

  controller.closed.then((reason) {
    if (_activeUndoSnackbars > 0) _activeUndoSnackbars--;
    if (reason != SnackBarClosedReason.action) {
      onCommitDelete?.call();
    }
  });

  return controller;
}
