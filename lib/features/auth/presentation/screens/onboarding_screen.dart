import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';
import 'package:gymlog/features/auth/presentation/providers/onboarding_draft_provider.dart';
import 'package:gymlog/features/auth/presentation/providers/tour_provider.dart';
import 'package:gymlog/features/auth/presentation/widgets/onboarding/step_name.dart';
import 'package:gymlog/features/auth/presentation/widgets/onboarding/step_age.dart';
import 'package:gymlog/features/auth/presentation/widgets/onboarding/step_gender.dart';
import 'package:gymlog/features/auth/presentation/widgets/onboarding/step_units.dart';
import 'package:gymlog/features/auth/presentation/widgets/onboarding/step_experience.dart';
import 'package:gymlog/features/auth/presentation/widgets/onboarding/step_weekly_goal.dart';
import 'package:gymlog/features/auth/presentation/widgets/onboarding/step_theme.dart';
import 'package:gymlog/features/auth/presentation/widgets/onboarding/step_completion.dart';
import 'package:gymlog/shared/widgets/ui/app_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Prefill name from Google sign-in metadata if available
    final user = ref.read(authProvider);
    final meta = user?.userMetadata;
    final googleName = (meta?['full_name'] ?? meta?['name']) as String?;
    if (googleName != null && googleName.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref
              .read(onboardingDraftProvider.notifier)
              .updateName(googleName.trim());
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _pageController.jumpToPage(page);
      setState(() => _currentPageIndex = page);
    } else {
      _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _cancel() async {
    final draftName = ref.read(onboardingDraftProvider).name;
    if (draftName.isNotEmpty) {
      final discard = await showAppConfirmDialog(
        context: context,
        title: 'Cancel setup?',
        message: "Your onboarding selections won't be saved. You'll be signed "
            "out and returned to the start.",
        confirmLabel: 'Sign Out',
        cancelLabel: 'Keep Editing',
        isDestructive: true,
      );
      if (!discard) return;
    }
    await ref.read(authRepositoryProvider).signOut();
    if (mounted) context.go('/auth');
  }

  Future<void> _handleStartTour() async {
    final prefs = await SharedPreferences.getInstance();
    // Defer the masked tour until the user has real content (a routine or a
    // logged workout) so spotlights never land on empty placeholder UI.
    await prefs.setInt(
        'first_run_tour_step', FirstRunTourNotifier.deferredStep);
    if (mounted) {
      context.go('/');
    }
  }

  Future<void> _handleSkipTour() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('first_run_tour_step', -1); // Skip tour permanently
    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    final accent = context.accent;

    const int totalSteps = 8;
    final progress = (_currentPageIndex + 1) / totalSteps;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: surface.isLight
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (_currentPageIndex > 0) {
            _goToPage(_currentPageIndex - 1);
          } else {
            _cancel();
          }
        },
        child: Scaffold(
          backgroundColor: surface.bgBase,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _currentPageIndex == 0
                        ? TextButton(
                            onPressed: _cancel,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.arrow_back_rounded,
                                    size: 18, color: surface.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  'Cancel',
                                  style: AppText.body(
                                    color: surface.textSecondary,
                                  ).copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : IconButton(
                            icon: Icon(
                              Icons.arrow_back_rounded,
                              color: surface.textSecondary,
                              size: 24,
                            ),
                            tooltip: 'Back',
                            constraints: const BoxConstraints(
                                minWidth: 48, minHeight: 48),
                            onPressed: () {
                              _goToPage(_currentPageIndex - 1);
                            },
                          ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          height: 4,
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: surface.surface3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _currentPageIndex == 7
                                  ? AppColors.success
                                  : accent.base,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '${_currentPageIndex + 1}/$totalSteps',
                      style: AppText.caption(color: surface.textSecondary)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: PageView(
            controller: _pageController,
            physics:
                const NeverScrollableScrollPhysics(), // Control via CTAs only
            onPageChanged: (index) {
              setState(() {
                _currentPageIndex = index;
              });
            },
            children: [
              StepName(onNext: () => _goToPage(1)),
              StepAge(onNext: () => _goToPage(2)),
              StepGender(onNext: () => _goToPage(3)),
              StepUnits(onNext: () => _goToPage(4)),
              StepExperience(onNext: () => _goToPage(5)),
              StepWeeklyGoal(onNext: () => _goToPage(6)),
              StepTheme(onNext: () => _goToPage(7)),
              StepCompletion(
                onStartTour: _handleStartTour,
                onSkipTour: _handleSkipTour,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
