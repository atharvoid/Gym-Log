import 'package:flutter/material.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';

/// [branded_bottom_sheet.dart]
/// Canonical bottom-sheet shell: drag handle, sheet background, safe-area
/// padding, and optional title/subtitle header. Keeps every branded sheet
/// (weekly goal, picker, etc.) visually identical and token-correct.
class BrandedBottomSheet extends StatelessWidget {
  final Widget child;
  final String? title;
  final String? subtitle;
  final EdgeInsetsGeometry padding;
  final bool scrollable;

  const BrandedBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.padding = const EdgeInsets.fromLTRB(24, 12, 24, 18),
    this.scrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = SafeArea(
      top: false,
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderDefault,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            if (title != null) ...[
              const SizedBox(height: 20),
              Text(title!,
                  style: AppText.sheetTitle(), textAlign: TextAlign.start),
            ],
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!,
                  style: AppText.body(), textAlign: TextAlign.start),
            ],
            if (title != null || subtitle != null) const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );

    if (scrollable) {
      content = SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: content,
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgSheet,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      child: content,
    );
  }
}

/// Convenience helper to present a [BrandedBottomSheet].
Future<T?> showBrandedBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  String? title,
  String? subtitle,
  bool useRootNavigator = true,
  bool isScrollControlled = false,
  bool scrollable = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    useSafeArea: true,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    builder: (_) => BrandedBottomSheet(
      title: title,
      subtitle: subtitle,
      scrollable: scrollable,
      child: child,
    ),
  );
}
