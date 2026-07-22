import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymlog/core/providers/premium_provider.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/features/routines/presentation/widgets/routine_detail_styles.dart';
import 'package:gymlog/shared/widgets/premium_paywall.dart';
import 'package:gymlog/shared/widgets/ui/branded_bottom_sheet.dart';

const kTimeRangeOptions = ['1M', '3M', '6M', '1Y', 'All Time'];

/// Ranges deeper than 6 months are a Pro feature, identically everywhere.
const kProTimeRanges = {'1Y', 'All Time'};

/// THE time-range filter — one chip, one sheet, one lock behavior, shared
/// by Routine Detail, Exercise Detail, and any future chart screen.
class TimeRangeFilter extends ConsumerWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const TimeRangeFilter({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      label: 'Time range filter, currently $value',
      button: true,
      child: GestureDetector(
        onTap: () => _showSheet(context, ref),
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.surface.surface2,
            borderRadius: BorderRadius.circular(AppRadius.buttonSecondary),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: RDStyles.rangePill),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: context.surface.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSheet(BuildContext context, WidgetRef ref) {
    HapticFeedback.lightImpact();
    final isPremium = ref.read(isPremiumProvider);
    // Resolve the live accent once from the calling context — the modal
    // builder runs under a different (root navigator) context, so capture it
    // here rather than reading it inside the sheet.
    final accent = context.accent;

    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        final surface = sheetCtx.surface;
        return Container(
          decoration: BoxDecoration(
            color: surface.bgSurface,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.sheet)),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.sheet)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: surface.borderDefault,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Time Range',
                      style: AppText.sheetTitle(),
                    ),
                    const SizedBox(height: 16),
                    ...kTimeRangeOptions.map((range) {
                      final isSelected = range == value;
                      final isLocked =
                          !isPremium && kProTimeRanges.contains(range);
                      return Semantics(
                        button: true,
                        selected: isSelected && !isLocked,
                        label: isLocked
                            ? '$range, premium, locked'
                            : isSelected
                                ? '$range, selected'
                                : range,
                        child: InkWell(
                          onTap: () {
                            Navigator.of(sheetCtx).pop();
                            if (isLocked) {
                              showPremiumPaywall(context);
                              return;
                            }
                            HapticFeedback.lightImpact();
                            onChanged(range);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: surface.borderSubtle,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    range,
                                    style: AppText.rowLabel(
                                      color: isLocked
                                          ? surface.textSecondary
                                          : isSelected
                                              ? accent.base
                                              : surface.textPrimary,
                                    ),
                                  ),
                                ),
                                if (isLocked)
                                  Icon(
                                    Icons.lock_rounded,
                                    size: 14,
                                    color: accent.light,
                                  )
                                else if (isSelected)
                                  Icon(
                                    Icons.check_rounded,
                                    size: 18,
                                    color: accent.base,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Branded picker sheet for simple option lists (set type, units, filters).
/// Same surface, handle, and row language as every other sheet in the app.
Future<T?> showBrandedPickerSheet<T>({
  required BuildContext context,
  required String title,
  required List<PickerOption<T>> options,
  T? selected,
}) {
  HapticFeedback.lightImpact();
  final accent = context.accent;

  Widget optionRow(PickerOption<T> opt) {
    final isSelected = selected != null && opt.value == selected;
    final iconColor = isSelected ? accent.base : opt.color;
    return Semantics(
      button: true,
      selected: isSelected,
      label: opt.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.buttonSecondary),
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.of(context, rootNavigator: true).pop(opt.value);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 13),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadius.badge),
                  ),
                  child: Icon(opt.icon, size: 18, color: iconColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(opt.label, style: AppText.rowLabel()),
                      if (opt.subtitle != null)
                        Text(opt.subtitle!, style: AppText.caption()),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_rounded, size: 18, color: accent.base),
              ],
            ),
          ),
        ),
      ),
    );
  }

  return showBrandedBottomSheet<T>(
    context: context,
    title: title,
    scrollable: true,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: options.map(optionRow).toList(),
    ),
  );
}

class PickerOption<T> {
  final T value;
  final String label;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const PickerOption({
    required this.value,
    required this.label,
    this.subtitle,
    required this.icon,
    this.color = AppColors.textSecondary,
  });
}
