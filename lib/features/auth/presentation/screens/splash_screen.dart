import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
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

    // Start the sync engine for this session: auto-debounce on any queued
    // write, and an immediate sync when connectivity returns. Then restore
    // cloud data (reinstall path) and snapshot preferences — all non-blocking,
    // navigation never waits on the network.
    final engine = ref.read(syncEngineProvider);
    engine.startAutoSync(user.id);
    engine.startConnectivityWatch(user.id);
    unawaited(engine.pull(user.id));
    unawaited(engine.loadLastSynced());
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
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
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
                    color: AppColors.surface3,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.fitness_center,
                      size: 40,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'GymLog',
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 32),
              Semantics(
                label: 'Loading Gymlog...',
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.textSecondary),
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
