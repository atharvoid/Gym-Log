import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/profile_image_sync_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/providers/premium_provider.dart';
import '../../../../core/services/profile_sync_service.dart';
import '../../../../core/services/sync_engine.dart';
import '../providers/auth_provider.dart';

/// [splash_screen.dart]
/// Purpose: Cinematic Volt-themed brand screen. Resolves auth state + profile
/// existence to decide the correct initial route: /auth → /onboarding → /
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  /// True once this process has already done an initial route resolution.
  /// On re-login we skip the brand pause so the second sign-in feels instant.
  static bool _hasResolvedOnce = false;
  late AnimationController _glowController;
  late AnimationController _introController;
  late AnimationController _exitController;

  late Animation<double> _glowScale;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<double> _exitOpacity;

  bool _isExiting = false;

  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _glowScale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _logoScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.1, 0.5, curve: Curves.easeOutCubic),
      ),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.1, 0.5, curve: Curves.easeIn),
      ),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeIn),
      ),
    );

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );

    // Trigger initial route resolution
    _resolveInitialRoute();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    if (disableAnimations) {
      _glowController.value = 1.0;
      _introController.value = 1.0;
    } else {
      if (!_glowController.isAnimating) _glowController.repeat(reverse: true);
      if (!_introController.isAnimating) _introController.forward();
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    _introController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  Future<void> _resolveInitialRoute() async {
    // Brand pause on cold start; instant on re-login so the user isn't
    // stalled after signing back in (e.g. delete-account → re-login).
    if (!_hasResolvedOnce) {
      await Future.delayed(const Duration(milliseconds: 1200));
    }
    _hasResolvedOnce = true;
    if (!mounted) return;

    final user = ref.read(authProvider);

    // Not logged in → go to auth screen
    if (user == null) {
      await _navigateExit('/auth');
      return;
    }

    final isPremium = ref.read(isPremiumProvider);
    final engine = ref.read(syncEngineProvider);
    unawaited(engine.initSession(user.id, isPremium: isPremium));
    unawaited(engine.enqueuePreferences(user.id));

    final resolution = await ref.read(profileSyncProvider).resolveOnLogin(
          userId: user.id,
          email: user.email ?? '',
        );

    if (!mounted) return;

    if (resolution == ProfileResolution.needsOnboarding) {
      await _navigateExit('/onboarding');
    } else {
      // Restore profile image if it doesn't exist locally
      final prefs = await SharedPreferences.getInstance();
      final localImage = prefs.getString('profile_image_path');
      if (localImage == null || localImage.isEmpty) {
        final imagePath = await ref
            .read(profileImageSyncProvider)
            .downloadIfEntitled(isPremium: isPremium);
        if (imagePath != null) {
          await prefs.setString('profile_image_path', imagePath);
        }
      }
      await _navigateExit('/');
    }
  }

  Future<void> _navigateExit(String targetRoute) async {
    if (!mounted) return;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    if (disableAnimations) {
      context.go(targetRoute);
    } else {
      setState(() {
        _isExiting = true;
      });
      await _exitController.forward();
      if (mounted) context.go(targetRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    const voltBase = Color(0xFFC8FF00); // Volt tokens directly
    final voltGlow = voltBase.withValues(alpha: 0.08);

    Widget content = Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo container
          AnimatedBuilder(
            animation: _introController,
            builder: (context, child) {
              return Opacity(
                opacity: _logoOpacity.value,
                child: Transform.scale(
                  scale: _logoScale.value,
                  child: child,
                ),
              );
            },
            child: Semantics(
              label: 'GymLog logo',
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: surface.surface3,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: voltBase.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: voltBase.withValues(alpha: 0.15),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.fitness_center_rounded,
                    size: 40,
                    color: voltBase,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          AnimatedBuilder(
            animation: _introController,
            builder: (context, child) {
              return Opacity(
                opacity: _textOpacity.value,
                child: child,
              );
            },
            child: Text(
              'GymLog',
              style: AppText.screenTitle(
                color: surface.textPrimary,
                shadows: [
                  Shadow(
                    color: voltBase.withValues(alpha: 0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    // Apply overall exit fade
    if (_isExiting) {
      content = AnimatedBuilder(
        animation: _exitOpacity,
        builder: (context, child) => Opacity(
          opacity: _exitOpacity.value,
          child: child,
        ),
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: surface.bgBase,
      body: Stack(
        children: [
          // Ambient breathing glow in the center
          Positioned.fill(
            child: Center(
              child: AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _glowScale.value,
                    child: child,
                  );
                },
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        voltGlow,
                        voltGlow.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(child: content),
        ],
      ),
    );
  }
}
