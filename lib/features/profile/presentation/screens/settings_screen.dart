import 'package:flutter/foundation.dart' show kDebugMode;
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
import 'package:gymlog/core/services/sign_out_coordinator.dart';
import 'package:gymlog/core/services/exercise_media_cache_manager.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/core/utils/tap_guard.dart';
import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';
import 'package:gymlog/features/auth/presentation/providers/tour_provider.dart';
import 'package:gymlog/features/profile/presentation/providers/profile_provider.dart';
import 'package:gymlog/features/profile/presentation/providers/profile_stats_provider.dart';
import 'package:gymlog/features/workout/presentation/providers/rest_timer_provider.dart';
import 'package:gymlog/shared/widgets/premium_paywall.dart';
import 'package:gymlog/shared/widgets/ui/app_action_row.dart';
import 'package:gymlog/shared/widgets/ui/app_card.dart';
import 'package:gymlog/shared/widgets/ui/app_dialog.dart';
import 'package:gymlog/shared/widgets/ui/app_snack_bar.dart';
import 'package:gymlog/shared/widgets/ui/branded_bottom_sheet.dart';
import 'package:gymlog/shared/widgets/ui/duration_slider.dart';
import 'package:gymlog/shared/widgets/ui/time_range_filter.dart';
import 'package:gymlog/core/config/legal_links.dart';
import 'package:gymlog/shared/widgets/tour/spotlight_tour_overlay.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gymlog/shared/layout/adaptive.dart';

