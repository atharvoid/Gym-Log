import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/workout/presentation/providers/active_workout_provider.dart';
import '../../core/services/workout_draft_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import 'active_workout_bar.dart';
import 'bottom_nav_bar.dart';

/// [app_shell.dart]
/// Purpose: High-Density Tracker - App shell with bottom nav
/// Mounts once after auth, so it's the natural place to offer to resume an
/// interrupted workout (a draft persisted by [WorkoutDraftStore]).

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
    // Don't interrupt if a session is somehow already live.
    if (!mounted || ref.read(activeWorkoutProvider) != null) return;
    final store = ref.read(workoutDraftStoreProvider);
    final draft = await store.load(); // null if none / older than 24h
    if (draft == null || !mounted) return;

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
          decoration: const BoxDecoration(
            color: AppColors.surface2,
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
                    color: AppColors.borderEmphasis,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                // Icon badge
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.indigoTint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: const Icon(
                    Icons.fitness_center_rounded,
                    size: 36,
                    color: AppColors.accentText,
                  ),
                ),
                const SizedBox(height: 16),
                Text('Resume Workout?',
                    style: AppText.sheetTitle(),
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(
                  'You have an unfinished workout started $ago. Continue where you left off.',
                  style: AppText.body(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                // Resume (primary)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentPrimary,
                      foregroundColor: AppColors.textPrimary,
                      elevation: 0,
                      shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.buttonPrimaryAll),
                    ),
                    onPressed: () => Navigator.of(sheetCtx).pop(true),
                    child: Text('Resume Workout', style: AppText.button()),
                  ),
                ),
                const SizedBox(height: 8),
                // Discard (secondary)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.buttonSecondaryAll),
                    ),
                    onPressed: () => Navigator.of(sheetCtx).pop(false),
                    child: Text('Discard',
                        style: AppText.button(color: AppColors.textSecondary)),
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
      context.push('/workout/active');
    } else {
      await store.clear(); // explicit decline → discard
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWorkoutActive = ref.watch(activeWorkoutProvider) != null;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: widget.navigationShell,
          ),
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration:
                reduceMotion ? Duration.zero : const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeOutCubic,
            transitionBuilder: (child, animation) {
              return SizeTransition(
                sizeFactor: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1.0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: isWorkoutActive
                ? const ActiveWorkoutBar(key: ValueKey('activeBar'))
                : const SizedBox.shrink(key: ValueKey('emptyBar')),
          ),
          BottomNavBar(
            currentIndex: widget.navigationShell.currentIndex,
            onTap: (index) => widget.navigationShell.goBranch(
              index,
              // Re-tapping the active tab pops it back to its branch root.
              initialLocation: index == widget.navigationShell.currentIndex,
            ),
          ),
        ],
      ),
    );
  }
}
