import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/database_provider.dart';
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
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final user = ref.read(authProvider);

    // Not logged in → go to auth screen
    if (user == null) {
      context.go('/auth');
      return;
    }

    // Logged in → check if local profile exists
    final db = ref.read(databaseProvider);
    final profile = await db.userDao.getUserOrNull(user.id);

    if (!mounted) return;

    if (profile == null) {
      // First-time user: capture name before entering the app
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
        child: Text(
          'GymLog',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}
