import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';

Future<T?> showActionBottomSheet<T>({
  required BuildContext context,
  String? title,
  required List<ActionSheetItem> items,
}) {
  HapticFeedback.lightImpact();
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _ActionBottomSheetContent(
      title: title,
      items: items,
    ),
  );
}

class ActionSheetItem {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final Color? titleColor;
  final String? subtitle;
  final Color? subtitleColor;
  final void Function(BuildContext context) onTap;

  const ActionSheetItem({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    this.titleColor,
    this.subtitle,
    this.subtitleColor,
    required this.onTap,
  });
}

class _ActionBottomSheetContent extends StatelessWidget {
  final String? title;
  final List<ActionSheetItem> items;

  const _ActionBottomSheetContent({
    this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // surface2 + AppRadius.sheetTop — same chrome as the branded confirm/
      // input sheets (app_dialog), so every sheet in the app matches.
      decoration: const BoxDecoration(
        color: AppColors.surface2,
        borderRadius: AppRadius.sheetTop,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: const BoxDecoration(
                color: AppColors.borderDefault,
                borderRadius: AppRadius.badgeAll,
              ),
            ),
            const SizedBox(height: 20),
            if (title != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  title!,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(color: AppColors.textSecondary)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(
                color: AppColors.borderSubtle,
                height: 0.5,
                thickness: 0.5,
              ),
              const SizedBox(height: 16),
            ],
            ...items.map((item) => _ActionSheetItemWidget(item: item)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _ActionSheetItemWidget extends StatelessWidget {
  final ActionSheetItem item;

  const _ActionSheetItemWidget({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => item.onTap(context),
          borderRadius: AppRadius.buttonPrimaryAll,
          splashColor: AppColors.accentPrimary.withValues(alpha: 0.1),
          highlightColor: AppColors.accentPrimary.withValues(alpha: 0.04),
          child: SizedBox(
            height: 56,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: item.iconBackground,
                      borderRadius: AppRadius.buttonPrimaryAll,
                    ),
                    child: Icon(item.icon, color: item.iconColor, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          // 16/500 — off the standard scale, so derive the family
                          // from AppText.button and pin the medium weight here.
                          style: AppText.button(
                                  color: item.titleColor ?? AppColors.textPrimary)
                              .copyWith(fontWeight: FontWeight.w500),
                        ),
                        if (item.subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.meta(
                                color: item.subtitleColor ??
                                    AppColors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
