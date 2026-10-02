import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/database/daos/workouts_dao.dart';
import 'package:gymlog/core/models/personal_record.dart';
import 'package:gymlog/core/models/pr_card_data.dart';
import 'package:gymlog/core/models/workout_metric_summary.dart';
import 'package:gymlog/core/providers/settings_provider.dart';
import 'package:gymlog/core/providers/premium_provider.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/app_theme.dart';
import 'package:gymlog/core/theme/theme_palette.dart';
import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';
import 'package:gymlog/features/exercises/presentation/providers/exercise_analytics_provider.dart';
import 'package:gymlog/features/exercises/presentation/screens/exercise_detail_screen.dart';
import 'package:gymlog/features/profile/presentation/providers/profile_stats_provider.dart';
import 'package:gymlog/features/profile/presentation/widgets/graph_kpi_header.dart';
import 'package:gymlog/features/profile/presentation/widgets/weekly_bar_chart.dart';
import 'package:gymlog/features/workout/presentation/providers/workout_detail_provider.dart';
import 'package:gymlog/features/workout/presentation/screens/workout_detail_screen.dart';
import 'package:gymlog/features/workout/presentation/widgets/active_workout_header.dart';
import 'package:gymlog/features/workout/presentation/widgets/finish_summary_sheet.dart';
import 'package:gymlog/features/workout/presentation/widgets/pr_celebration_overlay.dart';
import 'package:gymlog/features/workout/presentation/widgets/share_card/delt_share_card.dart';
import 'package:gymlog/shared/widgets/async_error_state.dart';

final fixtureDate = DateTime(2026, 9, 28, 18);
const fixtureExercise = Exercise(
    id: 42,
    name: 'Bench Press',
    bodyPart: 'Chest',
    equipment: 'Barbell',
    target: 'Chest',
    measurementType: 'weight_and_reps',
    isCustom: false);
final fixtureWorkout = HydratedWorkout(
    session: WorkoutSession(
        id: 'fixture',
        userId: 'fixture',
        name: 'Push A',
        startedAt: fixtureDate,
        endedAt: fixtureDate.add(const Duration(minutes: 24)),
        notes: '',
        totalVolumeKg: 476,
        synced: false),
    exercises: const []);
const fixturePr = PersonalRecord(
    type: PersonalRecordType.estimatedOneRepMax,
    exerciseId: 42,
    exerciseName: 'Bench Press',
    value: 100,
    unit: 'kg',
    setId: 'fixture-set',
    previousValue: 95,
    loggedWeightKg: 75,
    loggedReps: 10);
const fixtureHoldPr = PersonalRecord(
    type: PersonalRecordType.maxDuration,
    exerciseId: 43,
    exerciseName: 'Plank',
    value: 75,
    unit: 's',
    setId: 'hold',
    loggedReps: 75);
const fixtureDistancePr = PersonalRecord(
    type: PersonalRecordType.maxDistance,
    exerciseId: 44,
    exerciseName: 'Run',
    value: 400,
    unit: 'm',
    setId: 'run',
    loggedWeightKg: 400,
    loggedReps: 75);
const fixturePacePr = PersonalRecord(
    type: PersonalRecordType.bestPace,
    exerciseId: 44,
    exerciseName: 'Run',
    value: 0.1875,
    unit: 's/m',
    setId: 'run',
    previousValue: 0.2,
    loggedWeightKg: 400,
    loggedReps: 75);

WorkoutMetricSummary fixtureSummary(String kind) => WorkoutMetricSummary(
    weightedVolumeKg: kind == 'weighted' ? 476 : 0,
    totalReps: kind == 'reps'
        ? 15
        : kind == 'weighted'
            ? 7
            : 0,
    totalDurationSeconds: kind == 'timed' ? 75 : 0,
    totalDistanceMeters: kind == 'distance' ? 400 : 0);

List<WeeklyAggregate> fixtureWeeks({int count = 4, bool down = false}) =>
    List.generate(
        count,
        (i) => WeeklyAggregate(
            weekStart:
                fixtureDate.subtract(Duration(days: (count - i - 1) * 7)),
            volumeKg: down ? 1000.0 - i * 100 : 500.0 + i * 100,
            totalReps: 30 + i * 5,
            duration: Duration(minutes: down ? 60 - i * 5 : 30 + i * 5),
            workoutCount: 2));

Widget fixtureHeader(String kind) => ActiveWorkoutHeader(
    isEditing: false,
    workoutName: 'Push A',
    elapsedTime: '00:24:00',
    volumeKg: fixtureSummary(kind).weightedVolumeKg,
    metricSummary: fixtureSummary(kind),
    completedSets: kind == 'empty' ? 0 : 1,
    weightUnit: 'lbs',
    finishEnabled: kind != 'empty',
    onMinimize: () {},
    onClose: () {},
    onFinish: () {});

