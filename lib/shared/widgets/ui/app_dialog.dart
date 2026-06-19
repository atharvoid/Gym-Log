import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

/// Branded confirmation dialog — the single replacement for every stock
/// `AlertDialog` confirm in the app, so destructive flows look and feel
/// identical everywhere. Destructive confirms fire a warning haptic BEFORE
/// the dialog appears. Returns true when the user confirms.
Future<bool> showAppConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  bool isDestructive = false,
}) async {
  if (isDestructive) {
    HapticFeedback.heavyImpact();
  } else {
    HapticFeedback.lightImpact();
  }

  final result = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (dialogCtx) => Dialog(
      backgroundColor: AppColors.surface2,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppText.sectionHeading()),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(message, style: AppText.body()),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(false),
                  child: Text(cancelLabel,
                      style: AppText.button(color: AppColors.textSecondary)),
                ),
                const SizedBox(width: 4),
                TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(dialogCtx).pop(true);
                  },
                  child: Text(
                    confirmLabel,
                    style: AppText.button(
                      // On-dark accent text uses the lighter tone (AA);
                      // destructive stays red.
                      color:
                          isDestructive ? AppColors.error : AppColors.accentText,
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

/// Branded single-field text input dialog (rename routine, etc.).
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

  // Dispose the controller once the dialog closes (confirm OR dismiss) —
  // otherwise every invocation leaks a TextEditingController + focus node.
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
        backgroundColor: AppColors.surface2,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.sectionHeading()),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  maxLength: maxLength,
                  textCapitalization: TextCapitalization.words,
                  cursorColor: AppColors.accentPrimary,
                  style: AppText.value(),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: AppText.body(color: AppColors.textTertiary),
                    counterStyle:
                        AppText.caption(color: AppColors.textTertiary),
                    filled: true,
                    fillColor: AppColors.surface3,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    enabledBorder: const OutlineInputBorder(
                      borderRadius: AppRadius.inputAll,
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: AppRadius.inputAll,
                      borderSide:
                          BorderSide(color: AppColors.borderActive, width: 1.5),
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
                    child: Text('Cancel',
                        style: AppText.button(color: AppColors.textSecondary)),
                  ),
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: submit,
                    child: Text(confirmLabel,
                        style: AppText.button(color: AppColors.accentText)),
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
