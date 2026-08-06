import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/workout/presentation/providers/active_workout_provider.dart';
import '../../features/workout/presentation/providers/rest_timer_provider.dart';
import '../../core/services/workout_draft_store.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/chrome_tokens.dart';
import '../../core/theme/dynamic_accent_theme.dart';
import '../layout/adaptive.dart';
import '../providers/bottom_chrome_provider.dart';
import 'active_workout_bar.dart';
import 'bottom_nav_bar.dart';
import 'ui/app_dialog.dart';
import 'ui/app_snack_bar.dart';

/// [app_shell.dart]
/// Purpose: High-Density Tracker - App shell with bottom nav
/// Mounts once after auth, so it's the natural place to offer to resume an
/// interrupted workout (a draft persisted by [WorkoutDraftStore]).
///
/// LAYOUT CONTRACT: `bottomNavigationBar` holds the nav bar and NOTHING else,
/// so the bottom chrome height is constant for the life of the app. The
/// active-workout mini player floats in the body Stack above it. Anything that
/// needs to know how much bottom space is occluded reads
/// [bottomChromeInsetProvider].

class AppShell extends ConsumerStatefulWidget {
  /// Drives the tabbed branches. IndexedStack keeps every branch mounted, so
  /// each tab preserves its own scroll position + state across switches.
  final StatefulNavigationShell navigationShell;
  const AppShell({required this.navigationShell, super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  void initState() {
    super.initState();
    // One-time, after first frame: offer to resume a crash-interrupted session.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeOfferResume());
  }

  Future<void> _maybeOfferResume() async {
    if (!mounted || ref.read(activeWorkoutProvider) != null) return;
    final user = ref.read(authProvider);
    final store = ref.read(workoutDraftStoreProvider);

    WorkoutDraftSnapshot? snapshot;
    try {
      snapshot = await store.loadSnapshot(currentUserId: user?.id);
    } catch (_) {
      // A draft the user was mid-way through exists on disk but could not be
      // read. It is silently skipped — worse, the user believes the resume
      // offer simply never happened. Tell them instead.
      if (mounted) {
        showAppSnackBar(
          context,
          message: "Couldn't check for an in-progress workout.",
        );
      }
      return;
    }
    if (snapshot == null || !mounted) return;
    final draft = snapshot.workout;

    final accent = context.accent;

    final mins = DateTime.now().difference(draft.startTime).inMinutes;
    final ago = mins < 1
        ? 'just now'
        : mins < 60
            ? '$mins min ago'
            : '${mins ~/ 60}h ${mins % 60}m ago';

    final resume = await showModalBottomSheet<bool>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: context.chrome.sheetBg,
            borderRadius: AppRadius.sheetTop,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.surface.borderEmphasis,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                // Icon badge
                Container(
                  decoration: BoxDecoration(
                    color: accent.muted,
                    borderRadius: AppRadius.thumbnailAll,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.fitness_center_rounded,
                    size: 36,
                    color: accent.light,
                  ),
                ),
                const SizedBox(height: 16),
                Text('Resume Workout?',
                    style: AppText.sheetTitle(), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(
                  'You have an unfinished workout started $ago. Continue where you left off.',
                  style: AppText.body(color: context.chrome.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                // Resume (primary)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent.base,
                      foregroundColor: accent.onAccent,
                      elevation: 0,
                      shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.buttonPrimaryAll),
                    ),
                    onPressed: () => Navigator.of(sheetCtx).pop(true),
                    child: Text('Resume Workout',
                        style: AppText.button(color: accent.onAccent)),
                  ),
                ),
                const SizedBox(height: 8),
                // Discard (destructive — this permanently drops a logged
                // session, so it is red-on-outline, not a quiet grey label
                // sitting next to a bright accent-filled Resume).
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(
                          color: AppColors.errorBorder, width: 1),
                      shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.buttonSecondaryAll),
                    ),
                    onPressed: () => Navigator.of(sheetCtx).pop(false),
                    child: Text('Discard Workout',
                        style: AppText.button(color: AppColors.error)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (resume == true) {
      ref.read(activeWorkoutProvider.notifier).resumeDraft(draft);
      if (snapshot.restTimer != null) {
        ref.read(restTimerProvider.notifier).resumeFromEndTime(
              endTime: snapshot.restTimer!.endTime,
              totalSeconds: snapshot.restTimer!.totalSeconds,
              workoutId: snapshot.restTimer!.workoutId,
              exerciseId: snapshot.restTimer!.exerciseId,
              setId: snapshot.restTimer!.setId,
            );
      }
      context.push('/workout/active');
    } else if (resume == false) {
      if (!mounted) return;
      final confirm = await showAppConfirmDialog(
        context: context,
        title: 'Discard draft workout?',
        message: 'Your in-progress workout draft will be permanently deleted.',
        confirmLabel: 'Discard',
        isDestructive: true,
      );
      if (confirm) {
        try {
          await store.clear();
        } catch (e, st) {
          // Straggler from C38's debugPrint sweep: this ran unguarded in
          // release, writing the draft store's exception text to the
          // production device log. It was also swallowed outright — but a
          // failed clear silently un-honours the user's Discard, so the
          // draft reappears on the next launch and the resume sheet asks
          // again about a workout they already deleted. Report it.
          if (kDebugMode) {
            debugPrint('[AppShell] Draft clear error: $e');
          }
          await Sentry.captureException(e, stackTrace: st);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWorkoutActive =
        ref.watch(activeWorkoutProvider.select((s) => s != null));
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final surface = context.surface;
    final overlayStyle = surface.isLight
        ? SystemUiOverlayStyle.dark
        : SystemUiOverlayStyle.light;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: context.chrome.background,
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Positioned.fill(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                        maxWidth: context.adaptive.contentMaxWidth),
                    child: widget.navigationShell,
                  ),
                ),
              ),
              // The mini player floats over content. `bottom` is measured from
              // the body's own bottom edge, which already sits above the nav bar
              // — so this is a pure 8dp gap with no safe-area math to get wrong.
              Positioned(
                left: 16,
                right: 16,
                bottom: kActiveBarGap,
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                        maxWidth: context.adaptive.contentMaxWidth - 32),
                    child: AnimatedSwitcher(
                      duration: reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 280),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeOutCubic,
                      // Slide + fade only. Deliberately NOT SizeTransition: the
                      // bar no longer participates in the nav bar's layout, so
                      // there is nothing to grow — and animating size here was
                      // what visibly shoved the nav bar down on workout start.
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.6),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: isWorkoutActive
                          ? const ActiveWorkoutBar(key: ValueKey('activeBar'))
                          : const SizedBox.shrink(key: ValueKey('emptyBar')),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: widget.navigationShell.currentIndex,
          onTap: (index) => widget.navigationShell.goBranch(
            index,
            // Re-tapping the active tab pops it back to its branch root.
            initialLocation: index == widget.navigationShell.currentIndex,
          ),
        ),
      ),
    );
  }
}