Widget fixtureBody(String name) {
  if (name.startsWith('share-')) {
    final variant = ShareCardVariant.values
        .firstWhere((v) => v.name == name.split('-').last);
    final record = name.startsWith('share-duration-')
        ? fixtureHoldPr
        : name.startsWith('share-distance-')
            ? fixtureDistancePr
            : name.startsWith('share-pace-')
                ? fixturePacePr
                : fixturePr;
    return Scaffold(
        body: Center(
            child: DeltShareCard(
                data: PrCardData.fromPersonalRecord(
                    pr: record, sessionDate: fixtureDate, isImperial: true),
                variant: variant)));
  }
  if (name.startsWith('header-')) {
    return Builder(
        builder: (context) => Scaffold(
            backgroundColor: context.surface.bgBase,
            body: fixtureHeader(name.substring(7))));
  }
  if (name == 'pr' || name == 'pr-pace') {
    return Scaffold(
        body: Center(
            child: PrCelebrationCard(
                prs: [name == 'pr-pace' ? fixturePacePr : fixturePr],
                weightUnit: 'lbs',
                onKeepGoing: () {})));
  }
  if (name == 'detail' || name == 'detail-error' || name == 'detail-empty') {
    return const WorkoutDetailScreen(sessionId: 'fixture');
  }
  if (name == 'exercise' || name == 'exercise-no-estimate') {
    return const ExerciseDetailScreen(
        exerciseId: 42, exercise: fixtureExercise);
  }
  if (name.startsWith('progress')) {
    final weeks = fixtureWeeks(
        count: name == 'progress-low'
            ? 2
            : name == 'progress-empty'
                ? 0
                : 4,
        down: true);
    return Scaffold(
        body: SingleChildScrollView(
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  GraphKpiHeader(
                      aggregates: weeks,
                      metric: ProfileGraphMetric.duration,
                      unit: 'lbs'),
                  const SizedBox(height: 20),
                  WeeklyBarChart(
                      aggregates: weeks,
                      metric: ProfileGraphMetric.duration,
                      isPremium: true,
                      unit: 'lbs')
                ]))));
  }
  if (name == 'roles') {
    return Builder(
        builder: (context) => Scaffold(
            body: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reference labels', style: AppText.sectionHeading()),
                      for (final color in [
                        context.surface.bgBase,
                        context.surface.bgSurface,
                        context.surface.surface2,
                        context.surface.surface3,
                        context.surface.surface4
                      ])
                        Container(
                            color: color,
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            child: Text('PREVIOUS · 24 SEP · Local processing',
                                style: AppText.caption(
                                    color: context.surface.textTertiary))),
                      const TextField(
                          decoration:
                              InputDecoration(hintText: 'Workout name')),
                      const SizedBox(height: 12),
                      const AsyncErrorState(message: 'Could not load history.')
                    ]))));
  }
  return Builder(
      builder: (context) => Scaffold(
          body: Center(
              child: TextButton(
                  onPressed: () {
                    showFinishSummarySheet(
                        context: context,
                        duration: const Duration(minutes: 24),
                        volumeKg:
                            fixtureSummary(name.substring(7)).weightedVolumeKg,
                        metricSummary: fixtureSummary(name.substring(7)),
                        sets: 1,
                        unit: 'lbs',
                        initialName: 'Push A');
                  },
                  child: const Text('Open summary')))));
}

Widget fixtureApp(String name, ThemePalette palette, double scale,
        {Key? captureKey}) =>
    ProviderScope(
        overrides: [
          authProvider.overrideWithValue(null),
          weightUnitProvider.overrideWithValue('lbs'),
          isPremiumProvider.overrideWithValue(true),
          workoutDetailProvider('fixture').overrideWith((ref) => name ==
                  'detail-error'
              ? Stream.error(StateError('synthetic read error'))
              : Stream.value(name == 'detail-empty' ? null : fixtureWorkout)),
          exerciseAnalyticsProvider((42, '6M'))
              .overrideWith((ref) => Stream.value([
                    ExerciseHistoryData(
                        date: fixtureDate,
                        weight: 80,
                        bestSetWeight: 80,
                        reps: 7,
                        estimated1RM:
                            name == 'exercise-no-estimate' ? null : 100,
                        volume: 560)
                  ]))
        ],
        child: RepaintBoundary(
            key: captureKey,
            child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: buildAppTheme(palette.tokens, palette: palette),
                builder: (context, child) => MediaQuery(
                    // Existing SkeletonPulse creates a lazy ticker during disposal when
                    // reduced motion skips initialization. Detail fixtures use normal motion;
                    // that separate baseline defect is recorded rather than suppressed.
                    data: MediaQuery.of(context).copyWith(
                        textScaler: TextScaler.linear(scale),
                        disableAnimations: !name.startsWith('detail')),
                    child: child!),
                home: fixtureBody(name))));
