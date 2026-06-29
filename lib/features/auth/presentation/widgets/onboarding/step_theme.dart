import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/core/theme/theme_palette.dart';
import 'package:gymlog/features/auth/presentation/providers/onboarding_draft_provider.dart';
import 'package:gymlog/shared/widgets/ui/primary_button.dart';

class StepTheme extends ConsumerWidget {
  final VoidCallback onNext;

  const StepTheme({super.key, required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPalette = ref.watch(dynamicAccentThemeProvider);
    final surface = context.surface;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 48),
          Text(
            'Preferences',
            style: AppText.caption(color: surface.textSecondary).copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Choose your theme?',
            style: AppText.screenTitle(color: surface.textPrimary).copyWith(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Make it yours. Change anytime in Settings → Appearance.',
            style: AppText.body(color: surface.textSecondary).copyWith(
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Center(
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 20,
                crossAxisSpacing: 12,
                childAspectRatio: 0.78,
                children: [
                  for (final palette in ThemePalette.values)
                    GestureDetector(
                      onTap: () {
                        if (palette == selectedPalette) return;
                        HapticFeedback.selectionClick();
                        ref
                            .read(dynamicAccentThemeProvider.notifier)
                            .setPalette(palette);
                        ref
                            .read(onboardingDraftProvider.notifier)
                            .updatePalette(palette);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Semantics(
                        button: true,
                        selected: palette == selectedPalette,
                        label: palette.a11yName,
                        excludeSemantics: true,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: MediaQuery.disableAnimationsOf(context)
                                  ? Duration.zero
                                  : const Duration(milliseconds: 180),
                              curve: Curves.easeOut,
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: palette.swatch,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: palette == selectedPalette
                                      ? surface.textPrimary
                                      : surface.borderSubtle,
                                  width: palette == selectedPalette ? 2.5 : 1,
                                ),
                                boxShadow: palette == selectedPalette
                                    ? [
                                        BoxShadow(
                                          color: palette.swatch
                                              .withValues(alpha: 0.45),
                                          blurRadius: 16,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: palette == selectedPalette
                                  ? Icon(
                                      Icons.check_rounded,
                                      size: 28,
                                      color: palette.tokens.onAccent,
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              palette.displayName,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.caption(
                                color: palette == selectedPalette
                                    ? surface.textPrimary
                                    : surface.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          PrimaryButton(
            label: 'Continue',
            onPressed: onNext,
            icon: Icons.arrow_forward_rounded,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
