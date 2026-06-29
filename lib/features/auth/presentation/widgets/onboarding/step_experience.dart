import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/features/auth/presentation/providers/onboarding_draft_provider.dart';
import 'package:gymlog/features/auth/presentation/widgets/onboarding/selection_card.dart';
import 'package:gymlog/shared/widgets/ui/primary_button.dart';

class StepExperience extends ConsumerWidget {
  final VoidCallback onNext;

  const StepExperience({super.key, required this.onNext});

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
            'Personalise',
            style: AppText.caption(color: surface.textSecondary).copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Experience level?',
            style: AppText.screenTitle(color: surface.textPrimary).copyWith(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "We'll suggest programs that match your level.",
            style: AppText.body(color: surface.textSecondary).copyWith(
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          OnboardingSelectionCard(
            title: 'Beginner',
            subtitle: 'New to lifting or < 6 months',
            selected: draft.level == 'beginner',
            onTap: () {
              ref
                  .read(onboardingDraftProvider.notifier)
                  .updateLevel('beginner');
            },
            icon: Icons.directions_walk_rounded,
          ),
          OnboardingSelectionCard(
            title: 'Intermediate',
            subtitle: '6 months – 2 years, comfortable with form',
            selected: draft.level == 'intermediate',
            onTap: () {
              ref
                  .read(onboardingDraftProvider.notifier)
                  .updateLevel('intermediate');
            },
            icon: Icons.directions_run_rounded,
          ),
          OnboardingSelectionCard(
            title: 'Advanced',
            subtitle: '2+ years, programming your own splits',
            selected: draft.level == 'advanced',
            onTap: () {
              ref
                  .read(onboardingDraftProvider.notifier)
                  .updateLevel('advanced');
            },
            icon: Icons.bolt_rounded,
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
