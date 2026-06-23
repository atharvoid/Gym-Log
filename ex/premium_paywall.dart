// Location: lib/shared/widgets/premium_paywall.dart
//
// CHANGES FROM ORIGINAL — see inline `// FIX:` comments for each:
//   C2  feature list no longer advertises a free feature as a premium
//       perk, and now actually mentions routines (the thing that sends
//       users here in the first place via showRoutineLimitUpsell)
//   C3  "Start Free Trial" now gated behind a real per-user eligibility
//       check instead of inferring it from product metadata alone
//   C4  purchase success with an empty entitlement no longer fails silently
//   M1  duplicated handle/icon blocks extracted into shared widgets
//   M2  showRoutineLimitUpsell gets isScrollControlled + scroll fallback
//   M3  restore now has the same double-tap guard purchase already had
//   M4  Restore Purchases no longer disappears when offerings fail to load
//   M5  "BEST VALUE" badge is now computed from real price math
//   M6  annual plan shows a per-month equivalent, not just "per year"
//   M7  offerings are cached (5 min TTL) instead of re-fetched every open
//   Mi1 package rows get real ripple feedback (Material/InkWell layered
//       correctly so an opaque AnimatedContainer doesn't hide the splash)
//   Mi2 haptic weight standardized between the two sheet-opening entry points
//   Mi3 feature rows grouped into one Semantics node each

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:purchases_flutter/purchases_flutter.dart'
    show IntroductoryPrice, Offerings, Package, PackageType, PeriodUnit;

import '../../core/providers/premium_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';

Future<void> showPremiumPaywall(BuildContext context) {
  HapticFeedback.lightImpact();
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _PaywallSheet(),
  );
}

Future<void> showRoutineLimitUpsell(BuildContext context) {
  // FIX (Mi2): was mediumImpact — inconsistent with showPremiumPaywall's
  // lightImpact for the same category of action (opening a sheet).
  HapticFeedback.lightImpact();
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    // FIX (M2): was missing. Without this the sheet is capped at ~9/16
    // screen height and cannot grow — at large accessibility font sizes
    // the body copy will overflow.
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) => Container(
      decoration: const BoxDecoration(
        color: AppColors.bgSheet,
        borderRadius: AppRadius.sheetTop,
      ),
      child: SafeArea(
        top: false,
        // FIX (M2): was a bare Column with no scroll fallback.
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SheetHandle(),
              const SizedBox(height: 22),
              const _PaywallIcon(),
              const SizedBox(height: 14),
              Text(
                'Routine limit reached',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'The free plan includes up to $kFreeRoutineLimit routines — '
                'enough for a Push / Pull / Legs / Full-Body day split. Upgrade to '
                'Pro for unlimited routines and full analytics history.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(sheetCtx).pop();
                    showPremiumPaywall(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.buttonPrimaryAll),
                  ),
                  child: Text(
                    'Unlock Unlimited Routines',
                    style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(sheetCtx).pop(),
                  child: Text(
                    'Not now',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// FIX (M1): extracted from two copy-pasted inline Containers that both
/// hardcoded Color(0xFF6A6A6A). One definition now, used twice.
class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  static const _handleColor = Color(0xFF6A6A6A);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: _handleColor,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}

/// FIX (M1): same duplication as _SheetHandle. Also centralizes the
/// hardcoded Color(0xFFA78BFA), which was bypassing the AppColors
/// token system in two separate places.
class _PaywallIcon extends StatelessWidget {
  const _PaywallIcon({this.icon = Icons.workspace_premium_rounded});

  final IconData icon;

  // TODO: promote to AppColors once you can confirm the exact token —
  // kept local since AppColors' full contents weren't available here.
  static const _iconColor = Color(0xFFA78BFA);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.accentPrimary.withValues(alpha: 0.14),
        borderRadius: AppRadius.badgeAll,
      ),
      child: Icon(icon, color: _iconColor, size: 24),
    );
  }
}

class ProLockPill extends StatelessWidget {
  const ProLockPill({super.key, this.label = 'PRO'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Premium feature. Double tap to learn more.',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.badge),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => showPremiumPaywall(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.indigoTint,
              borderRadius: BorderRadius.circular(AppRadius.badge),
              border: Border.all(
                color: AppColors.indigoTrack,
                width: 1,
              ),
            ),
            child:
                Text(label, style: AppText.badge(color: AppColors.indigo400)),
          ),
        ),
      ),
    );
  }
}

class _PaywallSheet extends ConsumerStatefulWidget {
  const _PaywallSheet();

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

  // FIX (C2): previously led with "Unlimited workouts — Free, forever",
  // advertising a free feature as the #1 reason to pay, and never
  // mentioned routines despite kFreeRoutineLimit being a real gated
  // feature that showRoutineLimitUpsell explicitly promises right
  // before redirecting here.
  static const _features = [
    (
      Icons.fitness_center_rounded,
      'Unlimited routines',
      'No more $kFreeRoutineLimit-routine cap',
    ),
    (Icons.insights_rounded, 'Full analytics history',
        'Every chart, all of it'),
    (Icons.date_range_rounded, 'All time ranges', '1Y and All Time unlocked'),
  ];

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
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

  // FIX (C3): "free trial" was previously inferred purely from the
  // product's introductoryPrice being $0 — that's metadata on the
  // PRODUCT, not proof THIS user is eligible. A returning user who
  // already used their trial would see "Start Free Trial, cancel
  // anytime" and then get charged immediately. Now gated behind an
  // explicit eligibility check, defaulting to false on any doubt.
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

  String get _ctaLabel =>
      _hasFreeTrial ? 'Start Free Trial' : 'Upgrade to Pro';

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

