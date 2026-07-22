import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/config/legal_links.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/dynamic_accent_theme.dart';
import '../../../../shared/widgets/motion/pressable_scale.dart';
import '../../data/auth_repository.dart';
import '../providers/auth_provider.dart';

const String _googleIconSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
  <path fill="#EA4335" d="M20.33 3.34c-2.16-2-4.99-2.84-8.33-2.84-4.67 0-8.7 2.68-10.67 6.58l4.12 3.19c.97-2.92 3.7-5.23 6.55-5.23 1.83 0 3.48.63 4.77 1.86l3.56-3.56z"/>
  <path fill="#4285F4" d="M23.45 11.3c0-.83-.07-1.63-.2-2.41h-11.25v4.62h6.43c-.28 1.46-1.1 2.7-2.34 3.53l3.95 3.07c2.31-2.13 3.41-5.28 3.41-8.81z"/>
  <path fill="#34A853" d="M12 18.96c-2.85 0-5.58-2.31-6.55-5.23L1.33 16.92C3.3 20.82 7.33 23.5 12 23.5c3.23 0 6.13-1.07 8.21-2.93l-3.95-3.07c-1.13.76-2.6 1.46-4.26 1.46z"/>
  <path fill="#FBBC05" d="M5.45 13.73c-.25-.76-.4-1.57-.4-2.43s.15-1.67.4-2.43L1.33 5.68C.48 7.38 0 9.27 0 11.3s.48 3.92 1.33 5.62l4.12-3.19z"/>
