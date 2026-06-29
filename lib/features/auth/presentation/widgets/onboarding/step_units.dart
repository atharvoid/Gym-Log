import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/features/auth/presentation/providers/onboarding_draft_provider.dart';
import 'package:gymlog/features/auth/presentation/widgets/onboarding/selection_card.dart';
import 'package:gymlog/shared/widgets/ui/primary_button.dart';

class StepUnits extends ConsumerWidget {
  final VoidCallback onNext;

  const StepUnits({super.key, required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingDraftProvider);
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
            'Preferred unit?',
            style: AppText.screenTitle(color: surface.textPrimary).copyWith(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You can change this anytime in Settings.',
            style: AppText.body(color: surface.textSecondary).copyWith(
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 40),
          OnboardingSelectionCard(
            title: 'Kilograms (kg)',
            subtitle: 'Used worldwide',
            selected: draft.unit == 'kg',
            onTap: () {
              ref.read(onboardingDraftProvider.notifier).updateUnit('kg');
            },
            icon: Icons.fitness_center_rounded,
          ),
          OnboardingSelectionCard(
            title: 'Pounds (lbs)',
            subtitle: 'Used in the US, UK',
            selected: draft.unit == 'lbs',
            onTap: () {
              ref.read(onboardingDraftProvider.notifier).updateUnit('lbs');
            },
            icon: Icons.fitness_center_rounded,
          ),
          const Spacer(),
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