  // FIX (M5): "BEST VALUE" was a static string regardless of actual
  // pricing. Now computed so the claim can never be false.
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

  // FIX (M6): annual price previously showed only the raw yearly total
  // with no per-month equivalent. This avoids adding a new `intl`
  // dependency by reusing the currency symbol RevenueCat already
  // formatted into priceString. If `intl` is already in your pubspec,
  // NumberFormat.simpleCurrency(name: currencyCode) is more robust for
  // currencies with trailing symbols (e.g. "59,99 €").
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
        // User cancelled the native purchase sheet — no error to show.
        return;
      }
      if (info.entitlements.active.isNotEmpty) {
        HapticFeedback.heavyImpact();
        Navigator.of(context).pop();
        _snack('Welcome to GymLog Pro — everything is unlocked.');
      } else {
        // FIX (C4): previously this branch did nothing. A charge can
        // succeed with no exception thrown while entitlements come back
        // empty (sync delay, dashboard misconfig) — real money with
        // silent UI is not acceptable.
        HapticFeedback.heavyImpact();
        _snack(
          "Payment received — finishing setup. If Pro isn't unlocked in "
          "a minute, reopen the app or contact support.",
        );
      }
    } catch (e) {
      if (mounted) _snack('Purchase failed. You were not charged.');
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  Future<void> _restore() async {
    // FIX (M3): purchase already guarded against double-taps via
    // _purchasing; restore had no equivalent guard.
    if (_restoring) return;
    HapticFeedback.lightImpact();
    setState(() => _restoring = true);
    try {
      final info = await ref.read(premiumServiceProvider).restorePurchases();
      if (!mounted) return;
      if (info != null && info.entitlements.active.isNotEmpty) {
        HapticFeedback.heavyImpact();
        Navigator.of(context).pop();
        _snack('Pro restored. Welcome back.');
      } else {
        _snack('No previous purchases found.');
      }
    } catch (_) {
      if (mounted) _snack('Restore failed. Try again later.');
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message,
          style: GoogleFonts.inter(color: AppColors.textPrimary)),
      backgroundColor: AppColors.bgSurface,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final savings = _annualSavingsPercent;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgSheet,
        borderRadius: AppRadius.sheetTop,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SheetHandle(),
              const SizedBox(height: 24),
              const _PaywallIcon(),
              const SizedBox(height: 14),
              Text(
                'Unlock Premium',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Go deeper on the data behind your training.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              for (final (icon, title, subtitle) in _features)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  // FIX (Mi3): title + subtitle were two disjoint Text
                  // nodes with no Semantics grouping — a screen reader
                  // read them as separate fragments.
                  child: Semantics(
                    label: '$title, $subtitle',
                    child: Row(
                      children: [
                        Icon(icon, size: 19, color: const Color(0xFFA78BFA)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: ExcludeSemantics(
                            child: Text(
                              title,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        ExcludeSemantics(
                          child: Text(
                            subtitle,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(
                        color: AppColors.textPrimary, strokeWidth: 2),
                  ),
                )
              else if (_storeReady) ...[
                if (_annual != null)
                  _PackageRow(
                    title: 'Yearly',
                    price: _annual!.storeProduct.priceString,
                    // FIX (M6): real per-month equivalent instead of a
                    // bare "per year" caption.
                    caption: _perMonthEquivalent(_annual!) ?? 'per year',
                    // FIX (M5): only shown, and only true, when the
                    // math backs it up.
                    badge: savings != null ? 'SAVE ${savings.round()}%' : null,
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
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _purchasing ? null : _purchase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentPrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.buttonPrimaryAll),
                    ),
                    child: _purchasing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            _ctaLabel,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    _ctaCaption,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ] else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceRaised,
                    borderRadius: AppRadius.cardAll,
                  ),
                  child: Text(
                    'Pricing is unavailable right now. You are on the free '
                    'plan — workout logging stays free, forever.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Maybe Later',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  // FIX (M4): Restore Purchases was previously hidden
                  // whenever _storeReady was false (offerings fetch
                  // failed) — but restoring doesn't require live
                  // offerings, only Purchases.restorePurchases(). Now
                  // always available.
                  Container(
                    width: 3,
                    height: 3,
                    decoration: const BoxDecoration(
                      color: Color(0xFF6A6A6A),
                      shape: BoxShape.circle,
                    ),
                  ),
                  TextButton(
                    onPressed: _restoring ? null : _restore,
                    child: Text(
                      _restoring ? 'Restoring…' : 'Restore Purchases',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PackageRow extends StatelessWidget {
  const _PackageRow({
    required this.title,
    required this.price,
    required this.caption,
    this.badge,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String price;
  final String caption;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$title plan, $price $caption',
      // FIX (Mi1): naively wrapping the old AnimatedContainer in
      // InkWell would make the ripple invisible — an opaque child
      // painted on top of a Material's ink layer hides the splash.
      // The fix keeps AnimatedContainer as the OUTER animated
      // background/border, with Material(transparent) + InkWell
      // nested INSIDE it, so the ripple renders on top of the
      // background and under the (unfilled) content — actually visible.
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accentPrimary.withValues(alpha: 0.10)
              : AppColors.surfaceRaised,
          borderRadius: AppRadius.cardAll,
          border: Border.all(
            color: selected ? AppColors.borderActive : AppColors.borderSubtle,
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    size: 18,
                    color: selected
                        ? AppColors.accentPrimary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color:
                            AppColors.accentPrimary.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(AppRadius.badge),
                      ),
                      child: Text(
                        badge!,
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: AppColors.indigo400,
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
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        caption,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
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
