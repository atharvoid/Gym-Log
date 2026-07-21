import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart'
    show IntroductoryPrice, Offerings, Package, PackageType, PeriodUnit;

import '../../core/providers/premium_provider.dart';
import '../../core/services/premium_service.dart';
import '../../core/theme/app_colors.dart' show SurfaceContextX;
import '../../core/theme/app_text.dart';
import '../../core/theme/dynamic_accent_theme.dart';

enum PaywallSource { generic, routineLimit, chartFilter, timeRange, sync }

/// Opens the Premium paywall as a modal bottom sheet.
/// Safe to call when RevenueCat is unconfigured — it renders a graceful
/// "pricing unavailable" state instead of crashing.
Future<void> showPremiumPaywall(BuildContext context,
    {PaywallSource source = PaywallSource.generic}) {
  HapticFeedback.lightImpact();
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PaywallSheet(source: source),
  );
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          // Slightly more visible than textSecondary — machined feel.
          color: context.surface.borderEmphasis,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}

/// PRO wordmark badge — a compact pill with "PRO" in the accent color on a
/// tinted accent surface. Replaces the generic star icon that every tutorial
/// paywall uses. The wordmark reads as a brand, not a decorative emoji.
class _PaywallIcon extends StatelessWidget {
  const _PaywallIcon();

  @override
  Widget build(BuildContext context) {
    final accent = context.accent;
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent.base.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.buttonPrimary),
        border: Border.all(
          color: accent.base.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        'PRO',
        style: AppText.cardTitle(color: accent.base)
            .copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.2),
      ),
    );
  }
}

/// Small "PRO" lock pill used next to gated features.
/// Subtle by design — a hint, not a banner. Tapping opens the paywall.
class ProLockPill extends StatelessWidget {
  final String label;

  const ProLockPill({super.key, this.label = 'PRO'});

  @override
  Widget build(BuildContext context) {
    final accent = context.accent;
    return Semantics(
      button: true,
      label: 'Premium feature. Double tap to learn more.',
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.badgeAll,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => showPremiumPaywall(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: accent.muted,
              borderRadius: AppRadius.badgeAll,
              border: Border.all(
                color: accent.base.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            // No padlock — it communicates "you can't have this" while the user
            // looks at their own data. Just the label; tap opens the paywall.
            child: Text(label, style: AppText.badge(color: accent.base)),
          ),
        ),
      ),
    );
  }
}

class _PaywallSheet extends ConsumerStatefulWidget {
  final PaywallSource source;

  const _PaywallSheet({this.source = PaywallSource.generic});

  @override
  ConsumerState<_PaywallSheet> createState() => _PaywallSheetState();
}

class _PaywallSheetState extends ConsumerState<_PaywallSheet> {
  Offerings? _offerings;
  bool _loading = true;
  bool _purchasing = false;
  bool _restoring = false;
  bool _trialEligible = false;
  Package? _selected;

