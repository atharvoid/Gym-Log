import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/providers/cloud_readiness_provider.dart';
import '../../../../core/providers/premium_provider.dart';
import '../../../../core/services/profile_image_sync_service.dart';
import '../../../../core/services/profile_sync_service.dart';
import '../../../../core/services/sync_engine.dart';

import '../providers/auth_provider.dart';

/// Route-first startup gate.
///
/// Replaces the former cinematic splash screen. This widget holds the
/// application's initial route (`/splash`) while async startup work runs, then
/// immediately navigates to the resolved destination with no entrance or exit
/// animations. A solid background matching the app surface is shown so there
/// is no flash of unstyled content.
///
/// There is deliberately no cinematic motion here. There IS a progress
/// indicator, because resolution can legitimately take several seconds
/// (cloud readiness, then a profile fetch, then a possible profile-image
/// download) and a screen with nothing on it for that long reads as a hang.
/// See [_kProgressDelay].
///
/// EVERY await in [_SplashScreenState._resolve] is bounded. This screen sits
/// between the user and the app; nothing it waits on may wait forever.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

/// How long resolution may run before we show the user anything.
///
/// Tuned so a warm start (the common case) finishes first and the user never
/// sees a spinner flash. Only genuinely slow starts get an indicator.
const Duration _kProgressDelay = Duration(milliseconds: 600);

/// Hard ceiling on how long this screen will wait for the cloud-readiness
/// gate.
///
/// Bootstrap arms its own watchdog, so in principle the gate always resolves.
/// This screen bounds the wait anyway: a screen must never be permanently
/// unusable because a promise it does not own went unkept. Set above
/// Bootstrap's watchdog so the ordinary path always wins and this only fires
/// if the gate itself was never armed.
const Duration _kGateTimeout = Duration(seconds: 15);

/// Ceiling on the optional profile-image restore.
///
/// This is the least important thing on the launch path — a decorative avatar
/// with a perfectly good local fallback — so it gets the tightest bound. A
/// timeout is not an error: it just means the user launches with the fallback
/// avatar and the download is retried on the next launch.
const Duration _kProfileImageTimeout = Duration(seconds: 8);

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _progressTimer;
  bool _showProgress = false;

  @override
  void initState() {
    super.initState();
    _progressTimer = Timer(_kProgressDelay, () {
      if (mounted) setState(() => _showProgress = true);
    });
    // Run resolution in the next microtask so the widget tree is mounted and
    // context.go() can safely be called.
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  Future<void> _resolve() async {
    if (!mounted) return;

    // Cloud init runs post-first-frame; wait for it (bounded by
    // Bootstrap.cloudInitTimeout) so profileSync/syncEngine (which
    // construct Supabase remotes eagerly) see a ready singleton.
    //
    // Bounded independently of Bootstrap: an unresolved gate must degrade to
    // local-only, never to a permanent spinner.
    final cloudReady = await ref.read(cloudReadinessProvider).timeout(
          _kGateTimeout,
          onTimeout: () => false,
        );
    if (!mounted) return;

    final user = ref.read(authProvider);

    if (user == null) {
      // With no cloud there is no account system and nothing to sign in to,
      // so /auth would be a dead end. Go straight into the app; without a
      // cloud, signed-out still means the auth screen.
      if (mounted) context.go(cloudReady ? '/auth' : '/');
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
      context.go('/onboarding');
    } else {
      // Restore profile image if it doesn't exist locally. Bounded: the
      // fallback avatar is a perfectly good result, so this must never be the
      // reason the user is still looking at a spinner.
      final prefs = await SharedPreferences.getInstance();

      // Drain any profile-image upload that failed and was queued for retry
      // (see ProfileImageSyncService.uploadIfEntitled's catch block, which
      // promises "the user never sees a failure"). Before this call, nothing
      // in the app ever invoked retryPendingUpload — a single failed cloud
      // upload silently and permanently disabled avatar backup until the
      // user manually re-picked a photo. Fire-and-forget: a retry is never
      // worth blocking launch on.
      unawaited(
        ref
            .read(profileImageSyncProvider)
            .retryPendingUpload(isPremium: isPremium),
      );

      final localImage = prefs.getString('profile_image_path');
      if (localImage == null || localImage.isEmpty) {
        final imagePath = await ref
            .read(profileImageSyncProvider)
            .downloadIfEntitled(isPremium: isPremium)
            .timeout(_kProfileImageTimeout, onTimeout: () => null);
        if (imagePath != null) {
          await prefs.setString('profile_image_path', imagePath);
        }
      }
      if (mounted) context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: AnimatedOpacity(
          opacity: _showProgress ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: Semantics(
            label: 'Starting GymLog',
            liveRegion: true,
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
