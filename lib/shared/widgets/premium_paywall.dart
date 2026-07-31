import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gymlog/core/providers/premium_provider.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/shared/widgets/ui/app_dialog.dart';

/// Shared "couldn't open this link" feedback. Matches the snackbar pattern
/// used by auth_screen.dart / settings_screen.dart, rather than the bare
/// ScaffoldMessenger call (or a raw AlertDialog) other call sites used to
/// show.
void _openUrl(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  bool ok = false;
  if (uri != null) {
    ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
  if (!ok && context.mounted) {
    final surface = context.surface;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Couldn't open the link.",
            style: AppText.body(color: surface.textPrimary)),
        backgroundColor: surface.surface2,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

Future<void> showPremiumPaywall(BuildContext context) async {
  HapticFeedback.lightImpact();
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _PremiumPaywallSheet(),
  );
}

class _PremiumPaywallSheet extends ConsumerStatefulWidget {
  const _PremiumPaywallSheet();

  @override
  ConsumerState<_PremiumPaywallSheet> createState() =>
      _PremiumPaywallSheetState();
}

class _PremiumPaywallSheetState extends ConsumerState<_PremiumPaywallSheet> {
  bool _busy = false;
  Package? _selected;

  Future<void> _purchase(Package package) async {
    if (_busy) return;
    setState(() => _busy = true);
    HapticFeedback.mediumImpact();
    try {
      await Purchases.purchasePackage(package);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        final surface = context.surface;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Purchase could not be completed.',
              style: AppText.body(color: surface.textPrimary)),
          backgroundColor: surface.surface2,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _restore() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final info = await Purchases.restorePurchases();
      if (!mounted) return;
      final isPremium = info.entitlements.active.isNotEmpty;
      setState(() => _busy = false);
      final surface = context.surface;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            isPremium ? 'Purchases restored.' : 'No purchases to restore.',
            style: AppText.body(color: surface.textPrimary)),
        backgroundColor: surface.surface2,
        behavior: SnackBarBehavior.floating,
      ));
      if (isPremium) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final offeringsAsync = ref.watch(offeringsProvider);
    final surface = context.surface;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: surface.surface2,
          borderRadius: AppRadius.sheetTop,
        ),
        child: SafeArea(
          top: false,
          child: offeringsAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(
              child: Text('Could not load plans.',
                  style: AppText.body(color: surface.textPrimary)),
            ),
            data: (offering) {
              final packages = offering?.availablePackages ?? [];
              _selected ??= packages.isNotEmpty ? packages.first : null;
              return ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: surface.borderEmphasis,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('GymLog Pro',
                      style: AppText.pageTitle(color: surface.textPrimary)),
                  const SizedBox(height: 8),
                  Text(
                    'Unlock full analytics history and more.',
                    style: AppText.body(color: surface.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  for (final package in packages)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PackageTile(
                        package: package,
                        selected: _selected == package,
                        onTap: () => setState(() => _selected = package),
                      ),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: (_busy || _selected == null)
                          ? null
                          : () => _purchase(_selected!),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.accent.base,
                        foregroundColor: context.accent.onAccent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppRadius.buttonPrimary)),
                      ),
                      child: _busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text('Continue', style: AppText.button()),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: _busy ? null : _restore,
                      child: Text('Restore Purchases',
                          style: AppText.statLabel(
                              color: surface.textSecondary)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => _openUrl(context,
                              'https://gymlog.app/terms'),
                          child: Text('Terms',
                              style: AppText.caption(
                                  color: surface.textTertiary)),
                        ),
                        TextButton(
                          onPressed: () => _openUrl(context,
                              'https://gymlog.app/privacy'),
                          child: Text('Privacy',
                              style: AppText.caption(
                                  color: surface.textTertiary)),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PackageTile extends StatelessWidget {
  final Package package;
  final bool selected;
  final VoidCallback onTap;

  const _PackageTile({
    required this.package,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    final accent = context.accent;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: surface.surface3,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: selected ? accent.base : surface.borderSubtle,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? accent.base : surface.textTertiary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  package.storeProduct.title,
                  style: AppText.body(color: surface.textPrimary),
                ),
              ),
              Text(
                package.storeProduct.priceString,
                style: AppText.button(color: surface.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