/// Weekly-goal picker, shared by Settings and the Profile goal ring.
Future<void> showWeeklyGoalSheet(BuildContext context, WidgetRef ref) async {
  final current = ref.read(weeklyGoalProvider);
  HapticFeedback.lightImpact();
  final accent = context.accent;
  final surface = context.surface;

  await showBrandedBottomSheet<void>(
    context: context,
    title: 'Weekly goal',
    subtitle: 'How many days a week do you want to train?',
    // C32: was a 7-way Expanded Row. Splitting a sheet only ~24dp-inset on
    // each side into 7 equal flex slots, each further shrunk by 4dp/side of
    // its own padding, left the actual tap target under 44dp on effectively
    // every phone width up to ~410dp (as low as ~31dp at 320dp) — a real
    // touch-target miss on the single most common device band (booked from
    // B20). Fixed-size buttons in a centered Wrap guarantee 46x48 everywhere
    // and simply drop to a second row on screens too narrow for all seven.
    child: Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var days = 1; days <= 7; days++)
          Semantics(
            button: true,
            selected: days == current,
            excludeSemantics: true,
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
                width: 46,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: days == current ? accent.base : surface.surface2,
                  borderRadius:
                      BorderRadius.circular(AppRadius.buttonSecondary),
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
  int _devTapCount = 0;

  /// Key attached to the Rest timer row — used by the step-3 tour spotlight
  /// so the overlay can locate its screen position from the Settings route.
  final GlobalKey _restTimerRowKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadSyncPref();
  }

  Future<void> _loadSyncPref() async {
    // A preferences read should never be able to take the screen down. If it
    // fails we fall back to the same default the getter already used.
    var enabled = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      enabled = prefs.getBool(kSyncEnabledKey) ?? true;
    } catch (_) {
      enabled = true;
    }
    if (mounted) {
      setState(() => _syncEnabled = enabled);
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
    final previous = _syncEnabled;

    try {
      await gate.setSyncEnabled(value);
      if (mounted) setState(() => _syncEnabled = value);

      if (!value) {
        engine.pauseSync(userId);
      } else {
        await engine.resumeSync(userId, isPremium: isPremium);
      }
    } catch (_) {
      // The switch must not sit in a position the engine never reached. A
      // toggle reading ON over a sync that failed to resume is a silent
      // data-loss story: the user believes they are backed up.
      if (!mounted) return;
      setState(() => _syncEnabled = previous);
      showAppSnackBar(
        context,
        message: "Couldn't change sync. Please try again.",
      );
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
    final surface = context.surface;

    final version = versionAsync.valueOrNull ?? kAppVersionFallback;

    final String syncSubtitle;
    if (!isPremium) {
      syncSubtitle = 'Upgrade to Pro to sync across devices';
    } else if (_syncEnabled == false) {
      syncSubtitle = 'Sync paused. Your data stays on this device.';
    } else {
      syncSubtitle = 'Backup across devices and protect against data loss';
    }

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
          title: Text('Settings',
              style: AppText.sheetTitle(color: surface.textPrimary)),
        ),
        body: AdaptiveContent(
            child: SafeArea(
          child: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _GroupHeader('ACCOUNT', color: surface.textSecondary),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        if (profile != null) ...[
                          AppActionRow(
                            icon: Icons.badge_outlined,
                            iconColor: accent.light,
                            title: 'Personal details',
                            subtitle: 'Age, gender, experience & more',
                            onTap: () {
                              if (!tapGuard()) return;
                              HapticFeedback.lightImpact();
                              context.push('/settings/personal');
                            },
                          ),
                        ],
                        Semantics(
                          hint: "Navigates to paywall",
                          child: AppActionRow(
                            icon: Icons.workspace_premium_rounded,
                            iconColor: accent.light,
                            title: isPremium ? 'GymLog Pro' : 'Upgrade to Pro',
                            subtitle: isPremium
                                ? 'Active (full history unlocked)'
                                : 'Full analytics history & more',
                            onTap: () =>
                                _openPremium(context, isPremium: isPremium),
                          ),
                        ),
                        if (isPremium) ...[
                          const AppActionDivider(),
                          AppActionRow(
                            icon: Icons.card_membership_rounded,
                            iconColor: accent.light,
                            title: 'Manage subscription',
                            subtitle: 'Change plans or cancel',
                            onTap: () async {
                              if (!tapGuard()) return;
                              HapticFeedback.lightImpact();
                              final service = ref.read(premiumServiceProvider);
                              final info = await service.getCustomerInfo();
                              final urlString = info?.managementURL;
                              if (!context.mounted) return;
                              if (urlString == null) {
                                showAppSnackBar(
                                  context,
                                  message: 'No active subscription found.',
                                );
                                return;
                              }
                              var opened = false;
                              try {
                                opened = await launchUrl(
                                  Uri.parse(urlString),
                                  mode: LaunchMode.externalApplication,
                                );
                              } catch (_) {
                                opened = false;
                              }
                              if (opened || !context.mounted) return;
                              showAppSnackBar(
                                context,
                                message:
                                    "Couldn't open the subscription page.",
                              );
                            },
                          ),
                        ],
                        const AppActionDivider(),
                        AppActionRow(
                          icon: Icons.restore_rounded,
                          iconColor: accent.light,
                          title: 'Restore purchases',
                          subtitle: 'Re-verify your Pro status',
                          onTap: () async {
                            if (!tapGuard()) return;
                            HapticFeedback.lightImpact();
                            try {
                              final service = ref.read(premiumServiceProvider);
                              final info = await service.restorePurchases();
                              if (!context.mounted) return;
                              if (info != null && hasPremium(info)) {
                                showAppSnackBar(
                                  context,
                                  message:
                                      'Purchases restored successfully. You are now Pro!',
                                );
                              } else {
                                showAppSnackBar(
                                  context,
                                  message:
                                      'No active purchases found to restore.',
                                );
                              }
                            } catch (_) {
                              if (!context.mounted) return;
                              showAppSnackBar(
                                context,
                                message: 'Restore failed. Please try again.',
                              );
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
                        AppActionRow(
                          icon: Icons.scale_rounded,
                          iconColor: accent.light,
                          title: 'Weight unit',
                          subtitle:
                              unit == 'kg' ? 'Kilograms (kg)' : 'Pounds (lbs)',
                          onTap: () => _pickWeightUnit(context, ref, unit),
                        ),
                        const AppActionDivider(),
                        AppActionRow(
                          icon: Icons.flag_rounded,
                          iconColor: accent.light,
                          title: 'Weekly goal',
                          subtitle:
                              '$goal workout${goal != 1 ? 's' : ''} per week',
                          onTap: () => showWeeklyGoalSheet(context, ref),
                        ),
                        const AppActionDivider(),
                        AppActionRow(
                          key: _restTimerRowKey,
                          icon: Icons.timer_outlined,
                          iconColor: accent.light,
                          title: 'Rest timer',
                          // m:ss, matching the mid-workout rest tile. The old
                          // "$restSeconds seconds" made the same value read
                          // differently in two places ("90 seconds" vs "1:30").
                          subtitle: restSeconds == 0
                              ? 'Off'
                              : '${formatDurationLabel(restSeconds)} between sets',
                          onTap: () =>
                              _pickRestTimer(context, ref, restSeconds),
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
                  _GroupHeader('DATA', color: surface.textSecondary),
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
                            subtitle: 'CSV of every set, yours to keep',
                            onTap: () => _exportWorkouts(
                                context, ref, profile.id, profile.displayName),
                          ),
                        ],
                        const AppActionDivider(),
                        AppActionRow(
                          icon: Icons.cleaning_services_rounded,
                          title: 'Clear exercise media cache',
                          subtitle:
                              'Free up cache space without touching workout data',
                          onTap: () async {
                            if (!tapGuard()) return;
                            HapticFeedback.lightImpact();
                            await ExerciseMediaCacheManager().clearMediaCache();
                            if (!context.mounted) return;
                            showAppSnackBar(
                              context,
                              message: 'Exercise media cache cleared',
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  _GroupHeader('CLOUD SYNC', color: surface.textSecondary),
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
                                Icon(
                                  Icons.sync_rounded,
                                  size: 20,
                                  color: surface.textSecondary,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'Sync workout data to cloud',
                                            style: AppText.rowLabel(
                                                color: surface.textPrimary),
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
                                            color: surface.textSecondary),
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
                  if (profile?.id != null) ...[
                    Consumer(
                      builder: (context, ref, child) {
                        final qCount = ref
                                .watch(
                                    quarantinedSyncCountProvider(profile!.id))
                                .valueOrNull ??
                            0;
                        if (qCount <= 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.amber.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded,
                                    size: 18, color: Colors.amber),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '$qCount ${qCount == 1 ? "item" : "items"} could not be synchronized and ${qCount == 1 ? "was" : "were"} quarantined.',
                                    style: AppText.meta(
                                        color: surface.textPrimary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 22),
                  _GroupHeader('HELP', color: surface.textSecondary),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        AppActionRow(
                          icon: Icons.help_outline_rounded,
                          title: 'Help & feedback',
                          subtitle: 'Report a problem & support portal',
                          onTap: () {
                            if (!tapGuard()) return;
                            HapticFeedback.selectionClick();
                            context.push('/settings/help');
                          },
                        ),
                        const AppActionDivider(),
                        AppActionRow(
                          icon: Icons.shield_outlined,
                          title: 'Your data',
                          subtitle: isPremium
                              ? 'Stored on-device, backed up to your account'
                              : 'Stored locally on this device',
                          onTap: () => _showDataInfo(context, isPremium),
                        ),
                        const AppActionDivider(),
                        AppActionRow(
                          icon: Icons.privacy_tip_outlined,
                          title: 'Privacy Policy',
                          subtitle: 'Local-first. No tracking.',
                          onTap: () =>
                              _openExternalUrl(context, kPrivacyPolicyUrl),
                        ),
                        const AppActionDivider(),
                        AppActionRow(
                          icon: Icons.gavel_rounded,
                          title: 'Terms of Service',
                          subtitle: 'The short, readable kind',
                          onTap: () =>
                              _openExternalUrl(context, kTermsOfServiceUrl),
                        ),
                        const AppActionDivider(),
                        AppActionRow(
                          icon: Icons.tour_outlined,
                          title: 'Replay app tour',
                          subtitle: 'Walk through the basics again',
                          onTap: () {
                            if (!tapGuard()) return;
                            HapticFeedback.lightImpact();
                            ref.read(firstRunTourProvider.notifier).reset();
                            context.go('/');
                          },
                        ),
                        const AppActionDivider(),
                        AppActionRow(
                          icon: Icons.info_outline_rounded,
                          title: 'Version',
                          subtitle: 'GymLog $version',
                          showChevron: false,
                          onTap: () {
                            if (!tapGuard()) return;
                            HapticFeedback.lightImpact();
                            // Sentry smoke test: five taps throw on purpose.
                            // DEBUG ONLY. Shipped unguarded, this handed a
                            // real uncaught StateError to any user curious
                            // enough to tap the version number five times.
                            if (!kDebugMode) return;
                            setState(() {
                              _devTapCount++;
                              if (_devTapCount >= 5) {
                                _devTapCount = 0;
                                throw StateError(
                                    'Sentry Diagnostic Controlled Test Error');
                              }
                            });
                          },
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

              // Step 3 — Rest-timer spotlight (framing C-b: Settings row).
              // Guard: only show when Settings is the active top route.
              if (ref.watch(firstRunTourProvider) == 3 &&
                  (ModalRoute.of(context)?.isCurrent ?? false))
                SpotlightTourOverlay(
                  targetKey: _restTimerRowKey,
                  title: 'Automatic rest timer',
                  description:
                      'GymLog starts a countdown after every completed set. '
                      'Drag to set your preferred rest here — 1:30 is great '
                      'for compound lifts, 1:00 for isolation work.',
                  step: 3,
                ),
            ],
          ),
        )),
      ),
    );
  }
}

const kAppVersionFallback = '1.0.0';

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

/// The unsynced-work sign-out choice.
///
/// This was the last stock [AlertDialog] on a destructive path: untokenised
/// Material chrome on an AMOLED-black app, three equal-weight text buttons in
/// a row where the only safe option looked identical to the two that end the
/// session, and no statement of what each choice costs the user's unsynced
/// data.
///
/// Now a branded sheet with stacked rows. The safe option is first and
/// labelled as recommended; every option says what actually happens. A
/// drag-dismiss returns null, which the caller already treats as "stay signed
/// in" — the safe default is also the accidental one.
Future<SignOutStrategy?> _showUnsyncedWorkSheet(BuildContext context) {
  HapticFeedback.mediumImpact();
  final accent = context.accent;

  void choose(SignOutStrategy strategy) {
    HapticFeedback.selectionClick();
    Navigator.of(context, rootNavigator: true).pop(strategy);
  }

  return showBrandedBottomSheet<SignOutStrategy>(
    context: context,
    title: 'Unsynced workouts',
    subtitle: 'Some workouts on this device have not reached the cloud yet. '
        'Signing out now would leave them only on this phone.',
    child: AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          AppActionRow(
            icon: Icons.shield_outlined,
            iconColor: accent.light,
            title: 'Stay signed in',
            subtitle: 'Recommended — nothing leaves this device unsynced',
            onTap: () => choose(SignOutStrategy.keepSignedIn),
          ),
          const AppActionDivider(),
          AppActionRow(
            icon: Icons.cloud_upload_outlined,
            iconColor: accent.light,
            title: 'Sync, then sign out',
            subtitle: 'Uploads first. Signs out anyway if the upload fails.',
            onTap: () => choose(SignOutStrategy.signOutAfterSync),
          ),
          const AppActionDivider(),
          AppActionRow(
            icon: Icons.ios_share_rounded,
            iconColor: accent.light,
            title: 'Export a CSV, then sign out',
            subtitle: 'Saves a copy you keep, then ends the session',
            onTap: () => choose(SignOutStrategy.exportAndSignOut),
          ),
        ],
      ),
    ),
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
            final user = ref.read(authProvider);
            if (user == null) return;
            final profile = ref.read(currentUserProfileProvider).valueOrNull;
            final coordinator = ref.read(signOutCoordinatorProvider);
            final prep = await coordinator.prepare(user.id);
            if (prep == SignOutResult.unsyncedWork) {
              if (!context.mounted) return;
              final strategy = await _showUnsyncedWorkSheet(context);
              if (strategy == null ||
                  strategy == SignOutStrategy.keepSignedIn) {
                return;
              }
              if (strategy == SignOutStrategy.exportAndSignOut) {
                if (!context.mounted) return;
                await _exportWorkouts(
                    context, ref, user.id, profile?.displayName ?? '');
              }
              await coordinator.execute(strategy);
            } else {
              if (!context.mounted) return;
              final confirmed = await showAppConfirmDialog(
                context: context,
                title: 'Sign out?',
                message: 'Your workouts are stored locally and will be here '
                    'when you sign back in.',
                confirmLabel: 'Sign Out',
                isDestructive: true,
              );
              if (confirmed) {
                await coordinator.execute(SignOutStrategy.forceSignOut);
              }
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

Future<void> _pickWeightUnit(
    BuildContext context, WidgetRef ref, String unit) async {
  HapticFeedback.lightImpact();
  final selected = await showBrandedPickerSheet<String>(
    context: context,
    title: 'Weight Unit',
    selected: unit,
    options: [
      PickerOption(
        value: 'kg',
        label: 'Kilograms',
        subtitle: 'kg',
        icon: Icons.fitness_center_rounded,
        color: context.surface.textSecondary,
      ),
      PickerOption(
        value: 'lbs',
        label: 'Pounds',
        subtitle: 'lbs',
        icon: Icons.fitness_center_rounded,
        color: context.surface.textSecondary,
      ),
    ],
  );
  if (selected != null) {
    await ref.read(settingsActionsProvider).setWeightUnit(selected);
  }
}

/// Rest duration — a continuous slider, replacing a 7-item preset list.
///
/// The list could not express 45s, 75s, or anything above 3:00, and it labelled
/// values in raw seconds ("120 seconds") when lifters read rest as m:ss. See
/// [DurationSlider] for the interaction rationale.
///
/// Persistence happens in `onChangeEnd` only. A single drag emits dozens of
/// intermediate values; writing each one would hammer SharedPreferences and
/// invalidate the provider on every frame of the gesture.
Future<void> _pickRestTimer(
    BuildContext context, WidgetRef ref, int restSeconds) async {
  HapticFeedback.lightImpact();
  var value = restSeconds.clamp(0, kRestMaxSeconds);

  await showBrandedBottomSheet<void>(
    context: context,
    title: 'Rest Between Sets',
    subtitle: 'Drag to set the countdown that starts after each completed set. '
        'Slide to zero to turn it off.',
    child: StatefulBuilder(
      builder: (context, setSheetState) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: DurationSlider(
          valueSeconds: value,
          maxSeconds: kRestMaxSeconds,
          stepSeconds: 5,
          onChanged: (v) => setSheetState(() => value = v),
          onChangeEnd: (v) =>
              ref.read(settingsActionsProvider).setDefaultRestSeconds(v),
        ),
      ),
    ),
  );

  // Safety net: if the sheet is dismissed by a back gesture between the last
  // detent and the drag-end callback, the final value would otherwise be lost.
  if (value != restSeconds) {
    await ref.read(settingsActionsProvider).setDefaultRestSeconds(value);
  }
}

void _openPremium(BuildContext context, {required bool isPremium}) {
  if (!tapGuard()) return;
  if (isPremium) {
    HapticFeedback.lightImpact();
    showAppSnackBar(
      context,
      message: 'You are on GymLog Pro. Thanks for the support!',
    );
  } else {
    showPremiumPaywall(context);
  }
}

Future<void> _exportWorkouts(BuildContext context, WidgetRef ref, String userId,
    String displayName) async {
  HapticFeedback.lightImpact();
  try {
    final service = WorkoutExportService(ref.read(databaseProvider));
    final file = await service.writeCsvFile(userId);
    final who = displayName.trim().isEmpty ? '' : ' (${displayName.trim()})';
    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path, mimeType: 'text/csv')],
      subject: 'GymLog workout export$who',
      text: 'GymLog training history$who',
    ));
  } catch (_) {
    if (!context.mounted) return;
    showAppSnackBar(context, message: 'Export failed. Please try again.');
  }
}

