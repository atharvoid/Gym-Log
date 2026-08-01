import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/features/auth/data/auth_repository.dart';
import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';

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

  /// Starts Google sign-in.
  ///
  /// Goes through [authRepositoryProvider], not [authProvider]. authProvider
  /// is a Provider<User?> — a read-only view of who is signed in. It has no
  /// .notifier and User? has no sign-in method, so the previous call here
  /// could not compile. The repository is the object that owns the action,
  /// and it is the same one both sign-out call sites already use.
  ///
  /// The repository throws a sealed AuthFailure hierarchy, so every case is
  /// caught by type. The previous string match on 'network' never fired:
  /// AuthNetworkFailure.toString() is "Instance of 'AuthNetworkFailure'",
  /// which has no lowercase 'network' in it.
  Future<void> _signInWithGoogle() async {
    if (_busy) return;
    setState(() => _busy = true);
    HapticFeedback.mediumImpact();
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
    } on AuthCancelled {
      // Dismissing the account picker is a deliberate choice, not a failure.
      // The button re-enables and nothing is said; an error here would scold
      // the user for changing their mind.
    } on AuthNetworkFailure {
      _showError("You're offline. Check your connection and try again.");
    } on AuthConfigurationFailure catch (e) {
      // Surfacing the diagnostic code is the whole reason it is carried:
      // this failure is unrecoverable for the user but immediately
      // actionable for whoever receives the support report.
      _showError("Google sign-in isn't set up correctly in this build. "
          "Please update the app or contact support (${e.diagnosticCode}).");
    } on AuthProviderFailure {
      _showError(
          'Google sign-in is temporarily unavailable. Please try again in a moment.');
    } on AuthUnknownFailure {
      _showError("Couldn't sign in. Please try again.");
    } catch (_) {
      // Defence in depth. The repository funnels everything into AuthFailure,
      // so reaching this means a new escape route opened upstream; the user
      // still gets a recoverable message rather than a stuck spinner.
      _showError("Couldn't sign in. Please try again.");
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
