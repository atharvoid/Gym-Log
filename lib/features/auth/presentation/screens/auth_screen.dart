import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';
import 'package:gymlog/shared/widgets/ui/app_dialog.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _busy = false;

  void _showError(String message) {
    if (!mounted) return;
    final surface = context.surface;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: AppText.body(color: surface.textPrimary)),
      backgroundColor: surface.surface2,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _signInWithGoogle() async {
    if (_busy) return;
    setState(() => _busy = true);
    HapticFeedback.mediumImpact();
    try {
      await ref.read(authProvider.notifier).signInWithGoogle();
    } on UnsupportedError {
      _showError(
          "Google sign-in isn't available in this build. Please update the app or contact support.");
    } on Exception catch (e) {
      if (e.toString().contains('network')) {
        _showError("You're offline. Check your connection and try again.");
      } else {
        _showError("Couldn't sign in. Please try again.");
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    return Scaffold(
      backgroundColor: surface.bgBase,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('GymLog',
                  style: AppText.pageTitle(color: surface.textPrimary)),
              const SizedBox(height: 8),
              Text('Track your training.',
                  style: AppText.body(color: surface.textSecondary)),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _busy ? null : _signInWithGoogle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.accent.base,
                    foregroundColor: context.accent.onAccent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppRadius.buttonPrimary)),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text('Sign in with Google', style: AppText.button()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
