import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import 'package:gymlog/core/providers/settings_provider.dart';
import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';
import 'package:gymlog/features/profile/presentation/providers/profile_provider.dart';
import 'package:gymlog/features/profile/presentation/providers/profile_stats_provider.dart';
import 'package:gymlog/features/profile/presentation/screens/settings_screen.dart'; // for showWeeklyGoalSheet
import 'package:gymlog/core/services/profile_sync_service.dart';
import 'package:gymlog/shared/widgets/ui/app_action_row.dart';
import 'package:gymlog/shared/widgets/ui/app_card.dart';
import 'package:gymlog/shared/widgets/ui/branded_bottom_sheet.dart';
import 'package:gymlog/shared/widgets/ui/time_range_filter.dart';
import 'package:gymlog/shared/widgets/ui/app_dialog.dart';
import 'package:gymlog/shared/widgets/ui/primary_button.dart';
import 'package:gymlog/core/utils/tap_guard.dart';

class PersonalDetailsScreen extends ConsumerWidget {
  const PersonalDetailsScreen({super.key});

  String _capitalize(String? s) {
    if (s == null || s.isEmpty) return '';
    return s[0].toUpperCase() + s.substring(1);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    if (user == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final unit = ref.watch(weightUnitProvider);
    final goal = ref.watch(weeklyGoalProvider);
    final accent = context.accent;
    final surface = context.surface;

    final String displayName = profile?.displayName.trim().isEmpty ?? true
        ? 'Athlete'
        : profile!.displayName;
    final String ageStr = profile?.age == null
        ? 'Prefer not to say'
        : '${profile!.age} years old';

    final String genderStr;
    if (profile?.gender == null) {
      genderStr = 'Prefer not to say';
    } else if (profile!.gender == 'male') {
      genderStr = 'Male';
    } else if (profile.gender == 'female') {
      genderStr = 'Female';
    } else {
      genderStr = _capitalize(profile.gender);
    }

    final String expStr = profile?.experienceLevel == null
        ? 'Not set'
        : _capitalize(profile!.experienceLevel);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: surface.isLight
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: surface.bgBase,
        appBar: AppBar(
          backgroundColor: surface.bgBase,
          scrolledUnderElevation: 0,
          titleSpacing: 0,
          leading: IconButton(
            tooltip: 'Back',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: Icon(Icons.arrow_back_ios_new,
                size: 18, color: surface.textPrimary),
            onPressed: () => context.pop(),
          ),
          title: Text('Personal details',
              style: AppText.sheetTitle(color: surface.textPrimary)),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _GroupHeader('PROFILE DETAILS', color: surface.textSecondary),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    // 1. Display Name
                    AppActionRow(
                      icon: Icons.person_outline_rounded,
                      iconColor: accent.light,
                      title: 'Display name',
                      subtitle: displayName,
                      onTap: () async {
                        if (!tapGuard()) return;
                        HapticFeedback.lightImpact();
                        final newName = await showAppTextInputDialog(
                          context: context,
                          title: 'Change name',
                          hint: 'Display name',
                          initialValue: profile?.displayName ?? '',
                          maxLength: 40,
                        );
                        if (newName != null && newName.trim().isNotEmpty) {
                          if (!context.mounted) return;
                          final messenger = ScaffoldMessenger.of(context);
                          final bgSurface = context.surface.bgSurface;
                          final success = await ref
                              .read(profileSyncProvider)
                              .submitDisplayName(
                                userId: user.id,
                                email: user.email ?? '',
                                name: newName,
                              );
                          if (success) {
                            ref.invalidate(currentUserProfileProvider);
                          } else {
                            messenger.showSnackBar(SnackBar(
                              content: Text(
                                  "Couldn't save your name. Try again.",
                                  style: AppText.button()),
                              backgroundColor: bgSurface,
                              behavior: SnackBarBehavior.floating,
                            ));
                          }
                        }
                      },
                    ),
                    const AppActionDivider(),
                    // 2. Age
                    AppActionRow(
                      icon: Icons.cake_outlined,
                      iconColor: accent.light,
                      title: 'Age',
                      subtitle: ageStr,
                      onTap: () async {
                        if (!tapGuard()) return;
                        HapticFeedback.lightImpact();
                        await showBrandedBottomSheet<void>(
                          context: context,
                          title: 'Age',
                          subtitle:
                              'Helps tailor volume & recovery suggestions.',
                          child: _AgeStepperSheet(
                            initialAge: profile?.age,
                            onSave: (newAge) async {
                              await ref
                                  .read(databaseProvider)
                                  .userDao
                                  .setAge(user.id, newAge);
                            },
                          ),
                        );
                      },
                    ),
                    const AppActionDivider(),
                    // 3. Gender
                    AppActionRow(
                      icon: Icons.wc_rounded,
                      iconColor: accent.light,
                      title: 'Gender',
                      subtitle: genderStr,
                      onTap: () async {
                        if (!tapGuard()) return;
                        HapticFeedback.lightImpact();
                        final currentGender =
                            profile?.gender ?? 'prefer_not_to_say';
                        final selected = await showBrandedPickerSheet<String>(
                          context: context,
                          title: 'Gender',
                          selected: currentGender,
                          options: const [
                            PickerOption(
                              value: 'female',
                              label: 'Female',
                              icon: Icons.female_rounded,
                            ),
                            PickerOption(
                              value: 'male',
                              label: 'Male',
                              icon: Icons.male_rounded,
                            ),
                            PickerOption(
                              value: 'prefer_not_to_say',
                              label: 'Prefer not to say',
                              icon:
                                  Icons.do_not_disturb_on_total_silence_rounded,
                            ),
                          ],
                        );
                        if (selected != null) {
                          final genderValue =
                              selected == 'prefer_not_to_say' ? null : selected;
                          await ref
                              .read(databaseProvider)
                              .userDao
                              .setGender(user.id, genderValue);
                        }
                      },
                    ),
                    const AppActionDivider(),
                    // 4. Experience Level
                    AppActionRow(
                      icon: Icons.fitness_center_rounded,
                      iconColor: accent.light,
                      title: 'Experience level',
                      subtitle: expStr,
                      onTap: () async {
                        if (!tapGuard()) return;
                        HapticFeedback.lightImpact();
                        final currentLevel =
                            profile?.experienceLevel ?? 'beginner';
                        final selected = await showBrandedPickerSheet<String>(
                          context: context,
                          title: 'Experience level',
                          selected: currentLevel,
                          options: const [
                            PickerOption(
                              value: 'beginner',
                              label: 'Beginner',
                              subtitle: 'Just starting out',
                              icon: Icons.explore_outlined,
                            ),
                            PickerOption(
                              value: 'intermediate',
                              label: 'Intermediate',
                              subtitle: 'Consistent training history',
                              icon: Icons.fitness_center_rounded,
                            ),
                            PickerOption(
                              value: 'advanced',
                              label: 'Advanced',
                              subtitle: 'Years of dedicated training',
                              icon: Icons.stars_rounded,
                            ),
                          ],
                        );
                        if (selected != null) {
                          await ref
                              .read(databaseProvider)
                              .userDao
                              .setExperienceLevel(user.id, selected);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              _GroupHeader('PREFERENCES', color: surface.textSecondary),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    // 5. Weight unit
                    AppActionRow(
                      icon: Icons.scale_rounded,
                      iconColor: accent.light,
                      title: 'Weight unit',
                      subtitle:
                          unit == 'kg' ? 'Kilograms (kg)' : 'Pounds (lbs)',
                      onTap: () async {
                        if (!tapGuard()) return;
                        HapticFeedback.lightImpact();
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
                            ),
                            PickerOption(
                              value: 'lbs',
                              label: 'Pounds',
                              subtitle: 'lbs',
                              icon: Icons.fitness_center_rounded,
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
                    const AppActionDivider(),
                    // 6. Weekly Goal
                    AppActionRow(
                      icon: Icons.flag_rounded,
                      iconColor: accent.light,
                      title: 'Weekly goal',
                      subtitle: '$goal workout${goal != 1 ? 's' : ''} per week',
                      onTap: () => showWeeklyGoalSheet(context, ref),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final String label;
  final Color color;
  const _GroupHeader(this.label, {required this.color});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(label, style: AppText.groupHeader(color: color)),
      );
}

class _AgeStepperSheet extends StatefulWidget {
  final int? initialAge;
  final ValueChanged<int?> onSave;

  const _AgeStepperSheet({this.initialAge, required this.onSave});

  @override
  State<_AgeStepperSheet> createState() => _AgeStepperSheetState();
}

class _AgeStepperSheetState extends State<_AgeStepperSheet> {
  int? _age;

  @override
  void initState() {
    super.initState();
    _age = widget.initialAge;
  }

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    final currentAge = _age ?? 25;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Semantics(
              button: true,
              label: 'Decrease age',
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: surface.surface2,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: currentAge > 14
                      ? () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _age = currentAge - 1;
                          });
                        }
                      : null,
                  icon: Icon(
                    Icons.remove_rounded,
                    color: currentAge > 14
                        ? surface.textPrimary
                        : surface.textSecondary.withValues(alpha: 0.3),
                    size: 28,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 32),
            SizedBox(
              width: 100,
              child: Center(
                child: Text(
                  _age == null ? '—' : '$currentAge',
                  style: AppText.heroStat(color: surface.textPrimary).copyWith(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 32),
            Semantics(
              button: true,
              label: 'Increase age',
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: surface.surface2,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: currentAge < 100
                      ? () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _age = currentAge + 1;
                          });
                        }
                      : null,
                  icon: Icon(
                    Icons.add_rounded,
                    color: currentAge < 100
                        ? surface.textPrimary
                        : surface.textSecondary.withValues(alpha: 0.3),
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  widget.onSave(null);
                  Navigator.of(context, rootNavigator: true).pop();
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: surface.borderSubtle),
                  ),
                ),
                child: Text(
                  'Prefer not to say',
                  style: AppText.button(color: surface.textSecondary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PrimaryButton(
                label: 'Save',
                isFullWidth: true,
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  widget.onSave(currentAge);
                  Navigator.of(context, rootNavigator: true).pop();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
