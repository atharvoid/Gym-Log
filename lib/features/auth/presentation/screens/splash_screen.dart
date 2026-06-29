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
/// Purpose: 2-second brand screen. Resolves auth state + profile existence
/// to decide the correct initial route: /auth → /onboarding → /

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _resolveInitialRoute();
  }

  Future<void> _resolveInitialRoute() async {
    // Brand pause, not a toll booth — long enough to register, short
    // enough to never feel like loading.
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    final user = ref.read(authProvider);

    // Not logged in → go to auth screen
    if (user == null) {
      context.go('/auth');
      return;
    }

    // Initialise the sync engine for this session: starts the outbox watcher,
    // connectivity watcher, restores cloud data (reinstall path), and loads
    // the last-synced timestamp. initSession() is idempotent — the
    // auth-state listener in app.dart may have already started the engine for
    // fresh-sign-in flows; this call is a safe no-op in that case.
    //
    // The gate is checked inside the engine — if sync is not allowed (free
    // user, or Pro user opted out), the engine stays dormant.
    final isPremium = ref.read(isPremiumProvider);
    final engine = ref.read(syncEngineProvider);
    unawaited(engine.initSession(user.id, isPremium: isPremium));
    unawaited(engine.enqueuePreferences(user.id));

    // Logged in → make the backend authoritative: fetch the stored profile
    // and hydrate local, or fall back to local if offline. First-ever users
    // with no name anywhere are sent to the welcome. Never blocks (timed out
    // internally), retries any queued write along the way.
    final resolution = await ref.read(profileSyncProvider).resolveOnLogin(
          userId: user.id,
          email: user.email ?? '',
        );

    if (!mounted) return;

    if (resolution == ProfileResolution.needsOnboarding) {
      context.go('/onboarding');
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
      if (mounted) context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    return Scaffold(
      backgroundColor: surface.bgBase,
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOut,
          builder: (context, opacity, child) {
            return Opacity(
              opacity: opacity,
              child: child,
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                label: 'GymLog logo',
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: surface.surface3,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.fitness_center,
                      size: 40,
                      color: surface.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'GymLog',
                style: AppText.screenTitle(color: surface.textPrimary),
              ),
              const SizedBox(height: 32),
              Semantics(
                label: 'Loading Gymlog...',
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(surface.textSecondary),
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
