import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_text.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/config/legal_links.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/dynamic_accent_theme.dart';
import '../../../../shared/widgets/motion/entrance_fade.dart';
import '../providers/auth_provider.dart';

const String _googleIconSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
  <path fill="#EA4335" d="M20.33 3.34c-2.16-2-4.99-2.84-8.33-2.84-4.67 0-8.7 2.68-10.67 6.58l4.12 3.19c.97-2.92 3.7-5.23 6.55-5.23 1.83 0 3.48.63 4.77 1.86l3.56-3.56z"/>
  <path fill="#4285F4" d="M23.45 11.3c0-.83-.07-1.63-.2-2.41h-11.25v4.62h6.43c-.28 1.46-1.1 2.7-2.34 3.53l3.95 3.07c2.31-2.13 3.41-5.28 3.41-8.81z"/>
  <path fill="#34A853" d="M12 18.96c-2.85 0-5.58-2.31-6.55-5.23L1.33 16.92C3.3 20.82 7.33 23.5 12 23.5c3.23 0 6.13-1.07 8.21-2.93l-3.95-3.07c-1.13.76-2.6 1.46-4.26 1.46z"/>
  <path fill="#FBBC05" d="M5.45 13.73c-.25-.76-.4-1.57-.4-2.43s.15-1.67.4-2.43L1.33 5.68C.48 7.38 0 9.27 0 11.3s.48 3.92 1.33 5.62l4.12-3.19z"/>
</svg>
''';

// Parsed once at module load — avoids re-parsing the SVG XML on every build.
final Widget _googleIcon = SvgPicture.string(
  _googleIconSvg,
  width: 20,
  height: 20,
);

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isSigningIn = false;

  Future<void> _signIn() async {
    if (_isSigningIn) return;
    HapticFeedback.lightImpact();
    setState(() => _isSigningIn = true);
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
    } catch (e, s) {
      debugPrint('[AuthScreen] Sign-in error: $e\n$s');
      if (!mounted) return;
      if (e is SocketException ||
          e.toString().contains('SocketException') ||
          e.toString().contains('NetworkException')) {
        _snack('No connection. Check your internet and try again.');
      } else if (e is AuthException) {
        _snack('Sign-in unavailable. Please try again later.');
      } else {
        _snack("Couldn't sign in. Please try again.");
      }
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  void _snack(String message) {
    final surface = context.surface;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppText.body(color: surface.textPrimary)),
        backgroundColor: surface.surface2,
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
    final surface = context.surface;
    final accent = context.accent;
    final fine = AppText.caption(color: surface.textSecondary).copyWith(
      height: 1.4,
    );

    final overlay = (surface.isLight
            ? SystemUiOverlayStyle.dark // dark icons on a light bg
            : SystemUiOverlayStyle.light) // light icons on AMOLED
        .copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: surface.bgBase,
      systemNavigationBarIconBrightness:
          surface.isLight ? Brightness.dark : Brightness.light,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: Scaffold(
        backgroundColor: surface.bgBase,
        body: EntranceFade(
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── TOP: brand + value prop (anchors content to the top) ──
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: accent.tint,
                                  borderRadius: AppRadius.cardAll,
                                ),
                                child: Icon(
                                  Icons.fitness_center_rounded,
                                  color: accent.base,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 28),
                              Semantics(
                                header: true,
                                child: Text(
                                  'GymLog',
                                  style: AppText.screenTitle(
                                          color: surface.textPrimary)
                                      .copyWith(letterSpacing: -0.5),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Track every rep.\nOwn every byte.',
                                style:
                                    AppText.heroStat(color: surface.textPrimary)
                                        .copyWith(height: 1.05),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'A fast, private workout log — your data stays yours.',
                                style:
                                    AppText.body(color: surface.textSecondary)
                                        .copyWith(fontSize: 16, height: 1.4),
                              ),
                            ],
                          ),
                          // ── BOTTOM: CTA + legal (pinned) ──
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ConstrainedBox(
                                constraints:
                                    const BoxConstraints(minHeight: 52),
                                child: ElevatedButton(
                                  onPressed: _signIn,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF1F1F1F),
                                    elevation: 0,
                                    shape: const StadiumBorder(),
                                    side: surface.isLight
                                        ? BorderSide(
                                            color: surface.borderDefault)
                                        : BorderSide.none,
                                  ),
                                  child: _isSigningIn
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Color(0xFF1F1F1F)),
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            _googleIcon,
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
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
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
    final surface = context.surface;
    return Semantics(
      link: true,
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 2),
          child: Text(
            label,
            style: AppText.caption(
              color: surface.textSecondary,
            ).copyWith(
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationColor: surface.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
