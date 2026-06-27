import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/core/theme/theme_palette.dart';
import 'package:gymlog/core/services/premium_service.dart';
import 'package:gymlog/core/providers/premium_provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:gymlog/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:gymlog/features/profile/presentation/widgets/weekly_bar_chart.dart';
import 'package:gymlog/features/profile/presentation/providers/profile_stats_provider.dart';
import 'package:gymlog/shared/widgets/premium_paywall.dart';

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

class FakePremiumService extends Fake implements PremiumService {
  @override
  Future<Offerings?> offerings({bool forceRefresh = false}) async {
    return null;
  }

  @override
  Future<bool> isEligibleForTrial(String productIdentifier) async {
    return false;
  }
}

void main() {
  testWidgets('ProfileAvatar fallback displays display name letter',
      (tester) async {
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
        theme: ThemeData.dark().copyWith(extensions: [mockDark]),
        home: Scaffold(
          body: ProfileAvatar(
            displayName: 'John Doe',
            imagePath: null,
            size: 56,
            onImageChanged: (_) {},
          ),
        ),
      ),
    );

    await tester.pump();

    // Verify initial-letter fallback text is displayed.
    expect(find.text('J'), findsOneWidget);

    final textWidget = tester.widget<Text>(find.text('J'));
    expect(textWidget.style?.color, AppColors.textSecondary);
  });

  testWidgets('WeeklyBarChart low-data comparison view dynamic colors',
      (tester) async {
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

    // 2 filled weeks is less than 4, triggering ComparisonView
    final aggregates = [
      WeeklyAggregate(
        weekStart: DateTime.now().subtract(const Duration(days: 14)),
        volumeKg: 1000,
        totalReps: 100,
        duration: const Duration(minutes: 45),
        workoutCount: 2,
      ),
      WeeklyAggregate(
        weekStart: DateTime.now().subtract(const Duration(days: 7)),
        volumeKg: 1200,
        totalReps: 120,
        duration: const Duration(minutes: 50),
        workoutCount: 3,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark().copyWith(extensions: [mockLight]),
        home: Scaffold(
          body: WeeklyBarChart(
            aggregates: aggregates,
            metric: ProfileGraphMetric.volume,
            isPremium: false,
          ),
        ),
      ),
    );

    await tester.pump();

    // In light surface, textTertiary resolves to light token textTertiary
    final statLabelFinder = find.text('Last week');
    expect(statLabelFinder, findsOneWidget);

    final textWidget = tester.widget<Text>(statLabelFinder);
    expect(textWidget.style?.color, AppColors.textTertiaryLight);
  });

  testWidgets(
      'PremiumPaywall UI headline resolves and sheet themes dynamically',
      (tester) async {
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
      ProviderScope(
        overrides: [
          premiumServiceProvider.overrideWithValue(FakePremiumService()),
        ],
        child: MaterialApp(
          theme: ThemeData.dark().copyWith(extensions: [mockLight]),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => showPremiumPaywall(context,
                      source: PaywallSource.timeRange),
                  child: const Text('Show Paywall'),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Paywall'));
    await tester.pumpAndSettle();

    // Verify headline exists
    expect(find.text('Long-term trends'), findsOneWidget);

    final headlineText = tester.widget<Text>(find.text('Long-term trends'));
    // Under light surface, textPrimary should resolve to light token textPrimary
    expect(headlineText.style?.color, AppColors.textPrimaryLight);
  });
}
