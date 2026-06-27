import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/database/daos/workouts_dao.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/core/theme/theme_palette.dart';
import 'package:gymlog/shared/widgets/ui/app_action_row.dart';
import 'package:gymlog/features/home/presentation/widgets/workout_history_card.dart';

class MockAccentColors extends AccentColors {
  final bool _isLightSurface;

  const MockAccentColors({
    required super.base,
    required super.light,
    required super.dark,
    required super.muted,
    required super.glow,
    required super.onAccent,
    required super.muscleSplitRamp,
    required super.palette,
    required bool isLightSurface,
  }) : _isLightSurface = isLightSurface;

  @override
  bool get isLightSurface => _isLightSurface;

  @override
  Object get type => AccentColors;

  @override
  MockAccentColors copyWith({
    Color? base,
    Color? light,
    Color? dark,
    Color? muted,
    Color? glow,
    Color? onAccent,
    List<Color>? muscleSplitRamp,
    ThemePalette? palette,
  }) {
    return MockAccentColors(
      base: base ?? this.base,
      light: light ?? this.light,
      dark: dark ?? this.dark,
      muted: muted ?? this.muted,
      glow: glow ?? this.glow,
      onAccent: onAccent ?? this.onAccent,
      muscleSplitRamp: muscleSplitRamp ?? this.muscleSplitRamp,
      palette: palette ?? this.palette,
      isLightSurface: _isLightSurface,
    );
  }

  @override
  MockAccentColors lerp(ThemeExtension<AccentColors>? other, double t) {
    if (other is! AccentColors) return this;
    return MockAccentColors(
      base: Color.lerp(base, other.base, t)!,
      light: Color.lerp(light, other.light, t)!,
      dark: Color.lerp(dark, other.dark, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      glow: Color.lerp(glow, other.glow, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      muscleSplitRamp: t < 0.5 ? muscleSplitRamp : other.muscleSplitRamp,
      palette: t < 0.5 ? palette : other.palette,
      isLightSurface: _isLightSurface,
    );
  }
}

void main() {
  testWidgets(
      'AppActionDivider color resolves dynamically based on surface theme',
      (tester) async {
    // 1. Pump under dark surface
    final mockDark = MockAccentColors(
      base: Colors.purple,
      light: Colors.purple.shade200,
      dark: Colors.purple.shade800,
      muted: Colors.purple.withValues(alpha: 0.14),
      glow: Colors.purple.withValues(alpha: 0.12),
      onAccent: Colors.white,
      muscleSplitRamp: const [],
      palette: ThemePalette.neonPurple,
      isLightSurface: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        key: const ValueKey('dark_app'),
        themeMode: ThemeMode.light,
        theme: ThemeData.dark().copyWith(
          extensions: [mockDark],
        ),
        home: const Scaffold(
          body: AppActionDivider(),
        ),
      ),
    );
    await tester.pump();

    final darkContainerFinder = find.descendant(
      of: find.byType(AppActionDivider),
      matching: find.byType(Container),
    );
    expect(darkContainerFinder, findsOneWidget);
    final darkContainer = tester.widget<Container>(darkContainerFinder);
    expect(darkContainer.color, AppColors.borderSubtle);

    // 2. Pump under light surface
    final mockLight = MockAccentColors(
      base: Colors.purple,
      light: Colors.purple.shade200,
      dark: Colors.purple.shade800,
      muted: Colors.purple.withValues(alpha: 0.14),
      glow: Colors.purple.withValues(alpha: 0.12),
      onAccent: Colors.white,
      muscleSplitRamp: const [],
      palette: ThemePalette.neonPurple,
      isLightSurface: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        key: const ValueKey('light_app'),
        themeMode: ThemeMode.light,
        theme: ThemeData.dark().copyWith(
          extensions: [mockLight],
        ),
        home: const Scaffold(
          body: AppActionDivider(),
        ),
      ),
    );
    await tester.pump();

    final lightContainerFinder = find.descendant(
      of: find.byType(AppActionDivider),
      matching: find.byType(Container),
    );
    expect(lightContainerFinder, findsOneWidget);
    final lightContainer = tester.widget<Container>(lightContainerFinder);
    expect(lightContainer.color, AppColors.borderSubtleLight);
  });

  testWidgets(
      'WorkoutHistoryCard divider color resolves dynamically based on surface theme',
      (tester) async {
    final session = WorkoutSession(
      id: '123',
      userId: 'user1',
      name: 'Upper Body',
      startedAt: DateTime.fromMillisecondsSinceEpoch(0),
      notes: '',
      totalVolumeKg: 100,
      synced: true,
    );

    final preview = WorkoutSessionPreview(
      session: session,
      duration: Duration.zero,
      totalVolumeKg: 100,
      prCount: 0,
      topExercises: const [],
      totalExerciseCount: 0,
    );

    Widget buildCard(bool isLight) {
      final mockAccent = MockAccentColors(
        base: Colors.purple,
        light: Colors.purple.shade200,
        dark: Colors.purple.shade800,
        muted: Colors.purple.withValues(alpha: 0.14),
        glow: Colors.purple.withValues(alpha: 0.12),
        onAccent: Colors.white,
        muscleSplitRamp: const [],
        palette: ThemePalette.neonPurple,
        isLightSurface: isLight,
      );

      return MaterialApp(
        key: ValueKey(isLight ? 'light_card' : 'dark_card'),
        themeMode: ThemeMode.light,
        theme: ThemeData.dark().copyWith(
          extensions: [mockAccent],
        ),
        home: Scaffold(
          body: WorkoutHistoryCard(
            preview: preview,
            onMenuPressed: () {},
          ),
        ),
      );
    }

    // 1. Pump under dark surface
    await tester.pumpWidget(buildCard(false));
    await tester.pump();

    // Find the divider (Container of height 1)
    final darkDividerFinder = find.byWidgetPredicate(
        (w) => w is Container && w.constraints?.maxHeight == 1);
    expect(darkDividerFinder, findsOneWidget);
    final darkDivider = tester.widget<Container>(darkDividerFinder);
    expect(darkDivider.color, AppColors.borderSubtle);

    // 2. Pump under light surface
    await tester.pumpWidget(buildCard(true));
    await tester.pump();

    final lightDividerFinder = find.byWidgetPredicate(
        (w) => w is Container && w.constraints?.maxHeight == 1);
    expect(lightDividerFinder, findsOneWidget);
    final lightDivider = tester.widget<Container>(lightDividerFinder);
    expect(lightDivider.color, AppColors.borderSubtleLight);
  });
}
