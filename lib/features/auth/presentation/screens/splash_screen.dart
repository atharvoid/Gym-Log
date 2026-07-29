import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Run resolution in the next microtask so the widget tree is mounted and
    // context.go() can safely be called.
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
  }

  Future<void> _resolve() async {
    if (!mounted) return;

    final user = ref.read(authProvider);

    if (user == null) {
      if (mounted) context.go('/auth');
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
      // Restore profile image if it doesn't exist locally.
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
    // Render a plain scaffold while resolution runs.
    // No animation controllers, no timers, no decorative motion.
    return const Scaffold();
  }
}
