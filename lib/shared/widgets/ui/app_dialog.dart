import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

/// Branded confirmation dialog — the single replacement for every stock
/// `AlertDialog` confirm in the app, so destructive flows look and feel
/// identical everywhere.
///
/// Destructive confirms fire a warning haptic BEFORE the dialog appears.
///
/// Returns true when the user confirms, false/null otherwise.
Future<bool> showAppConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  bool isDestructive = false,
}) async {
  if (isDestructive) {
    HapticFeedback.heavyImpact(); // warning haptic before the dialog
  } else {
    HapticFeedback.lightImpact();
  }

  final result = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (dialogCtx) => Dialog(
      backgroundColor: const Color(0xFF121212),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(false),
                  child: Text(
                    cancelLabel,
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(dialogCtx).pop(true);
                  },
                  child: Text(
                    confirmLabel,
                    style: GoogleFonts.inter(
                      color: isDestructive
                          ? AppColors.error
                          : AppColors.accentPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}

/// Branded single-field text input dialog (rename routine, name workout…).
/// Returns the trimmed non-empty value, or null when cancelled.
Future<String?> showAppTextInputDialog({
  required BuildContext context,
  required String title,
  required String hint,
  String? initialValue,
  String confirmLabel = 'Save',
  int maxLength = 50,
}) {
  HapticFeedback.selectionClick();
  final controller = TextEditingController(text: initialValue);

  // Dispose the controller once the dialog closes — otherwise every rename /
  // "save workout" invocation leaks a TextEditingController (and its focus
  // node + listeners). whenComplete fires on both confirm and dismiss.
  return showDialog<String>(
    context: context,
    useRootNavigator: true,
    builder: (dialogCtx) {
      void submit() {
        final value = controller.text.trim();
        if (value.isEmpty) return;
        Navigator.of(dialogCtx).pop(value);
      }

      return Dialog(
        backgroundColor: const Color(0xFF121212),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  maxLength: maxLength,
                  textCapitalization: TextCapitalization.words,
                  cursorColor: AppColors.accentPrimary,
                  style: GoogleFonts.inter(
                      color: AppColors.textPrimary, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle:
                        GoogleFonts.inter(color: AppColors.textSecondary),
                    counterStyle: GoogleFonts.inter(
                        color: AppColors.textSecondary, fontSize: 11),
                    filled: true,
                    fillColor: AppColors.surfaceRaised,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: const BorderSide(
                          color: AppColors.accentPrimary, width: 1.5),
                    ),
                  ),
                  onSubmitted: (_) => submit(),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogCtx).pop(null),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: submit,
                    child: Text(
                      confirmLabel,
                      style: GoogleFonts.inter(
                        color: AppColors.accentPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  ).whenComplete(controller.dispose);
}
