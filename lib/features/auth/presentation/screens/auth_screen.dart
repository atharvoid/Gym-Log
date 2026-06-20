import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/config/legal_links.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../shared/widgets/ui/primary_button.dart';
import '../providers/auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isSigningIn = false;

  @override
  void dispose() {
    ScaffoldMessenger.of(context).clearSnackBars();
    super.dispose();
  }

  Future<void> _signIn() async {
    // Local guard so the button can't re-enter while awaiting; the repository
    // also coalesces concurrent calls as a second line of defence against the
    // google_sign_in "Concurrent operations detected" crash.
    if (_isSigningIn) return;
    setState(() => _isSigningIn = true);
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      HapticFeedback.lightImpact();
      // On success the auth-state stream drives the router redirect to Home;
      // this screen is disposed, so no explicit navigation is needed here.
    } catch (_) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      _snack("Couldn't sign in. Please try again.");
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppText.body()),
        backgroundColor: AppColors.bgSurface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    try {
      final ok = await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication);
      if (!ok && mounted) _snack("Couldn't open the link.");
    } catch (_) {
      if (mounted) _snack("Couldn't open the link.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.bgBase,
        body: SafeArea(
          child: CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    children: [
                      const Spacer(),
                      Text(
                        'GymLog',
                        style: AppText.display(),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your gym. Your data.',
                        style: AppText.body(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const Spacer(),
                      PrimaryButton(
                        label: _isSigningIn ? 'Signing in…' : 'Continue with Google',
                        isLoading: _isSigningIn,
                        onPressed: _signIn,
                        // COMPLIANCE NOTE: the generic lock glyph (Icons.login) was
                        // removed — pairing a non-Google icon with "Continue with
                        // Google" is off-brand. 
                        icon: Icons.g_mobiledata_rounded,
                      ),
                      const SizedBox(height: 16),
                      // Apple App Store (3.1.2 / 5.1.1) and Google Play require Terms &
                      // Privacy to be reachable BEFORE a data-collecting sign-in.
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text('By continuing you agree to our ', style: AppText.caption()),
                          _LegalLink(
                              label: 'Terms',
                              onTap: () => _openUrl(kTermsOfServiceUrl)),
                          Text(' and ', style: AppText.caption()),
                          _LegalLink(
                              label: 'Privacy Policy',
                              onTap: () => _openUrl(kPrivacyPolicyUrl)),
                          Text('.', style: AppText.caption()),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Free to use. Sign in with Google to sync across your devices.',
                        style: AppText.caption(),
                        textAlign: TextAlign.center,
                      ),
                    ],
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

/// Inline, AA-contrast, screen-reader-labelled legal link.
class _LegalLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _LegalLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      link: true,
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            label,
            style: AppText.caption(color: AppColors.accentText).copyWith(
              decoration: TextDecoration.underline,
              decorationColor: AppColors.accentText,
            ),
          ),
        ),
      ),
    );
  }
}