void _showDataInfo(BuildContext context, bool isPremium) {
  HapticFeedback.lightImpact();
  showAppConfirmDialog(
    context: context,
    title: isPremium ? 'Local-first, cloud-backed' : 'Local-first privacy',
    message: isPremium
        ? 'Every workout is saved instantly to a private database '
            'on this device — GymLog works fully offline. Workouts are '
            'automatically backed up to your account so your history survives '
            'a reinstall or a new phone. Only you can read it.'
        : 'Every workout is saved instantly to a private database '
            'on this device — GymLog works fully offline. Upgrade to '
            'GymLog Pro to automatically back up your history to the cloud '
            'and sync across devices.',
    confirmLabel: 'Got it',
    cancelLabel: 'Close',
  );
}

/// launchUrl THROWS a PlatformException when the platform has no handler for
/// the scheme - it does not merely return false. The original code inspected
/// only the bool, so on a device with no browser the Privacy Policy and Terms
/// rows raised an uncaught async exception and told the user nothing at all.
Future<void> _openExternalUrl(BuildContext context, String url) async {
  HapticFeedback.lightImpact();
  var opened = false;
  try {
    opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
  } catch (_) {
    opened = false;
  }
  if (opened || !context.mounted) return;
  showAppSnackBar(context, message: "Couldn't open the link.");
}
