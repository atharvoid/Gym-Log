import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/features/auth/presentation/providers/onboarding_draft_provider.dart';
import 'package:gymlog/shared/widgets/ui/primary_button.dart';

class StepAge extends ConsumerWidget {
  final VoidCallback onNext;

  const StepAge({super.key, required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingDraftProvider);
    final accent = context.accent;
    final surface = context.surface;

    // Use a default age of 25 if not set yet, or if it was cleared
    final currentAge = draft.age ?? 25;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Personalise',
                style: AppText.caption(color: surface.textSecondary).copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ref.read(onboardingDraftProvider.notifier).updateAge(null);
                  onNext();
                },
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: const Size(48, 48),
                ),
                child: Text(
                  'Skip',
                  style: AppText.body(color: accent.light).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'How old are you?',
            style: AppText.screenTitle(color: surface.textPrimary).copyWith(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Helps tailor volume & recovery suggestions.',
            style: AppText.body(color: surface.textSecondary).copyWith(
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const Spacer(),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Semantics(
                  button: true,
                  label: 'Decrease age',
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: surface.surface2,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: currentAge > 14
                          ? () {
                              HapticFeedback.lightImpact();
                              ref
                                  .read(onboardingDraftProvider.notifier)
                                  .updateAge(currentAge - 1);
                            }
                          : null,
                      icon: Icon(
                        Icons.remove_rounded,
                        color: currentAge > 14
                            ? surface.textPrimary
                            : surface.textSecondary.withValues(alpha: 0.3),
                        size: 32,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 40),
                SizedBox(
                  width: 100,
                  child: Center(
                    child: Text(
                      '$currentAge',
                      style:
                          AppText.heroStat(color: surface.textPrimary).copyWith(
                        fontSize: 72,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 40),
                Semantics(
                  button: true,
                  label: 'Increase age',
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: surface.surface2,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: currentAge < 100
                          ? () {
                              HapticFeedback.lightImpact();
                              ref
                                  .read(onboardingDraftProvider.notifier)
                                  .updateAge(currentAge + 1);
                            }
                          : null,
                      icon: Icon(
                        Icons.add_rounded,
                        color: currentAge < 100
                            ? surface.textPrimary
                            : surface.textSecondary.withValues(alpha: 0.3),
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          PrimaryButton(
            label: 'Continue',
            onPressed: () {
              // Ensure we write the age explicitly if they tap Continue
              ref.read(onboardingDraftProvider.notifier).updateAge(currentAge);
              onNext();
            },
            icon: Icons.arrow_forward_rounded,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
