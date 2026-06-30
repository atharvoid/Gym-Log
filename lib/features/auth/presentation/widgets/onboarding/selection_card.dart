import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/shared/widgets/motion/pressable_scale.dart';

class OnboardingSelectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const OnboardingSelectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final accent = context.accent;
    final surface = context.surface;

    return Semantics(
      button: true,
      selected: selected,
      child: PressableScale(
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: AppColors.cardGradient,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: selected ? accent.base : surface.borderSubtle,
              width: selected ? 2.0 : 1.0,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accent.base.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                onTap();
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Row(
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        color: selected ? accent.light : surface.textSecondary,
                        size: 24,
                      ),
                      const SizedBox(width: 16),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppText.body(color: surface.textPrimary)
                                .copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: AppText.caption(color: surface.textSecondary)
                                .copyWith(
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (selected)
                      Icon(
                        Icons.check_circle_rounded,
                        color: accent.base,
                        size: 24,
                      )
                    else
                      Icon(
                        Icons.circle_outlined,
                        color: surface.textSecondary.withValues(alpha: 0.4),
                        size: 24,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
