import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/config/legal_links.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../shared/widgets/motion/pressable_scale.dart';
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

class _AuthScreenState extends ConsumerState<AuthScreen>
    with TickerProviderStateMixin {
  bool _isSigningIn = false;
  late AnimationController _driftController;
  late AnimationController _ambientController;
  late AnimationController _sheenController;
  late AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _driftController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1750), // 3.5s back-and-forth
    );
    _sheenController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (!MediaQuery.disableAnimationsOf(context)) {
          _entranceController.forward();
        } else {
          _entranceController.value = 1.0;
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    if (disableAnimations) {
      _driftController.stop();
      _ambientController.stop();
      _sheenController.stop();
      _entranceController.value = 1.0;
    } else {
      if (!_driftController.isAnimating) {
        _driftController.repeat();
      }
      if (!_ambientController.isAnimating) {
        _ambientController.repeat(reverse: true);
      }
      if (!_sheenController.isAnimating) {
        _sheenController.repeat();
      }
      if (!_entranceController.isAnimating &&
          _entranceController.value == 0.0) {
        _entranceController.forward();
      }
    }
  }

  @override
  void dispose() {
    _driftController.dispose();
    _ambientController.dispose();
    _sheenController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

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
      } else if (e.toString().contains('10:') ||
          e.toString().contains('DEVELOPER_ERROR')) {
        _snack('Sign-in error (10): Google SHA-1 fingerprint mismatch.');
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

  Widget _buildLogoEntrance(Widget child) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return child;
    }
    final scaleCurve = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.32, curve: Curves.easeOutBack),
    );
    final fadeCurve = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.32, curve: Curves.easeOut),
    );
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        return Opacity(
          opacity: fadeCurve.value,
          child: Transform.scale(
            scale: scaleCurve.value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildStaggeredEntrance(int index, Widget child) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return child;
    }
    final start = (index * 70) / 1000.0;
    final end = (index * 70 + 320) / 1000.0;
    final curve = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start.clamp(0.0, 1.0), end.clamp(0.0, 1.0),
          curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: curve,
      builder: (context, child) {
        final opacity = curve.value;
        final yOffset = (1 - curve.value) * 16.0;
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, yOffset),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildBrandBlock(SurfaceTokens surface, Color voltBase) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    // Ambient breathing pulse for glow box shadow
    final double animValue = disableAnimations ? 0.5 : _ambientController.value;
    final shadowAlpha =
        Tween<double>(begin: 0.08, end: 0.18).transform(animValue);
    final blurRadius =
        Tween<double>(begin: 20.0, end: 32.0).transform(animValue);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // App-tile logo (Centered squircle app tile with Volt glow)
        _buildLogoEntrance(
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  surface.surface3,
                  surface.surface2,
                ],
              ),
              border: Border.all(
                color: voltBase.withValues(alpha: 0.18),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: voltBase.withValues(alpha: shadowAlpha),
                  blurRadius: blurRadius,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.fitness_center_rounded,
                color: Color(0xFFC8FF00),
                size: 34,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Wordmark "GymLog" (Centered with shimmer sweep)
        _buildStaggeredEntrance(
          1,
          disableAnimations
              ? Text(
                  'GymLog',
                  textAlign: TextAlign.center,
                  style:
                      AppText.screenTitle(color: surface.textPrimary).copyWith(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                )
              : AnimatedBuilder(
                  animation: _sheenController,
                  builder: (context, child) {
                    final t = _sheenController.value;
                    double sweep;
                    if (t <= 0.3) {
                      sweep = t / 0.3; // 0.0 to 1.0
                    } else {
                      sweep = 1.0;
                    }

                    final alignBegin = Alignment(-2.0 + sweep * 4.0, -1.0);
                    final alignEnd = Alignment(-1.0 + sweep * 4.0, 1.0);

                    return ShaderMask(
                      shaderCallback: (bounds) {
                        return LinearGradient(
                          begin: alignBegin,
                          end: alignEnd,
                          colors: [
                            surface.textPrimary,
                            voltBase.withValues(alpha: 0.35),
                            surface.textPrimary,
                          ],
                          stops: const [0.35, 0.5, 0.65],
                        ).createShader(bounds);
                      },
                      child: child,
                    );
                  },
                  child: Text(
                    'GymLog',
                    textAlign: TextAlign.center,
                    style: AppText.screenTitle(color: Colors.white).copyWith(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 14),

        // Tagline "Track every rep. Own every byte."
        _buildStaggeredEntrance(
          2,
          Text(
            'Track every rep. Own every byte.',
            textAlign: TextAlign.center,
            style: AppText.body(color: surface.textPrimary).copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Supporting line
        _buildStaggeredEntrance(
          3,
          Text(
            'A fast, private workout log. Your data stays yours.',
            textAlign: TextAlign.center,
            maxLines: 2,
            style: AppText.caption(color: surface.textSecondary).copyWith(
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionBlock(
      SurfaceTokens surface, Color voltBase, bool disableAnimations) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Google CTA button
        _buildStaggeredEntrance(
          4,
          PressableScale(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  ElevatedButton(
                    onPressed: _signIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF111111),
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
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF111111),
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _googleIcon,
                              const SizedBox(width: 12),
                              Text(
                                'Continue with Google',
                                style: AppText.button(
                                  color: const Color(0xFF111111),
                                ).copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                  ),

                  // Diagonal sweep CTA shine
                  if (!disableAnimations)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedBuilder(
                          animation: _sheenController,
                          builder: (context, child) {
                            final t = _sheenController.value;
                            double sweepProgress;
                            if (t >= 0.5 && t <= 0.7) {
                              sweepProgress = (t - 0.5) / 0.2; // 0.0 to 1.0
                            } else {
                              return const SizedBox.shrink();
                            }

                            return FractionallySizedBox(
                              widthFactor: 2.0,
                              heightFactor: 1.0,
                              alignment:
                                  Alignment(-2.0 + sweepProgress * 4.0, 0.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: const Alignment(-1, -1),
                                    end: const Alignment(1, 1),
                                    colors: [
                                      Colors.transparent,
                                      voltBase.withValues(alpha: 0.15),
                                      Colors.white.withValues(alpha: 0.25),
                                      voltBase.withValues(alpha: 0.15),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.35, 0.48, 0.5, 0.52, 0.65],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Legal Wrap with compact vertical padding
        _buildStaggeredEntrance(
          5,
          Semantics(
            button: true,
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'By continuing, you agree to our ',
                  style: AppText.caption(color: surface.textSecondary).copyWith(
                    fontSize: 12.5,
                  ),
                ),
                _LegalLink(
                  label: 'Terms of Service',
                  onTap: () => _openUrl(kTermsOfServiceUrl),
                ),
                Text(
                  ' and ',
                  style: AppText.caption(color: surface.textSecondary).copyWith(
                    fontSize: 12.5,
                  ),
                ),
                _LegalLink(
                  label: 'Privacy Policy',
                  onTap: () => _openUrl(kPrivacyPolicyUrl),
                ),
                Text(
                  '.',
                  style: AppText.caption(color: surface.textSecondary).copyWith(
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    const voltBase = Color(0xFFC8FF00);
    final overlay = (surface.isLight
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light)
        .copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: surface.bgBase,
      systemNavigationBarIconBrightness:
          surface.isLight ? Brightness.dark : Brightness.light,
    );

    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: Scaffold(
        backgroundColor: surface.bgBase,
        body: Stack(
          children: [
            // ── Background flowing-wave loop + motes ──
            Positioned.fill(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation:
                      Listenable.merge([_driftController, _ambientController]),
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _FlowingWavePainter(
                        animationValue:
                            disableAnimations ? 0.0 : _driftController.value,
                        ambientValue:
                            disableAnimations ? 0.0 : _ambientController.value,
                        isLight: surface.isLight,
                        disableAnimations: disableAnimations,
                      ),
                    );
                  },
                ),
              ),
            ),

            // ── Scrim gradient behind action block ──
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 280,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        surface.bgBase.withValues(alpha: 0.0),
                        surface.bgBase.withValues(alpha: 0.70),
                        surface.bgBase,
                      ],
                      stops: const [0.0, 0.40, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // ── Centered Content layout ──
            Positioned.fill(
              child: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Spacer(flex: 2),

                                // BRAND block
                                _buildBrandBlock(surface, voltBase),

                                const Spacer(flex: 3),

                                // ACTION block
                                _buildActionBlock(
                                    surface, voltBase, disableAnimations),

                                const SizedBox(height: 28),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlowingWavePainter extends CustomPainter {
  final double animationValue;
  final double ambientValue;
  final bool isLight;
  final bool disableAnimations;

  _FlowingWavePainter({
    required this.animationValue,
    required this.ambientValue,
    required this.isLight,
    required this.disableAnimations,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const voltColor = Color(0xFFC8FF00);

    // Smooth vertical background gradient so waves blend into the screen.
    final bgGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.transparent,
        isLight
            ? voltColor.withValues(alpha: 0.02)
            : voltColor.withValues(alpha: 0.01),
        isLight
            ? voltColor.withValues(alpha: 0.08)
            : voltColor.withValues(alpha: 0.03),
      ],
    );

    final bgPaint = Paint()
      ..shader = bgGradient.createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Drifting motes: rising slowly in the lower third
    final double moteProgress = disableAnimations ? 0.0 : ambientValue;
    for (int i = 0; i < 8; i++) {
      final double xPercent = ((i * 0.17) + 0.1) % 1.0;
      final double speed = 0.3 + (i % 3) * 0.2;
      final double sizeMod = 1.5 + (i % 4) * 0.5; // 1.5 to 3.0 px
      final double baseAlpha = 0.04 + (i % 3) * 0.02; // 0.04 to 0.08

      final double yProgress = (moteProgress * speed + (i * 0.15)) % 1.0;
      final double yPercent = 0.95 - yProgress * 0.35; // lower third

      double opacity = baseAlpha;
      if (yProgress < 0.2) {
        opacity = baseAlpha * (yProgress / 0.2);
      } else if (yProgress > 0.8) {
        opacity = baseAlpha * ((1.0 - yProgress) / 0.2);
      }

      final center = Offset(xPercent * size.width, yPercent * size.height);
      canvas.drawCircle(
        center,
        sizeMod,
        Paint()..color = voltColor.withValues(alpha: opacity.clamp(0.0, 1.0)),
      );
    }

    final path1 = Path();
    final path2 = Path();
    final path3 = Path();

    final double midY = size.height * 0.80;

    path1.moveTo(0, size.height);
    path2.moveTo(0, size.height);
    path3.moveTo(0, size.height);

    for (double x = 0; x <= size.width; x++) {
      // Wave 1: slower, taller wave
      final y1 = midY + 22 * math.sin(x * 0.008 + animationValue * 2 * math.pi);
      path1.lineTo(x, y1);

      // Wave 2: medium wave, offset phase
      final y2 = midY +
          8 +
          14 * math.sin(x * 0.012 - animationValue * 2 * math.pi + math.pi / 3);
      path2.lineTo(x, y2);

      // Wave 3: faster, shorter wave
      final y3 = midY -
          6 +
          8 * math.sin(x * 0.016 + animationValue * 4 * math.pi + math.pi / 6);
      path3.lineTo(x, y3);
    }

    path1.lineTo(size.width, size.height);
    path2.lineTo(size.width, size.height);
    path3.lineTo(size.width, size.height);

    // Layer 1 (top): Strengthened for AMOLED: crest gradient ~Volt @0.16 fading to @0.02
    final gradient1 = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        voltColor.withValues(alpha: 0.16),
        voltColor.withValues(alpha: 0.02),
      ],
    );
    final paint1 = Paint()
      ..shader = gradient1
          .createShader(Rect.fromLTRB(0, midY - 30, size.width, size.height))
      ..style = PaintingStyle.fill;

    // Layer 2: fainter
    final gradient2 = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        voltColor.withValues(alpha: 0.05),
        voltColor.withValues(alpha: 0.01),
      ],
    );
    final paint2 = Paint()
      ..shader = gradient2
          .createShader(Rect.fromLTRB(0, midY - 20, size.width, size.height))
      ..style = PaintingStyle.fill;

    // Layer 3: fainter
    final gradient3 = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        voltColor.withValues(alpha: 0.03),
        voltColor.withValues(alpha: 0.005),
      ],
    );
    final paint3 = Paint()
      ..shader = gradient3
          .createShader(Rect.fromLTRB(0, midY - 15, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(path3, paint3);
    canvas.drawPath(path2, paint2);
    canvas.drawPath(path1, paint1);

    // Add a luminous crest: stroke top wave path with Volt @0.28, strokeWidth 1.5
    final crestStrokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = voltColor.withValues(alpha: 0.28);
    canvas.drawPath(path1, crestStrokePaint);

    // Wave crest specular: a short bright Volt gradient traveling horizontally driven by animationValue
    if (!disableAnimations) {
      final double cx = animationValue * size.width;
      final highlightPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      void drawSegment(double offset) {
        final rect =
            Rect.fromLTRB(cx + offset - 60, 0, cx + offset + 60, size.height);
        highlightPaint.shader = LinearGradient(
          colors: [
            voltColor.withValues(alpha: 0.0),
            voltColor.withValues(alpha: 0.55),
            voltColor.withValues(alpha: 0.0),
          ],
        ).createShader(rect);
        canvas.drawPath(path1, highlightPaint);
      }

      drawSegment(0);
      if (cx < 60) drawSegment(size.width);
      if (cx > size.width - 60) drawSegment(-size.width);
    }
  }

  @override
  bool shouldRepaint(covariant _FlowingWavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.ambientValue != ambientValue ||
        oldDelegate.isLight != isLight;
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
        child: Container(
          height: 48,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            label,
            style: AppText.caption(
              color: surface.textSecondary,
            ).copyWith(
              fontSize: 12.5,
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
