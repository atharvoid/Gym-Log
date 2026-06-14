import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

/// Drop-in body for `AsyncValue.when(error:)` branches.
///
/// The pre-launch audit found four screens that stranded the user on a bare
/// `Center(child: Text('error'))` — no retry, sometimes no back button. This
/// is the shared replacement: a calm message plus a retry affordance. It is a
/// plain widget (not a Scaffold) so it slots into an existing body; pair it
/// with [AppNotFoundScreen] for full-screen / deleted-entity cases.
class AsyncErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const AsyncErrorState({
    super.key,
    this.message = "Something went wrong. Your data is safe.",
    this.onRetry,
    this.icon = Icons.cloud_off_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 30, color: Colors.white.withValues(alpha: 0.30)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.4,
                // textPrimary, not a dim grey — AA contrast on OLED black.
                color: AppColors.textPrimary,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 14),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded,
                    size: 18, color: AppColors.accentText),
                label: Text(
                  'Try again',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentText,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Full-screen "this record doesn't exist" state with a GUARANTEED way out:
/// an AppBar back button AND an explicit action button. Used where a routed
/// entity (routine / workout / exercise) was deleted or the id is bad.
class AppNotFoundScreen extends StatelessWidget {
  final String title;
  final String? message;
  final String actionLabel;

  /// Defaults to popping the current route. Pass an explicit callback (e.g.
  /// `() => context.go('/')`) when there may be no back stack to pop.
  final VoidCallback? onAction;

  const AppNotFoundScreen({
    super.key,
    this.title = 'Not found',
    this.message,
    this.actionLabel = 'Go back',
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgBase,
        scrolledUnderElevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded,
                  size: 34, color: Colors.white.withValues(alpha: 0.25)),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 6),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              TextButton(
                onPressed: onAction ?? () => Navigator.of(context).maybePop(),
                child: Text(
                  actionLabel,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentText,
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
