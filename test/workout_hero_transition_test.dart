import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/database/daos/workouts_dao.dart';
import 'package:gymlog/features/home/presentation/widgets/workout_history_card.dart';
import 'package:gymlog/features/workout/presentation/widgets/workout_detail/hero_sliver.dart';

void main() {
  testWidgets(
      'WorkoutHistoryCard renders Hero when enableHero is true and animations enabled',
      (tester) async {
    final preview = WorkoutSessionPreview(
      session: WorkoutSession(
        id: 'session-123',
        startedAt: DateTime(2026, 6, 28, 12, 0),
        endedAt: DateTime(2026, 6, 28, 13, 0),
        totalVolumeKg: 1000,
        userId: 'user-1',
        notes: '',
        synced: false,
      ),
      duration: const Duration(hours: 1),
      totalVolumeKg: 1000,
      prCount: 0,
      topExercises: const [],
      totalExerciseCount: 0,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorkoutHistoryCard(
            preview: preview,
            enableHero: true,
          ),
        ),
      ),
    );

    final heroFinder = find.byType(Hero);
    expect(heroFinder, findsOneWidget);

    final hero = tester.widget<Hero>(heroFinder);
    expect(hero.tag, 'workout-hero-session-123');
  });

  testWidgets(
      'WorkoutHistoryCard does NOT render Hero when enableHero is false',
      (tester) async {
    final preview = WorkoutSessionPreview(
      session: WorkoutSession(
        id: 'session-123',
        startedAt: DateTime(2026, 6, 28, 12, 0),
        endedAt: DateTime(2026, 6, 28, 13, 0),
        totalVolumeKg: 1000,
        userId: 'user-1',
        notes: '',
        synced: false,
      ),
      duration: const Duration(hours: 1),
      totalVolumeKg: 1000,
      prCount: 0,
      topExercises: const [],
      totalExerciseCount: 0,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorkoutHistoryCard(
            preview: preview,
            enableHero: false,
          ),
        ),
      ),
    );

    expect(find.byType(Hero), findsNothing);
  });

  testWidgets(
      'WorkoutHeroSliver renders Hero when workoutId is present and animations enabled',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              WorkoutHeroSliver(
                workoutId: 'session-123',
                name: 'Workout Title',
                dateStr: 'Sun, 28 Jun',
                durationStr: '45 min',
                volumeStr: '1200 kg',
                totalSets: 12,
                onMoreTap: () {},
              ),
            ],
          ),
        ),
      ),
    );

    final heroFinder = find.byType(Hero);
    expect(heroFinder, findsOneWidget);

    final hero = tester.widget<Hero>(heroFinder);
    expect(hero.tag, 'workout-hero-session-123');
  });

  testWidgets('WorkoutHeroSliver does NOT render Hero when workoutId is null',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              WorkoutHeroSliver(
                workoutId: null,
                name: 'Workout Title',
                dateStr: 'Sun, 28 Jun',
                durationStr: '45 min',
                volumeStr: '1200 kg',
                totalSets: 12,
                onMoreTap: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(Hero), findsNothing);
  });
}
