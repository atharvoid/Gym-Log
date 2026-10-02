import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' show Value;
import 'package:gymlog/shared/widgets/branded_line_chart.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/theme_palette.dart';
import 'package:gymlog/core/utils/units.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import 'package:gymlog/core/models/pr_card_data.dart';
import 'package:gymlog/core/models/personal_record.dart';
import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';
import 'package:gymlog/features/workout/domain/active_workout_state.dart';
import 'package:gymlog/features/workout/presentation/providers/active_workout_provider.dart';
import 'session_1_fixtures.dart';

double contrast(Color foreground, Color background) {
  final ink = Color.alphaBlend(foreground, background).computeLuminance();
  final backing = background.computeLuminance();
  return ((ink > backing ? ink : backing) + .05) /
      ((ink > backing ? backing : ink) + .05);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final palette in ThemePalette.values) {
    test('${palette.name}: composed tertiary text and chart ticks meet 4.5:1',
        () {
      const s = SurfaceTokens.dark;
      for (final background in [
        s.bgBase,
        s.bgSurface,
        s.surface2,
        s.surface3,
        s.surface4,
        Color.alphaBlend(palette.tokens.muted, s.surface3),
        Color.alphaBlend(palette.tokens.glow, s.surface2),
        Color.alphaBlend(AppColors.successTint, s.surface3),
        Color.alphaBlend(AppColors.warningTint, s.surface3)
      ]) {
        for (final ink in [
          s.textTertiary,
          AppColors.chartAxisLabel,
          AppColors.profileGraphAxisLabel
        ]) {
          expect(contrast(ink, background), greaterThanOrEqualTo(4.5),
              reason: 'Composed foreground $ink on $background');
        }
      }
    });
    test(
        '${palette.name}: solid accent label meets 4.5:1',
        () => expect(contrast(palette.tokens.onAccent, palette.tokens.base),
            greaterThanOrEqualTo(4.5)));
  }
  test(
      'summary uses the existing display conversion for pounds',
      () => expect(fixtureSummary('weighted').primaryMetricValue(unit: 'lbs'),
          formatVolume(476, 'lbs')));
  test('summary preserves logged hold seconds',
      () => expect(fixtureSummary('timed').primaryMetricValue(), '1m 15s'));
  test('short distance summary preserves metres',
      () => expect(fixtureSummary('distance').primaryMetricValue(), '400 m'));
  test('an estimated record value is not its logged weight', () {
    const record = PersonalRecord(
        type: PersonalRecordType.estimatedOneRepMax,
        exerciseId: 42,
        exerciseName: 'Bench',
        value: 100,
        unit: 'kg',
        setId: 'old-without-evidence');
    expect(record.weightKg, 0);
    expect(fixturePr.weightKg, 75);
  });
  test(
      'estimated share hero never implies the estimate was lifted for seven reps',
      () {
    final card = PrCardData(
        exerciseName: 'Bench',
        prType: PrCardType.estimated1rm,
        heroValue: '100',
        unit: 'KG',
        reps: 7,
        deltaText: '+5 kg',
        date: fixtureDate);
    expect(card.heroDisplay, '100 KG');
  });
  test('a timed PR shares seconds once, without a rep multiplier', () {
    const record = PersonalRecord(
        type: PersonalRecordType.maxDuration,
        exerciseId: 42,
        exerciseName: 'Plank',
        value: 75,
        unit: 's',
        setId: 'hold',
        loggedReps: 75);
    final card = PrCardData.fromPersonalRecord(
        pr: record, sessionDate: fixtureDate, isImperial: true);
    expect(card.heroDisplay, '75 SEC');
  });
  test('distance and pace PR shares preserve their recorded dimensions', () {
    for (final record in [
      const PersonalRecord(
          type: PersonalRecordType.maxDistance,
          exerciseId: 42,
          exerciseName: 'Run',
          value: 400,
          unit: 'm',
          setId: 'run',
          loggedWeightKg: 400,
          loggedReps: 75),
      const PersonalRecord(
          type: PersonalRecordType.bestPace,
          exerciseId: 42,
          exerciseName: 'Run',
          value: 0.1875,
          unit: 's/m',
          setId: 'run',
          loggedWeightKg: 400,
          loggedReps: 75)
    ]) {
      final card = PrCardData.fromPersonalRecord(
          pr: record, sessionDate: fixtureDate, isImperial: true);
      expect(
          card.unit, record.type == PersonalRecordType.bestPace ? '/KM' : 'M');
      expect(card.heroDisplay, isNot(contains('×')));
      expect(
          card.metricLabel,
          record.type == PersonalRecordType.maxDistance
              ? 'MAX DISTANCE'
              : 'BEST PACE');
    }
  });
  test('pace exports preserve actual DAO seconds-per-metre precision', () {
    final card = PrCardData.fromPersonalRecord(
        pr: fixturePacePr, sessionDate: fixtureDate, isImperial: true);
    expect(card.heroDisplay, '3:08 /KM');
    final faster = PrCardData.fromPersonalRecord(
        pr: const PersonalRecord(
            type: PersonalRecordType.bestPace,
            exerciseId: 44,
            exerciseName: 'Run',
            value: 0.1775,
            unit: 's/m',
            setId: 'faster'),
        sessionDate: fixtureDate);
    expect(faster.heroDisplay, '2:58 /KM');
    expect(faster.heroDisplay, isNot(card.heroDisplay));
  });
  testWidgets('pace celebration converts current and previous spoken pace',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(fixtureApp('pr-pace', ThemePalette.higgsfield, 1));
    await tester.pumpAndSettle();
    expect(find.text('3:08 /km'), findsOneWidget);
    expect(find.text('prev 3:20 /km'), findsOneWidget);
    expect(
        find.bySemanticsLabel(RegExp(
            'Best pace, 3 minutes 8 seconds per kilometre.*Previous: 3 minutes 20 seconds per kilometre')),
        findsOneWidget);
    semantics.dispose();
  });
  test('distance metres times seconds never become weighted session volume',
      () async {
    FlutterSecureStorage.setMockInitialValues({});
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      authProvider.overrideWithValue(null)
    ]);
    final notifier = container.read(activeWorkoutProvider.notifier);
    await notifier.startWorkout(name: 'Distance', initialExercises: [
      const WorkoutExerciseState(
          id: 'run',
          exerciseId: 42,
          name: 'Run',
          measurementType: 'distance',
          sets: [
            WorkoutSetState(id: 's', weightKg: 400, reps: 75, isCompleted: true)
          ])
    ]);
    expect(notifier.sessionTotals, (0.0, 1));
    expect(container.read(sessionTotalsProvider), (0.0, 1));
    container.dispose();
    await db.close();
  });
  testWidgets('workout detail volume converts once to pounds', (tester) async {
    await tester.pumpWidget(fixtureApp('detail', ThemePalette.higgsfield, 1));
    await tester.pumpAndSettle();
    expect(find.text(formatVolume(476, 'lbs')), findsOneWidget);
    expect(find.text('476 kg'), findsNothing);
  });
  testWidgets(
      'PR exports describe recorded results without certification claims',
      (tester) async {
    for (final variant in ['technical', 'sticker']) {
      await tester
          .pumpWidget(fixtureApp('share-$variant', ThemePalette.higgsfield, 1));
      await tester.pumpAndSettle();
      expect(find.text('OFFICIAL RECORD'), findsNothing);
      expect(find.text('VERIFIED ON-DEVICE'), findsNothing);
    }
  });
  testWidgets('missing 1RM estimate never borrows the logged weight',
      (tester) async {
    await tester.pumpWidget(
        fixtureApp('exercise-no-estimate', ThemePalette.higgsfield, 1));
    await tester.pumpAndSettle();
    final chart =
        tester.widget<BrandedLineChart>(find.byType(BrandedLineChart));
    expect(chart.data, isEmpty);
    expect(chart.emptyTitle, 'No estimate available');
    expect(chart.emptySubtitle, contains('Heaviest Weight'));
    expect(chart.emptySubtitle, contains('Total Reps'));
  });
  test(
      'editing distance workout does not persist metres times seconds as kg volume',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    try {
      await db.into(db.exercises).insert(ExercisesCompanion.insert(
          id: const Value(42),
          name: 'Run',
          bodyPart: 'Legs',
          equipment: 'Bodyweight',
          target: 'Legs',
          measurementType: const Value('distance')));
      await db.workoutsDao.insertSession(WorkoutSessionsCompanion.insert(
          id: const Value('edit'),
          userId: 'fixture',
          name: const Value('Run'),
          startedAt: fixtureDate));
      await db.workoutsDao.updateHistoricalWorkout(ActiveWorkoutState(
          id: 'edit',
          name: 'Run',
          startTime: fixtureDate,
          originalSessionId: 'edit',
          exercises: const [
            WorkoutExerciseState(
                id: 'run',
                exerciseId: 42,
                name: 'Run',
                measurementType: 'distance',
                sets: [
                  WorkoutSetState(
                      id: 's', weightKg: 400, reps: 75, isCompleted: true)
                ])
          ]));
      expect((await db.workoutsDao.getSession('edit')).totalVolumeKg, 0);
    } finally {
      await db.close();
    }
  });
  testWidgets(
      'PR visibly labels the estimate and does not invent zero-rep logged set',
      (tester) async {
    await tester.pumpWidget(fixtureApp('pr', ThemePalette.higgsfield, 1));
    await tester.pumpAndSettle();
    expect(find.textContaining('Estimated 1RM'), findsWidgets);
    expect(find.textContaining('× 0 reps'), findsNothing);
    final spoken = tester
        .widgetList<Semantics>(find.byType(Semantics))
        .map((s) => s.properties.label ?? '')
        .join(' ');
    expect(spoken, contains('220.5 pounds'));
    expect(spoken, contains('165.3 pounds for 10 reps'));
    expect(spoken, isNot(contains('100 kilograms')));
  });
  testWidgets('finish review does not announce completion before save',
      (tester) async {
    await tester
        .pumpWidget(fixtureApp('finish-timed', ThemePalette.higgsfield, 1));
    await tester.pumpAndSettle();
    tester
        .widget<TextButton>(find.widgetWithText(TextButton, 'Open summary'))
        .onPressed!();
    await tester.pumpAndSettle();
    expect(find.text('Finish workout'), findsOneWidget);
    expect(find.text('Workout complete'), findsNothing);
  });
  testWidgets(
      'volume and duration changes use neutral color with their direction intact',
      (tester) async {
    await tester.pumpWidget(fixtureApp('progress', ThemePalette.higgsfield, 1));
    await tester.pumpAndSettle();
    final labels = tester
        .widgetList<Text>(find.byType(Text))
        .where((t) => t.data?.contains('%') ?? false);
    expect(labels, isNotEmpty);
    for (final label in labels) {
      expect(label.style?.color, SurfaceTokens.dark.textSecondary);
    }
  });
}
