import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_text.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/config/legal_links.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

const String _googleIconSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
  <path fill="#EA4335" d="M20.33 3.34c-2.16-2-4.99-2.84-8.33-2.84-4.67 0-8.7 2.68-10.67 6.58l4.12 3.19c.97-2.92 3.7-5.23 6.55-5.23 1.83 0 3.48.63 4.77 1.86l3.56-3.56z"/>
  <path fill="#4285F4" d="M23.45 11.3c0-.83-.07-1.63-.2-2.41h-11.25v4.62h6.43c-.28 1.46-1.1 2.7-2.34 3.53l3.95 3.07c2.31-2.13 3.41-5.28 3.41-8.81z"/>
  <path fill="#34A853" d="M12 18.96c-2.85 0-5.58-2.31-6.55-5.23L1.33 16.92C3.3 20.82 7.33 23.5 12 23.5c3.23 0 6.13-1.07 8.21-2.93l-3.95-3.07c-1.13.76-2.6 1.46-4.26 1.46z"/>
  <path fill="#FBBC05" d="M5.45 13.73c-.25-.76-.4-1.57-.4-2.43s.15-1.67.4-2.43L1.33 5.68C.48 7.38 0 9.27 0 11.3s.48 3.92 1.33 5.62l4.12-3.19z"/>
</svg>
''';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isSigningIn = false;

  Future<void> _signIn() async {
    if (_isSigningIn) return;
    setState(() => _isSigningIn = true);
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
    } catch (e, s) {
      debugPrint("Error signing in with Google: $e\n$s");
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
            Text(message, style: AppText.body(color: AppColors.textPrimary)),
        backgroundColor: AppColors.bgSurface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final ok =
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && mounted) _snack("Couldn't open the link.");
  }

  @override
  Widget build(BuildContext context) {
    final fine = AppText.caption(color: AppColors.textSecondary).copyWith(
      height: 1.4,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.bgBase,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 48),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'GymLog',
                          style: AppText.screenTitle(
                            color: AppColors.textPrimary,
                          ).copyWith(
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your gym. Your data.',
                          style: AppText.body(
                            color: AppColors.textSecondary,
                          ).copyWith(
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 64),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _signIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1F1F1F),
                              elevation: 0,
                              shape: const StadiumBorder(),
                            ),
                            child: _isSigningIn
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Color(0xFF1F1F1F)),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SvgPicture.string(
                                        _googleIconSvg,
                                        width: 20,
                                        height: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Continue with Google',
                                        style: AppText.button(),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Semantics(
                          button: true,
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text('By continuing, you agree to our ',
                                  style: fine),
                              _LegalLink(
                                label: 'Terms of Service',
                                onTap: () => _openUrl(kTermsOfServiceUrl),
                              ),
                              Text(' and ', style: fine),
                              _LegalLink(
                                label: 'Privacy Policy',
                                onTap: () => _openUrl(kPrivacyPolicyUrl),
                              ),
                              Text('.', style: fine),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Free to use. Sign in with Google to sync across your devices.',
                          style: fine,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
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
          style: AppText.caption(
            color: AppColors.textSecondary,
          ).copyWith(
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
            decorationColor: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
