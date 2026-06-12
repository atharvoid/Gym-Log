import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymlog/core/providers/premium_provider.dart';
import 'package:gymlog/core/providers/settings_provider.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';
import 'package:gymlog/features/profile/presentation/providers/profile_provider.dart';
import 'package:gymlog/features/profile/presentation/providers/profile_stats_provider.dart';
import 'package:gymlog/features/routines/presentation/widgets/routine_detail_styles.dart';
import 'package:gymlog/shared/widgets/premium_paywall.dart';
import 'package:gymlog/shared/widgets/ui/app_dialog.dart';
import 'package:gymlog/shared/widgets/ui/time_range_filter.dart';

/// App version shown in Settings — bumped with each release.
const kAppVersion = '1.0.0';

/// Weekly-goal picker, shared by Settings and the Profile goal ring.
Future<void> showWeeklyGoalSheet(BuildContext context, WidgetRef ref) async {
  final current = ref.read(weeklyGoalProvider);
  HapticFeedback.lightImpact();
  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) => Container(
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF6A6A6A),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Weekly goal',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'How many days a week do you want to train?',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var days = 1; days <= 7; days++)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref.read(weeklyGoalProvider.notifier).setGoal(days);
                        Navigator.of(sheetCtx).pop();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 40,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: days == current
                              ? AppColors.accentPrimary
                              : AppColors.surfaceRaised,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$days',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: days == current
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Settings — grouped rows, Hevy-style information architecture, zero
/// social clutter. Every row does something real.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final isPremium = ref.watch(isPremiumProvider);
    final unit = ref.watch(weightUnitProvider);
    final restSeconds = ref.watch(defaultRestSecondsProvider);
    final goal = ref.watch(weeklyGoalProvider);

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgBase,
        scrolledUnderElevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: -0.3,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
        children: [
          const _GroupHeader('ACCOUNT'),
          _Group(children: [
            _Row(
              icon: Icons.alternate_email_rounded,
              title: profile?.displayName ?? 'Athlete',
              subtitle: profile?.email ?? '',
              showChevron: false,
            ),
            _Row(
              icon: Icons.workspace_premium_rounded,
              iconColor: const Color(0xFFCBB2FF),
              title: isPremium ? 'GymLog Pro' : 'Upgrade to Pro',
              subtitle: isPremium
                  ? 'Active — full history unlocked'
                  : 'Full analytics history & more',
              onTap: () {
                if (isPremium) {
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                      'You are on GymLog Pro. Thanks for the support!',
                      style: GoogleFonts.inter(color: AppColors.textPrimary),
                    ),
                    backgroundColor: AppColors.bgSurface,
                    behavior: SnackBarBehavior.floating,
                  ));
                } else {
                  showPremiumPaywall(context);
                }
              },
            ),
          ]),
          const SizedBox(height: 22),

          const _GroupHeader('PREFERENCES'),
          _Group(children: [
            _Row(
              icon: Icons.scale_rounded,
              title: 'Weight unit',
              subtitle: unit == 'kg' ? 'Kilograms (kg)' : 'Pounds (lbs)',
              onTap: () async {
                final selected = await showBrandedPickerSheet<String>(
                  context: context,
                  title: 'Weight Unit',
                  selected: unit,
                  options: const [
                    PickerOption(
                      value: 'kg',
                      label: 'Kilograms',
                      subtitle: 'kg',
                      icon: Icons.fitness_center_rounded,
                      color: AppColors.textPrimary,
                    ),
                    PickerOption(
                      value: 'lbs',
                      label: 'Pounds',
                      subtitle: 'lbs',
                      icon: Icons.fitness_center_rounded,
                      color: Color(0xFFB98CFF),
                    ),
                  ],
                );
                if (selected != null) {
                  await ref
                      .read(settingsActionsProvider)
                      .setWeightUnit(selected);
                }
              },
            ),
            _Row(
              icon: Icons.flag_rounded,
              title: 'Weekly goal',
              subtitle: '$goal workout${goal != 1 ? 's' : ''} per week',
              onTap: () => showWeeklyGoalSheet(context, ref),
            ),
            _Row(
              icon: Icons.timer_outlined,
              title: 'Rest timer',
              subtitle: restSeconds == 0
                  ? 'Off'
                  : '$restSeconds seconds between sets',
              onTap: () async {
                final selected = await showBrandedPickerSheet<int>(
                  context: context,
                  title: 'Rest Between Sets',
                  selected: restSeconds,
                  options: [
                    for (final s in const [0, 30, 60, 90, 120, 150, 180])
                      PickerOption(
                        value: s,
                        label: s == 0 ? 'Off' : '$s seconds',
                        subtitle: s == 90 ? 'Recommended' : null,
                        icon: s == 0
                            ? Icons.timer_off_outlined
                            : Icons.timer_outlined,
                        color: s == 90
                            ? const Color(0xFFB98CFF)
                            : AppColors.textSecondary,
                      ),
                  ],
                );
                if (selected != null) {
                  await ref
                      .read(settingsActionsProvider)
                      .setDefaultRestSeconds(selected);
                }
              },
            ),
          ]),
          const SizedBox(height: 22),

          const _GroupHeader('HELP'),
          _Group(children: [
            _Row(
              icon: Icons.shield_outlined,
              title: 'Your data',
              subtitle: 'Workouts never leave this device',
              onTap: () {
                HapticFeedback.lightImpact();
                showAppConfirmDialog(
                  context: context,
                  title: 'Local-first by design',
                  message:
                      'Every workout, set and record is stored in a private '
                      'database on this device. Your Google account is used '
                      'for sign-in only — training data is never uploaded.',
                  confirmLabel: 'Got it',
                  cancelLabel: 'Close',
                );
              },
            ),
            const _Row(
              icon: Icons.info_outline_rounded,
              title: 'Version',
              subtitle: 'GymLog $kAppVersion',
              showChevron: false,
            ),
          ]),
          const SizedBox(height: 28),

          // ── Sign out — red, bottom, deliberate ─────────────────────────
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                final confirmed = await showAppConfirmDialog(
                  context: context,
                  title: 'Sign out?',
                  message: 'Your workouts are stored locally and will be here '
                      'when you sign back in.',
                  confirmLabel: 'Sign Out',
                  isDestructive: true,
                );
                if (confirmed) {
                  await ref.read(authRepositoryProvider).signOut();
                }
              },
              child: Container(
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Sign Out',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final String label;
  const _GroupHeader(this.label);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: AppColors.textSecondary,
          ),
        ),
      );
}

class _Group extends StatelessWidget {
  final List<Widget> children;
  const _Group({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: RDStyles.cardGradient,
        borderRadius: BorderRadius.circular(18),
        border: RDStyles.hairlineBorder,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 56),
                child: Container(height: 1, color: RDStyles.hairline),
              ),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool showChevron;

  const _Row({
    required this.icon,
    this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Icon(icon,
                    size: 20, color: iconColor ?? AppColors.textSecondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null && showChevron)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Colors.white.withValues(alpha: 0.25),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
