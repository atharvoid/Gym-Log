import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/features/auth/presentation/providers/onboarding_draft_provider.dart';
import 'package:gymlog/shared/widgets/motion/pressable_scale.dart';
import 'package:gymlog/shared/widgets/ui/primary_button.dart';

class StepGender extends ConsumerWidget {
  final VoidCallback onNext;

  const StepGender({super.key, required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingDraftProvider);
    final surface = context.surface;

    // Default to 'prefer_not_to_say' if not chosen yet
    final selectedGender = draft.gender ?? 'prefer_not_to_say';

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
            'What is your gender?',
            style: AppText.screenTitle(color: surface.textPrimary).copyWith(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "This chooses the body figure style displayed across your workouts.",
            style: AppText.body(color: surface.textSecondary).copyWith(
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          _GenderCard(
            title: 'Female',
            genderKey: 'female',
            selected: selectedGender == 'female',
            assetPath: 'assets/icons/muscles/female/fullbody.svg',
            onTap: () {
              ref.read(onboardingDraftProvider.notifier).updateGender('female');
            },
          ),
          _GenderCard(
            title: 'Male',
            genderKey: 'male',
            selected: selectedGender == 'male',
            assetPath: 'assets/icons/muscles/male/fullbody.svg',
            onTap: () {
              ref.read(onboardingDraftProvider.notifier).updateGender('male');
            },
          ),
          _GenderCard(
            title: 'Prefer not to say',
            genderKey: 'prefer_not_to_say',
            selected: selectedGender == 'prefer_not_to_say',
            assetPath: 'assets/icons/muscles/neutral/fullbody.svg',
            onTap: () {
              ref
                  .read(onboardingDraftProvider.notifier)
                  .updateGender('prefer_not_to_say');
            },
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

class _GenderCard extends StatelessWidget {
  final String title;
  final String genderKey;
  final bool selected;
  final String assetPath;
  final VoidCallback onTap;

  const _GenderCard({
    required this.title,
    required this.genderKey,
    required this.selected,
    required this.assetPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = context.accent;
    final surface = context.surface;

    final tint = selected ? accent.light : surface.textSecondary;

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
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: tint.withValues(alpha: 0.12),
                        borderRadius: AppRadius.thumbnailAll,
                      ),
                      child: SvgPicture.asset(
                        assetPath,
                        width: 24,
                        height: 24,
                        colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
                        placeholderBuilder: (_) => Icon(
                          Icons.person_rounded,
                          size: 24,
                          color: tint,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style:
                            AppText.body(color: surface.textPrimary).copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
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
