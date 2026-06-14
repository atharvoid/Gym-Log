import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/config/legal_links.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/ui/primary_button.dart';
import '../providers/auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isSigningIn = false;

  Future<void> _signIn() async {
    // Local guard so the button can't re-enter while awaiting; the repository
    // also coalesces concurrent calls as a second line of defence against the
    // google_sign_in "Concurrent operations detected" crash.
    if (_isSigningIn) return;
    setState(() => _isSigningIn = true);
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      // On success the auth-state stream drives the router redirect to Home;
      // this screen is disposed, so no explicit navigation is needed here.
    } catch (_) {
      if (!mounted) return;
      _snack("Couldn't sign in. Please try again.");
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(message, style: GoogleFonts.inter(color: AppColors.textPrimary)),
        backgroundColor: AppColors.bgSurface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final ok = await launchUrl(Uri.parse(url),
        mode: LaunchMode.externalApplication);
    if (!ok && mounted) _snack("Couldn't open the link.");
  }

  @override
  Widget build(BuildContext context) {
    final fine = GoogleFonts.inter(
      color: AppColors.textSecondary,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.4,
    );

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Text(
                'GymLog',
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your gym. Your data.',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: _isSigningIn ? 'Signing in…' : 'Continue with Google',
                isLoading: _isSigningIn,
                onPressed: _signIn,
                leading: Image.asset(
                  'assets/images/google_g.png',
                  width: 24,
                  height: 24,
                ),
              ),
              const SizedBox(height: 14),
              // Apple App Store (3.1.2 / 5.1.1) and Google Play require Terms &
              // Privacy to be reachable BEFORE a data-collecting sign-in. This
              // consent line ties the policies to the act of continuing.
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('By continuing you agree to our ', style: fine),
                  _LegalLink(
                      label: 'Terms',
                      onTap: () => _openUrl(kTermsOfServiceUrl)),
                  Text(' and ', style: fine),
                  _LegalLink(
                      label: 'Privacy Policy',
                      onTap: () => _openUrl(kPrivacyPolicyUrl)),
                  Text('.', style: fine),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Free to use. Sign in with Google to sync across your devices.',
                style: fine,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
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
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: AppColors.accentText, // ~5.9:1 on black, passes AA
            fontSize: 12,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
            decorationColor: AppColors.accentText,
          ),
        ),
      ),
    );
  }
}
