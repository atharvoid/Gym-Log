import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gymlog/core/providers/app_info_provider.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import 'package:gymlog/core/providers/premium_provider.dart';
import 'package:gymlog/core/providers/settings_provider.dart';
import 'package:gymlog/core/services/sync_engine.dart';
import 'package:gymlog/core/services/sync_entitlement_gate.dart';
import 'package:gymlog/core/services/workout_export_service.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/core/utils/tap_guard.dart';
import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';
import 'package:gymlog/features/profile/presentation/providers/profile_provider.dart';
import 'package:gymlog/features/profile/presentation/providers/profile_stats_provider.dart';
import 'package:gymlog/shared/widgets/premium_paywall.dart';
import 'package:gymlog/shared/widgets/ui/app_action_row.dart';
import 'package:gymlog/shared/widgets/ui/app_card.dart';
import 'package:gymlog/shared/widgets/ui/app_dialog.dart';
import 'package:gymlog/shared/widgets/ui/branded_bottom_sheet.dart';
import 'package:gymlog/shared/widgets/ui/time_range_filter.dart';
import 'package:gymlog/core/config/legal_links.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Weekly-goal picker, shared by Settings and the Profile goal ring.
Future<void> showWeeklyGoalSheet(BuildContext context, WidgetRef ref) async {
  final current = ref.read(weeklyGoalProvider);
  HapticFeedback.lightImpact();
  final accent = context.accent;

  await showBrandedBottomSheet<void>(
    context: context,
    title: 'Weekly goal',
    subtitle: 'How many days a week do you want to train?',
    child: Row(
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
                    ref.read(weeklyGoalProvider.notifier).setGoal(days);
                    Navigator.of(context, rootNavigator: true).pop();
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
                          : AppColors.surfaceRaised,
                      borderRadius: BorderRadius.circular(AppRadius.buttonSecondary),
                    ),
                    child: Text(
                      '$days',
                      style: AppText.button(
                        color: days == current
                            ? AppColors.textPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

/// Settings — grouped rows, clear information architecture, zero social clutter.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool? _syncEnabled;

  @override
  void initState() {
    super.initState();
    _loadSyncPref();
  }

  Future<void> _loadSyncPref() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _syncEnabled = prefs.getBool(kSyncEnabledKey) ?? true;
      });
    }
  }

  Future<void> _toggleSync(bool value) async {
    final isPremium = ref.read(isPremiumProvider);
    final user = ref.read(authProvider);
    final userId = user?.id ?? '';
    if (userId.isEmpty) return;

    HapticFeedback.selectionClick();
    final gate = ref.read(syncEntitlementGateProvider);
    final engine = ref.read(syncEngineProvider);

    await gate.setSyncEnabled(value);
    if (mounted) setState(() => _syncEnabled = value);

    if (!value) {
      // Toggle OFF: pause sync engine (void — no await needed).
      engine.pauseSync(userId);
    } else {
      // Toggle ON: resume sync engine and pull.
      await engine.resumeSync(userId, isPremium: isPremium);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final isPremium = ref.watch(isPremiumProvider);
    final unit = ref.watch(weightUnitProvider);
    final restSeconds = ref.watch(defaultRestSecondsProvider);
    final goal = ref.watch(weeklyGoalProvider);
    final versionAsync = ref.watch(appVersionProvider);
    final accent = context.accent;

    final version = versionAsync.valueOrNull ?? kAppVersionFallback;

    // Determine sync subtitle based on premium + toggle state.
    final String syncSubtitle;
    if (!isPremium) {
      syncSubtitle = 'Upgrade to Pro to sync across devices';
    } else if (_syncEnabled == false) {
      syncSubtitle = 'Sync paused. Your data stays on this device.';
    } else {
      syncSubtitle = 'Backup across devices and protect against data loss';
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.bgBase,
        appBar: AppBar(
          backgroundColor: AppColors.bgBase,
          scrolledUnderElevation: 0,
          titleSpacing: 0,
          leading: IconButton(
            tooltip: 'Back',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: const Icon(Icons.arrow_back_ios_new,
                size: 18, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
          title: Text('Settings', style: AppText.sheetTitle()),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              const _GroupHeader('ACCOUNT'),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    Semantics(
                      hint: "Navigates to paywall",
                      child: AppActionRow(
                        icon: Icons.workspace_premium_rounded,
                        iconColor: accent.light,
                        title: isPremium ? 'GymLog Pro' : 'Upgrade to Pro',
                        subtitle: isPremium
                            ? 'Active — full history unlocked'
                            : 'Full analytics history & more',
                        onTap: () => _openPremium(context, isPremium: isPremium),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              const _GroupHeader('PREFERENCES'),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    AppActionRow(
                      icon: Icons.scale_rounded,
                      iconColor: accent.light,
                      title: 'Weight unit',
                      subtitle: unit == 'kg' ? 'Kilograms (kg)' : 'Pounds (lbs)',
                      onTap: () => _pickWeightUnit(context, ref, unit),
                    ),
                    const AppActionDivider(),
                    AppActionRow(
                      icon: Icons.flag_rounded,
                      iconColor: accent.light,
                      title: 'Weekly goal',
                      subtitle: '$goal workout${goal != 1 ? 's' : ''} per week',
                      onTap: () => showWeeklyGoalSheet(context, ref),
                    ),
                    const AppActionDivider(),
                    AppActionRow(
                      icon: Icons.timer_outlined,
                      iconColor: accent.light,
                      title: 'Rest timer',
                      subtitle: restSeconds == 0
                          ? 'Off'
                          : '$restSeconds seconds between sets',
                      onTap: () => _pickRestTimer(context, ref, restSeconds),
                    ),
                    const AppActionDivider(),
                    AppActionRow(
                      icon: Icons.palette_outlined,
                      iconColor: accent.light,
                      title: 'Appearance',
                      subtitle: 'Accent color',
                      onTap: () {
                        if (!tapGuard()) return;
                        HapticFeedback.lightImpact();
                        context.push('/settings/appearance');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              const _GroupHeader('DATA'),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    AppActionRow(
                      icon: Icons.download_rounded,
                      title: 'Import workouts',
                      subtitle: 'From Hevy or Strong (CSV)',
                      onTap: () {
                        if (!tapGuard()) return;
                        HapticFeedback.lightImpact();
                        context.push('/settings/import');
                      },
                    ),
                    if (profile != null) ...[
                      const AppActionDivider(),
                      AppActionRow(
                        icon: Icons.ios_share_rounded,
                        title: 'Export workouts',
                        subtitle: 'CSV of every set — yours to keep',
                        onTap: () => _exportWorkouts(
                            context, ref, profile.id, profile.displayName),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // ── CLOUD SYNC ──────────────────────────────────────────
              const _GroupHeader('CLOUD SYNC'),
              AppCard(
                padding: EdgeInsets.zero,
                child: Semantics(
                  button: !isPremium,
                  label: isPremium
                      ? 'Sync workout data to cloud. Currently ${_syncEnabled == false ? "off" : "on"}.'
                      : 'Upgrade to Pro to sync across devices',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: isPremium
                          ? null
                          : () {
                              if (!tapGuard()) return;
                              showPremiumPaywall(context,
                                  source: PaywallSource.sync);
                            },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.sync_rounded,
                              size: 20,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Sync workout data to cloud',
                                        style: AppText.rowLabel(
                                            color: AppColors.textPrimary),
                                      ),
                                      if (!isPremium) ...[
                                        const SizedBox(width: 8),
                                        const ProLockPill(),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    syncSubtitle,
                                    style: AppText.meta(
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            if (isPremium)
                              Switch.adaptive(
                                value: _syncEnabled ?? true,
                                onChanged: (v) => _toggleSync(v),
                                activeTrackColor: accent.base,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),

              const _GroupHeader('HELP'),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    AppActionRow(
                      icon: Icons.shield_outlined,
                      title: 'Your data',
                      subtitle: 'Stored on-device, backed up to your account',
                      onTap: () => _showDataInfo(context),
                    ),
                    const AppActionDivider(),
                    AppActionRow(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      subtitle: 'Local-first. No tracking.',
                      onTap: () => _openExternalUrl(context, kPrivacyPolicyUrl),
                    ),
                    const AppActionDivider(),
                    AppActionRow(
                      icon: Icons.gavel_rounded,
                      title: 'Terms of Service',
                      subtitle: 'The short, readable kind',
                      onTap: () => _openExternalUrl(context, kTermsOfServiceUrl),
                    ),
                    const AppActionDivider(),
                    AppActionRow(
                      icon: Icons.info_outline_rounded,
                      title: 'Version',
                      subtitle: 'GymLog $version',
                      showChevron: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              _SignOutButton(),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: () {
                    if (!tapGuard()) return;
                    HapticFeedback.selectionClick();
                    context.push('/settings/delete-account');
                  },
                  child: Text(
                    'Delete account',
                    style: AppText.button(color: AppColors.error),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const kAppVersionFallback = '1.0.0';

class _GroupHeader extends StatelessWidget {
  final String label;
  const _GroupHeader(this.label);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(label, style: AppText.groupHeader()),
      );
}

class _SignOutButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      button: true,
      label: 'Sign out',
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.cardAll,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: AppRadius.cardAll,
          onTap: () async {
            if (!tapGuard()) return;
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
              borderRadius: AppRadius.cardAll,
            ),
            child: Text(
              'Sign Out',
              style: AppText.button(color: AppColors.error),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _pickWeightUnit(BuildContext context, WidgetRef ref, String unit) async {
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
        color: AppColors.textSecondary,
      ),
      PickerOption(
        value: 'lbs',
        label: 'Pounds',
        subtitle: 'lbs',
        icon: Icons.fitness_center_rounded,
        color: AppColors.textSecondary,
      ),
    ],
  );
  if (selected != null) {
    await ref.read(settingsActionsProvider).setWeightUnit(selected);
  }
}

Future<void> _pickRestTimer(BuildContext context, WidgetRef ref, int restSeconds) async {
  HapticFeedback.lightImpact();
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
          icon: s == 0 ? Icons.timer_off_outlined : Icons.timer_outlined,
          color: AppColors.textSecondary,
        ),
    ],
  );
  if (selected != null) {
    await ref.read(settingsActionsProvider).setDefaultRestSeconds(selected);
  }
}

void _openPremium(BuildContext context, {required bool isPremium}) {
  if (!tapGuard()) return;
  if (isPremium) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        'You are on GymLog Pro. Thanks for the support!',
        style: AppText.button(),
      ),
      backgroundColor: AppColors.bgSurface,
      behavior: SnackBarBehavior.floating,
    ));
  } else {
    showPremiumPaywall(context);
  }
}

Future<void> _exportWorkouts(BuildContext context, WidgetRef ref, String userId,
    String displayName) async {
  HapticFeedback.lightImpact();
  final messenger = ScaffoldMessenger.of(context);
  try {
    final service = WorkoutExportService(ref.read(databaseProvider));
    final file = await service.writeCsvFile(userId);
    final who = displayName.trim().isEmpty ? '' : ' — ${displayName.trim()}';
    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path, mimeType: 'text/csv')],
      subject: 'GymLog workout export$who',
      text: 'GymLog training history$who',
    ));
  } catch (e) {
    messenger.showSnackBar(SnackBar(
      content: Text(
        'Export failed. Please try again.',
        style: AppText.button(),
      ),
      backgroundColor: AppColors.bgSurface,
      behavior: SnackBarBehavior.floating,
    ));
  }
}

void _showDataInfo(BuildContext context) {
  HapticFeedback.lightImpact();
  showAppConfirmDialog(
    context: context,
    title: 'Local-first, cloud-backed',
    message: 'Every workout is saved instantly to a private database '
        'on this device — the app works fully offline. A '
        'compressed copy is then mirrored to your private '
        'account so your history survives a reinstall or a new '
        'phone. Only you can read it.',
    confirmLabel: 'Got it',
    cancelLabel: 'Close',
  );
}

Future<void> _openExternalUrl(BuildContext context, String url) async {
  HapticFeedback.lightImpact();
  final messenger = ScaffoldMessenger.of(context);
  final ok = await launchUrl(
    Uri.parse(url),
    mode: LaunchMode.externalApplication,
  );
  if (!ok) {
    messenger.showSnackBar(SnackBar(
      content: Text(
        'Could not open link.',
        style: AppText.button(),
      ),
      backgroundColor: AppColors.bgSurface,
      behavior: SnackBarBehavior.floating,
    ));
  }
}
