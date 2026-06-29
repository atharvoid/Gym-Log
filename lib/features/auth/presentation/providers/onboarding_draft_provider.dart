import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymlog/core/theme/theme_palette.dart';

class OnboardingDraft {
  final String name;
  final int? age;
  final String unit; // 'kg' | 'lbs'
  final String level; // 'beginner' | 'intermediate' | 'advanced'
  final int weeklyGoal; // 1–7
  final ThemePalette palette; // default higgsfield

  const OnboardingDraft({
    this.name = '',
    this.age,
    this.unit = 'kg',
    this.level = 'beginner',
    this.weeklyGoal = 3,
    this.palette = ThemePalette.higgsfield,
  });

  OnboardingDraft copyWith({
    String? name,
    int? age,
    bool clearAge = false,
    String? unit,
    String? level,
    int? weeklyGoal,
    ThemePalette? palette,
  }) {
    return OnboardingDraft(
      name: name ?? this.name,
      age: clearAge ? null : (age ?? this.age),
      unit: unit ?? this.unit,
      level: level ?? this.level,
      weeklyGoal: weeklyGoal ?? this.weeklyGoal,
      palette: palette ?? this.palette,
    );
  }
}

class OnboardingDraftNotifier extends StateNotifier<OnboardingDraft> {
  OnboardingDraftNotifier() : super(const OnboardingDraft());

  void updateName(String name) {
    state = state.copyWith(name: name);
  }

  void updateAge(int? age) {
    if (age == null) {
      state = state.copyWith(clearAge: true);
    } else {
      state = state.copyWith(age: age);
    }
  }

  void updateUnit(String unit) {
    state = state.copyWith(unit: unit);
  }

  void updateLevel(String level) {
    state = state.copyWith(level: level);
  }

  void updateWeeklyGoal(int goal) {
    state = state.copyWith(weeklyGoal: goal);
  }

  void updatePalette(ThemePalette palette) {
    state = state.copyWith(palette: palette);
  }
}

final onboardingDraftProvider =
    StateNotifierProvider<OnboardingDraftNotifier, OnboardingDraft>((ref) {
  return OnboardingDraftNotifier();
});