</svg>
''';

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

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool _isSigningIn = false;
  late final AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _entranceController.value = 1.0;
    } else {
      if (!_entranceController.isAnimating &&
          _entranceController.value == 0.0) {
        _entranceController.forward();
      }
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_isSigningIn) return;
    HapticFeedback.lightImpact();
    setState(() => _isSigningIn = true);

    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
    } catch (e) {
      if (e is AuthCancelled) {
        return;
      }

      String message = "Couldn’t sign in. Please try again.";
      String failure = 'unknown';
      String? code;

      if (e is AuthNetworkFailure) {
        message = 'You’re offline. Check your connection and try again.';
        failure = 'network';
      } else if (e is AuthConfigurationFailure) {
        message =
            'Google sign-in isn’t available in this build. Please update the app or contact support.';
        failure = 'configuration';
        code = e.diagnosticCode;
      } else if (e is AuthProviderFailure) {
        message =
            'Google sign-in is temporarily unavailable. Try again in a moment.';
        failure = 'provider';
      }

      // Sanitized debug output
      debugPrint('[Auth] failure=$failure${code != null ? " code=$code" : ""}');

      if (!mounted) return;
      _snack(message);
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
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) _snack("Couldn't open the link.");
      }
    } catch (_) {
      if (mounted) _snack("Couldn't open the link.");
    }
  }

  Widget _entrance({
    required Widget child,
    double start = 0,
  }) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);

    if (reducedMotion) {
      return child;
    }

    final animation = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(
        start,
        1.0,
        curve: Curves.easeOutCubic,
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, 8 * (1 - animation.value)),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    final accent = context.accent;

    final overlay = (surface.isLight
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light)
        .copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: surface.bgBase,
      systemNavigationBarIconBrightness:
          surface.isLight ? Brightness.dark : Brightness.light,
    );

    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final double topPadding = textScale >= 1.6 ? 12 : 24;

    final secondaryColor =
        surface.isLight ? const Color(0xFF555555) : surface.textSecondary;

    final brandBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: topPadding),
        ExcludeSemantics(
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              color: surface.surface3,
              border: Border.all(
                color: accent.selectionBorder,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.glow.withValues(alpha: 0.12),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.fitness_center_rounded,
                color: accent.base,
                size: 27,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Semantics(
          header: true,
          child: Text(
            'GymLog',
            style: AppText.screenTitle(color: surface.textPrimary).copyWith(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Semantics(
          child: Text(
            'Track every workout.\nKeep your history.',
            style: AppText.screenTitle(color: surface.textPrimary).copyWith(
              fontSize: 27,
              fontWeight: FontWeight.w700,
              height: 1.12,
              letterSpacing: -0.3,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Semantics(
          child: Text(
            'A fast workout log with local storage and signed-in sync across your devices.',
            style: AppText.body(color: secondaryColor).copyWith(
              fontSize: 15,
              height: 1.45,
            ),
          ),
        ),
      ],
    );

    final trustBlock = Semantics(
      child: Row(
        children: [
          Icon(
            Icons.shield_outlined,
            size: 16,
            color: secondaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Google is used for secure sign-in and account sync.',
              style: AppText.caption(color: secondaryColor).copyWith(
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );

    final signInButton = Semantics(
      button: true,
      enabled: !_isSigningIn,
      label: _isSigningIn ? 'Signing in with Google' : 'Continue with Google',
      value: _isSigningIn ? 'In progress' : null,
      child: PressableScale(
        enabled: !_isSigningIn,
        pressedScale: 0.985,
        child: ElevatedButton(
          onPressed: _isSigningIn ? null : _signIn,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF111111),
            disabledBackgroundColor: Colors.white.withValues(alpha: 0.92),
            disabledForegroundColor:
                const Color(0xFF111111).withValues(alpha: 0.72),
            elevation: 0,
            minimumSize: const Size.fromHeight(56),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            side: surface.isLight
                ? BorderSide(color: surface.borderDefault, width: 1.0)
                : BorderSide.none,
          ),
          child: _isSigningIn
              ? Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  children: [
                    const ExcludeSemantics(
                      child: SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF111111),
                        ),
                      ),
                    ),
                    Text(
                      'Signing in…',
                      style: AppText.button(
                        color: const Color(0xFF111111).withValues(alpha: 0.72),
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                )
              : Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  children: [
                    _googleIcon,
                    Text(
                      'Continue with Google',
                      style: AppText.button(
                        color: const Color(0xFF111111),
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
        ),
      ),
    );

    final legalBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          child: Text(
            'By continuing, you agree to:',
            style: AppText.caption(color: secondaryColor).copyWith(
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 12,
          runSpacing: 0,
          children: [
            _LegalLink(
              label: 'Terms of Service',
              onPressed: () => _openUrl(kTermsOfServiceUrl),
            ),
            _LegalLink(
              label: 'Privacy Policy',
              onPressed: () => _openUrl(kPrivacyPolicyUrl),
            ),
          ],
        ),
      ],
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: Scaffold(
        backgroundColor: surface.bgBase,
        body: Stack(
          children: [
            const Positioned.fill(
              child: _AuthAtmosphere(),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 520,
                  ),
                  child: CustomScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                        sliver: SliverFillRemaining(
                          hasScrollBody: false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _entrance(child: brandBlock, start: 0.0),
                              const SizedBox(height: 24),
                              const Spacer(),
                              _entrance(child: trustBlock, start: 0.1),
                              const SizedBox(height: 24),
                              _entrance(child: signInButton, start: 0.2),
                              const SizedBox(height: 18),
                              _entrance(child: legalBlock, start: 0.28),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthAtmosphere extends StatelessWidget {
  const _AuthAtmosphere();

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    final accent = context.accent;

    return IgnorePointer(
      child: RepaintBoundary(
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: surface.bgBase),
            Align(
              alignment: const Alignment(0, -0.72),
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      accent.glow.withValues(alpha: 0.65),
                      Colors.transparent,
                    ],
                    stops: const [0, 1],
                  ),
                ),
              ),
            ),
            Align(
              alignment: const Alignment(-0.9, 0.95),
              child: Container(
                width: 320,
                height: 220,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      accent.muted.withValues(alpha: 0.45),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalLink extends StatelessWidget {
  const _LegalLink({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;

    return Semantics(
      link: true,
      label: label,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onPressed,
          behavior: HitTestBehavior.opaque,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(
              horizontal: 2,
              vertical: 8,
            ),
            child: Text(
              label,
              style: AppText.caption().copyWith(
                fontSize: 13,
                color: surface.textSecondary,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: surface.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
