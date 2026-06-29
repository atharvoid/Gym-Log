import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import 'package:gymlog/core/providers/settings_provider.dart';
import 'package:gymlog/core/services/profile_sync_service.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';
import 'package:gymlog/features/auth/presentation/providers/onboarding_draft_provider.dart';
import 'package:gymlog/features/profile/presentation/providers/profile_provider.dart';
import 'package:gymlog/features/profile/presentation/providers/profile_stats_provider.dart';
import 'package:gymlog/features/routines/presentation/data/explore_catalog.dart';
import 'package:gymlog/shared/widgets/ui/app_card.dart';
import 'package:gymlog/shared/widgets/ui/goal_ring.dart';
import 'package:gymlog/shared/widgets/ui/primary_button.dart';
import 'package:gymlog/shared/widgets/ui/secondary_button.dart';

class StepCompletion extends ConsumerStatefulWidget {
  final VoidCallback onStartTour;
  final VoidCallback onSkipTour;

  const StepCompletion({
    super.key,
    required this.onStartTour,
    required this.onSkipTour,
  });

  @override
  ConsumerState<StepCompletion> createState() => _StepCompletionState();
}

class _StepCompletionState extends ConsumerState<StepCompletion> {
  bool _isSaving = false;

  Future<void> _persistAndComplete(bool startTour) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final user = ref.read(authProvider);
      if (user != null) {
        final draft = ref.read(onboardingDraftProvider);

        // 1. Submit display name (local write + background remote sync).
        //    Mark onboarding complete remotely so future logins treat this
        //    profile authoritatively as finished.
        await ref.read(profileSyncProvider).submitDisplayName(
              userId: user.id,
              email: user.email ?? '',
              name: draft.name,
              onboardingComplete: true,
            );

        // 2. Set age in local DB if present
        if (draft.age != null) {
          await ref.read(databaseProvider).userDao.setAge(user.id, draft.age);
        }

        // Set gender in local DB
        final genderValue =
            draft.gender == 'prefer_not_to_say' ? null : draft.gender;
        await ref
            .read(databaseProvider)
            .userDao
            .setGender(user.id, genderValue);

        // 3. Set experience level in local DB
        await ref
            .read(databaseProvider)
            .userDao
            .setExperienceLevel(user.id, draft.level);

        // 4. Set weight unit
        await ref.read(settingsActionsProvider).setWeightUnit(draft.unit);

        // 5. Set weekly goal
        await ref.read(weeklyGoalProvider.notifier).setGoal(draft.weeklyGoal);

        // 6. Mark onboarding complete in local DB
        await ref
            .read(databaseProvider)
            .userDao
            .setOnboardingComplete(user.id, complete: true);

        // 7. Invalidate profile so observers refresh
        ref.invalidate(currentUserProfileProvider);
      }

      if (mounted) {
        if (startTour) {
          widget.onStartTour();
        } else {
          widget.onSkipTour();
        }
      }
    } catch (e) {
      debugPrint('[StepCompletion] Error saving onboarding data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save settings. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(onboardingDraftProvider);
    final accent = context.accent;
    final surface = context.surface;

    final name = draft.name;
    final level = draft.level;
    final unit = draft.unit;
    final weeklyGoal = draft.weeklyGoal;

    // Dynamically query template count matching user experience level
    final levelTemplatesCount =
        exploreTemplates.where((t) => t.level.name == level).length;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 48),
          Text(
            'Setup complete',
            style: AppText.caption(color: surface.textSecondary).copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "You're all set,\n$name",
            style: AppText.screenTitle(color: surface.textPrimary).copyWith(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your personalised training plan is ready to launch.',
            style: AppText.body(color: surface.textSecondary).copyWith(
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _SummaryRow(
                  icon: Icons.directions_run_rounded,
                  title: 'Level & Programs',
                  value:
                      '${level[0].toUpperCase()}${level.substring(1)} ($levelTemplatesCount starter programs)',
                  iconColor: accent.light,
                ),
                const Divider(height: 24, color: AppColors.borderSubtle),
                _SummaryRow(
                  icon: Icons.flag_rounded,
                  title: 'Weekly Target',
                  value: '$weeklyGoal workouts / week',
                  iconColor: accent.light,
                  trailing: const GoalRing(progress: 0.0, size: 20),
                ),
                const Divider(height: 24, color: AppColors.borderSubtle),
                _SummaryRow(
                  icon: Icons.scale_rounded,
                  title: 'Logging Unit',
                  value: unit == 'kg' ? 'Kilograms (kg)' : 'Pounds (lbs)',
                  iconColor: accent.light,
                ),
              ],
            ),
          ),
          const Spacer(),
          PrimaryButton(
            label: 'Take the 60-second tour',
            onPressed: _isSaving ? null : () => _persistAndComplete(true),
            isLoading: _isSaving,
            icon: Icons.tour_rounded,
          ),
          const SizedBox(height: 12),
          SecondaryButton(
            label: 'Skip tour & start',
            onPressed: _isSaving ? null : () => _persistAndComplete(false),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color iconColor;
  final Widget? trailing;

  const _SummaryRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.iconColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppText.caption(color: surface.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppText.body(color: surface.textPrimary).copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
