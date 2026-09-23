@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/features/auth/presentation/providers/onboarding_draft_provider.dart';
import 'package:gymlog/features/auth/presentation/widgets/onboarding/step_age.dart';
import 'package:gymlog/features/auth/presentation/widgets/onboarding/step_weekly_goal.dart';

import 'golden_test_helpers.dart';

Widget _step(Widget step) => ProviderScope(
      child: SizedBox(width: 390, height: 700, child: step),
    );

void _noop() {}

void main() {
  goldenTest(
    'StepAge renders per theme',
    fileName: 'onboarding_step_age',
    builder: () => allThemesGroup(
      'StepAge',
      _step(const StepAge(onNext: _noop)),
    ),
  );

  goldenTest(
    'StepAge at 100 renders per theme (regression: 3 digits must not wrap)',
    fileName: 'onboarding_step_age_100',
    builder: () => allThemesGroup(
      'StepAge (100)',
      ProviderScope(
        overrides: [
          onboardingDraftProvider
              .overrideWith((ref) => OnboardingDraftNotifier()..updateAge(100)),
        ],
        child: const SizedBox(
          width: 390,
          height: 700,
          child: StepAge(onNext: _noop),
        ),
      ),
    ),
  );

  goldenTest(
    'StepWeeklyGoal renders per theme',
    fileName: 'onboarding_step_weekly_goal',
    builder: () => allThemesGroup(
      'StepWeeklyGoal',
      _step(const StepWeeklyGoal(onNext: _noop)),
    ),
  );
}
