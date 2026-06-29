import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/features/auth/presentation/providers/onboarding_draft_provider.dart';
import 'package:gymlog/shared/widgets/ui/goal_ring.dart';
import 'package:gymlog/shared/widgets/ui/primary_button.dart';

class StepWeeklyGoal extends ConsumerWidget {
  final VoidCallback onNext;

  const StepWeeklyGoal({super.key, required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingDraftProvider);
    final accent = context.accent;
    final surface = context.surface;

    final current = draft.weeklyGoal;
    // Show a realistic progress: e.g. 2 workouts completed.
    final double progress = (2 / current).clamp(0.0, 1.0);

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
            'Weekly goal?',
            style: AppText.screenTitle(color: surface.textPrimary).copyWith(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your weekly target powers the Home streak ring.',
            style: AppText.body(color: surface.textSecondary).copyWith(
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const Spacer(),
          // Mini preview of the Home ring
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GoalRing(
                  progress: progress,
                  size: 72,
                ),
                const SizedBox(height: 16),
                Text(
                  '2 of $current workouts completed',
                  style: AppText.body(color: surface.textPrimary).copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Weekly progress ring preview',
                  style: AppText.caption(color: surface.textSecondary),
                ),
              ],
            ),
          ),
          const Spacer(),
          // 7-segment horizontal picker
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var days = 1; days <= 7; days++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Semantics(
                      button: true,
                      selected: days == current,
                      toggled: days == current,
                      label: '$days day${days == 1 ? '' : 's'} per week',
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          ref
                              .read(onboardingDraftProvider.notifier)
                              .updateWeeklyGoal(days);
                        },
                        child: AnimatedContainer(
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : const Duration(milliseconds: 150),
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: days == current
                                ? accent.base
                                : surface.surface2,
                            borderRadius: BorderRadius.circular(
                                AppRadius.buttonSecondary),
                          ),
                          child: Text(
                            '$days',
                            style: AppText.button(
                              color: days == current
                                  ? accent.onAccent
                                  : surface.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 32),
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