  // HONESTY RULE: this list may only name things that exist in the app
  // today. Advertising unbuilt features in a paid subscription is a
  // Play/App Store rejection risk and a user-trust killer. Accent palettes
  // are FREE personalization and deliberately not sold here.
  //
  // Icons are FILLED (not outline). Outline icons are the #1 signature of
  // "I didn't hire a designer." Filled icons read as intentional.
  static const _features = [
    (
      Icons.fitness_center, // filled
      'Unlimited routines',
      'No more $kFreeRoutineLimit-routine cap',
    ),
    (
      Icons.sync_rounded, // filled
      'Sync across devices',
      'Your data, on any device',
    ),
    (
      Icons.insights, // filled
      'Full analytics history',
      'Every chart, all of it',
    ),
    (
      Icons.calendar_month, // filled
      'All time ranges',
      '1Y and All Time unlocked',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    if (mounted) setState(() => _loading = true);
    final offerings = await ref.read(premiumServiceProvider).offerings();
    if (!mounted) return;
    setState(() {
      _offerings = offerings;
      _loading = false;
      _selected = _annual ?? _monthly;
    });
    await _refreshTrialEligibility();
  }

  Package? get _monthly => _offerings?.current?.availablePackages
      .where((p) => p.packageType == PackageType.monthly)
      .firstOrNull;

  Package? get _annual => _offerings?.current?.availablePackages
      .where((p) => p.packageType == PackageType.annual)
      .firstOrNull;

  bool get _storeReady => _monthly != null || _annual != null;

  void _selectPackage(Package pkg) {
    HapticFeedback.selectionClick();
    setState(() => _selected = pkg);
    unawaited(_refreshTrialEligibility());
  }

  Future<void> _refreshTrialEligibility() async {
    final package = _selected;
    final intro = package?.storeProduct.introductoryPrice;
    if (package == null || intro == null || intro.price > 0) {
      if (mounted) setState(() => _trialEligible = false);
      return;
    }
    final eligible = await ref
        .read(premiumServiceProvider)
        .isEligibleForTrial(package.storeProduct.identifier);
    if (mounted) setState(() => _trialEligible = eligible);
  }

  bool get _hasFreeTrial {
    final intro = _selected?.storeProduct.introductoryPrice;
    return intro != null && intro.price == 0 && _trialEligible;
  }

  /// CTA + caption derive from the live offering — never hardcode trial
  /// terms the store may not actually grant.
  String get _ctaLabel => _hasFreeTrial ? 'Start Free Trial' : 'Upgrade to Pro';

  String get _ctaCaption {
    if (!_hasFreeTrial) return 'Cancel anytime.';
    final intro = _selected!.storeProduct.introductoryPrice!;
    return '${_trialLength(intro)} free, cancel anytime.';
  }

  static String _trialLength(IntroductoryPrice intro) {
    final n = intro.periodNumberOfUnits;
    return switch (intro.periodUnit) {
      PeriodUnit.day => n == 1 ? '1 day' : '$n days',
      PeriodUnit.week => '${n * 7} days',
      PeriodUnit.month => n == 1 ? '1 month' : '$n months',
      PeriodUnit.year => n == 1 ? '1 year' : '$n years',
      _ => '$n days',
    };
  }

  double? get _annualSavingsPercent {
    final annual = _annual;
    final monthly = _monthly;
    if (annual == null || monthly == null) return null;
    final monthlyPrice = monthly.storeProduct.price;
    if (monthlyPrice <= 0) return null;
    final annualMonthlyEquivalent = annual.storeProduct.price / 12;
    final savings = 1 - (annualMonthlyEquivalent / monthlyPrice);
    return savings > 0 ? savings * 100 : null;
  }

  String? _perMonthEquivalent(Package annual) {
    final full = annual.storeProduct.priceString;
    final match = RegExp(r'^[^\d-]*').firstMatch(full);
    final prefix = match?.group(0) ?? '';
    final perMonth = annual.storeProduct.price / 12;
    return '$prefix${perMonth.toStringAsFixed(2)}/mo';
  }

  Future<void> _purchase() async {
    final package = _selected;
    if (package == null || _purchasing) return;
    HapticFeedback.mediumImpact();
    setState(() => _purchasing = true);

    try {
      final info =
          await ref.read(premiumServiceProvider).purchasePackage(package);
      if (!mounted) return;
      if (info == null) {
        // User cancelled the purchase
        return;
      }
      if (hasPremium(info)) {
        HapticFeedback.heavyImpact();
        Navigator.of(context).pop();
        _snack('Welcome to GymLog Pro — everything is unlocked.');
      } else {
        HapticFeedback.heavyImpact();
        debugPrint(
          '[PremiumPaywall] Purchase completed for package "${package.identifier}", '
          'but entitlement "${PremiumService.entitlementId}" is not active. '
          'Active entitlements: ${info.entitlements.active.keys.join(", ")}',
        );
        _snack(
          'Purchase completed, but Premium is still being verified. Try Restore Purchases.',
        );
      }
    } catch (e) {
      if (mounted) _snack('Purchase failed. You were not charged.');
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  Future<void> _restore() async {
    if (_restoring) return;
    HapticFeedback.lightImpact();
    setState(() => _restoring = true);
    try {
      final info = await ref.read(premiumServiceProvider).restorePurchases();
      if (!mounted) return;
      if (info != null && hasPremium(info)) {
        HapticFeedback.heavyImpact();
        Navigator.of(context).pop();
        _snack('Pro restored. Welcome back.');
      } else {
        _snack('No active Pro subscription found for this account.');
      }
    } catch (_) {
      if (mounted) _snack('Restore failed. Try again later.');
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  void _snack(String message) {
    final surface = context.surface;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: AppText.body(color: surface.textPrimary)),
      backgroundColor: surface.bgSurface,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.accent;
    final savings = _annualSavingsPercent;
    final String headline;
    final String subheadline;

    switch (widget.source) {
      case PaywallSource.generic:
        headline = 'Unlock Premium';
        subheadline = 'Go deeper on the data behind your training.';
        break;
      case PaywallSource.routineLimit:
        headline = 'Routine limit reached';
        subheadline =
            'The free plan includes up to $kFreeRoutineLimit routines — enough for a Push / Pull / Legs / Full-Body split. Upgrade to Pro for unlimited routines and full analytics history.';
        break;
      case PaywallSource.chartFilter:
        headline = 'Full history locked';
        subheadline =
            'Free plan shows your last 3 weeks. Upgrade to see your full history.';
        break;
      case PaywallSource.timeRange:
        headline = 'Long-term trends';
        subheadline = '1Y and All Time ranges unlocked with Pro.';
        break;
      case PaywallSource.sync:
        headline = 'Sync across devices';
        subheadline =
            'Cloud sync is a Pro feature. Upgrade to back up your data and pick up where you left off on any device.';
        break;
    }

    final surface = context.surface;
    return Container(
      decoration: BoxDecoration(
        color: surface.surface2,
        borderRadius: AppRadius.sheetTop,
        // Hairline border — defines the sheet edge against the black canvas.
        // This is what separates "material" from "grey blob on black."
        border: Border(
          top: BorderSide(color: surface.surface3, width: 1),
          left: BorderSide(color: surface.surface3, width: 1),
          right: BorderSide(color: surface.surface3, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top glow — light leak at sheet edge ──────────────────
              // Premium apps use light to create depth, not shadow.
              // This 1px row emits a faint accent luminance above the handle.
              Container(
                height: 1,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: accent.glow,
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SheetHandle(),
                    const SizedBox(height: 24),

                    // ── Header ──────────────────────────────────────────
                    const _PaywallIcon(),
                    const SizedBox(height: 14),
                    Text(
                      headline,
                      style: AppText.sheetTitle(color: surface.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subheadline,
                      style: AppText.body(color: surface.textSecondary),
                    ),
                    const SizedBox(height: 20),

                    // ── Features ────────────────────────────────────────
                    // Subtitles are sentence case — uppercase reads like a
                    // system alert. Sentence case reads like a human wrote it.
                    for (final (icon, title, subtitle) in _features)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Semantics(
                          label: '$title, $subtitle',
                          child: Row(
                            children: [
                              // Filled icons signal intentional design.
                              // Outline icons look like a default choice.
                              Icon(icon, size: 20, color: accent.base),
                              const SizedBox(width: 14),
                              Expanded(
                                child: ExcludeSemantics(
                                  child: Text(
                                    title,
                                    style: AppText.body(
                                            color: surface.textPrimary)
                                        .copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                              ExcludeSemantics(
                                child: Text(
                                  subtitle, // sentence case — not .toUpperCase()
                                  style: AppText.label(
                                      color: surface.textSecondary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),

                    // ── Pricing ─────────────────────────────────────────
                    if (_loading)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: CircularProgressIndicator(
                              color: surface.textPrimary, strokeWidth: 2),
                        ),
                      )
                    else if (_storeReady) ...[
                      if (_annual != null)
                        _PackageRow(
                          title: 'Yearly',
                          price: _annual!.storeProduct.priceString,
                          caption: _perMonthEquivalent(_annual!) ?? 'per year',
                          badge: savings != null
                              ? 'SAVE ${savings.round()}%'
                              : null,
                          selected: _selected == _annual,
                          onTap: () => _selectPackage(_annual!),
                        ),
                      if (_annual != null && _monthly != null)
                        const SizedBox(height: 10),
                      if (_monthly != null)
                        _PackageRow(
                          title: 'Monthly',
                          price: _monthly!.storeProduct.priceString,
                          caption: 'per month',
                          selected: _selected == _monthly,
                          onTap: () => _selectPackage(_monthly!),
                        ),
                      const SizedBox(height: 18),
                      Material(
                        color: _purchasing
                            ? accent.base.withValues(alpha: 0.85)
                            : accent.base,
                        borderRadius:
                            BorderRadius.circular(AppRadius.buttonPrimary),
                        elevation: 0,
                        child: InkWell(
                          onTap: _purchasing ? null : _purchase,
                          borderRadius:
                              BorderRadius.circular(AppRadius.buttonPrimary),
                          child: Container(
                            height: 52,
                            width: double.infinity,
                            alignment: Alignment.center,
                            child: _purchasing
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: accent.onAccent, strokeWidth: 2),
                                  )
                                : Text(
                                    _ctaLabel,
                                    style: AppText.body(color: accent.onAccent)
                                        .copyWith(fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Text(
                          _ctaCaption,
                          style: AppText.caption(color: surface.textSecondary),
                        ),
                      ),
                    ] else ...[
                      // RevenueCat unreachable — actionable, not apologetic.
                      // A premium app never shows a "broken" UI; it shows a
                      // minimal, tappable state that lets the user retry.
                      const SizedBox(height: 8),
                      Center(
                        child: GestureDetector(
                          onTap: _loadOfferings,
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'Pricing unavailable. Tap to retry.',
                              style:
                                  AppText.caption(color: surface.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 8),

                    // ── Secondary actions ───────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: Text(
                            'Maybe Later',
                            style: AppText.body(color: surface.textSecondary),
                          ),
                        ),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: surface.textSecondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        TextButton(
                          onPressed: _restoring ? null : _restore,
                          style: TextButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: Text(
                            _restoring ? 'Restoring…' : 'Restore Purchases',
                            style: AppText.body(color: surface.textSecondary),
                          ),
                        ),
                      ],
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

class _PackageRow extends StatelessWidget {
  final String title;
  final String price;
  final String caption;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  const _PackageRow({
    required this.title,
    required this.price,
    required this.caption,
    this.badge,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = context.accent;
    final surface = context.surface;
    return Semantics(
      button: true,
      selected: selected,
      label: '$title plan, $price $caption',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          // Unselected cards are transparent — no grey blob pattern.
          // Only the selected card gets a tinted fill.
          color: selected
              ? accent.base.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.buttonSecondary),
          border: Border.all(
            color: selected ? accent.base : surface.borderDefault,
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.buttonSecondary),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    size: 18,
                    color: selected ? accent.base : surface.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: AppText.body(color: surface.textPrimary).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: accent.base.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(AppRadius.badge),
                      ),
                      child: Text(
                        badge!.toUpperCase(),
                        style: AppText.label(
                          color: accent.base,
                          letterSpacing: 12 * 0.05,
                        ).copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        price,
                        style:
                            AppText.value(color: surface.textPrimary).copyWith(
                          fontSize: 17,
                        ),
                      ),
                      Text(
                        caption,
                        style: AppText.caption(color: surface.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
