import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/features/routines/domain/exercise_resolver.dart';

void main() {
  var nextId = 1;
  ResolvedExercise ex(
    String name, {
    String target = 'pectorals',
    List<String> secondary = const [],
  }) =>
      ResolvedExercise(
        id: nextId++,
        name: name,
        target: target,
        secondaryMuscles: secondary,
      );

  setUp(() => nextId = 1);

  group('normalisation', () {
    test('lowercases and strips punctuation', () {
      expect(normalizeExerciseName('Barbell Bench-Press!'),
          'barbell bench press');
    });

    test('base form drops the equipment parenthetical', () {
      expect(normalizeExerciseNameBase('Floor Press (Barbell)'), 'floor press');
      expect(normalizeExerciseNameBase('Standing Calf Raise (Machine)'),
          'standing calf raise');
    });
  });

  group('resolve', () {
    test('matches an exact name', () {
      final r = ExerciseResolver([ex('Barbell Bench Press')]);
      expect(r.resolve('Barbell Bench Press')!.name, 'Barbell Bench Press');
    });

    test('matches regardless of case and punctuation', () {
      final r = ExerciseResolver([ex('Barbell Bench Press')]);
      expect(r.resolve('  barbell   bench-press ')!.name,
          'Barbell Bench Press');
    });

    test('matches across an equipment parenthetical', () {
      final r = ExerciseResolver([ex('Floor Press')]);
      expect(r.resolve('Floor Press (Barbell)')!.name, 'Floor Press');
    });

    test('prefers the shortest qualifying candidate', () {
      final r = ExerciseResolver([
        ex('Close Grip Barbell Bench Press'),
        ex('Bench Press'),
        ex('Incline Barbell Bench Press'),
      ]);
      expect(r.resolve('Bench Press')!.name, 'Bench Press');
    });

    test('returns null rather than guessing wrong', () {
      final r = ExerciseResolver([ex('Barbell Squat')]);
      expect(r.resolve('Cable Woodchopper'), isNull);
      expect(r.resolve(''), isNull);
      expect(r.resolve('   '), isNull);
    });

    test('a single shared word is not enough to match', () {
      final r = ExerciseResolver([ex('Barbell Hip Thrust')]);
      expect(r.resolve('Barbell Curl'), isNull);
    });

    test('known aliases collapse onto one exercise', () {
      final r = ExerciseResolver(
        [ex('Inverted Row - Underhand')],
        aliases: const [
          ('Inverted Row with Underhand Grip', 'Inverted Row - Underhand'),
        ],
      );
      final a = r.resolve('Inverted Row with Underhand Grip');
      final b = r.resolve('Inverted Row - Underhand');
      expect(a, isNotNull);
      expect(a!.id, b!.id, reason: 'history must not split across spellings');
    });

    test('an alias pointing at nothing is ignored, not fatal', () {
      final r = ExerciseResolver(
        [ex('Barbell Squat')],
        aliases: const [('Ghost Lift A', 'Ghost Lift B')],
      );
      expect(r.resolve('Ghost Lift A'), isNull);
      expect(r.resolve('Barbell Squat'), isNotNull);
    });

    test('repeat lookups are memoised to the same instance', () {
      final r = ExerciseResolver([ex('Barbell Squat')]);
      expect(identical(r.resolve('Barbell Squat'), r.resolve('barbell squat')),
          isTrue);
    });

    test('an empty catalog resolves nothing without throwing', () {
      final r = ExerciseResolver([]);
      expect(r.resolve('Barbell Squat'), isNull);
      expect(r.indexedCount, 0);
    });
  });

  group('unresolvedNames', () {
    test('reports only the gaps', () {
      final r = ExerciseResolver([ex('Barbell Squat'), ex('Leg Press')]);
      expect(
        r.unresolvedNames(['Barbell Squat', 'Nordic Ham Curl', 'Leg Press']),
        ['Nordic Ham Curl'],
      );
    });
  });

  group('muscleProfileFor', () {
    test('a push day does not report leg muscles', () {
      final r = ExerciseResolver([
        ex('Barbell Bench Press', target: 'pectorals', secondary: ['triceps']),
        ex('Overhead Press', target: 'delts', secondary: ['triceps']),
      ]);
      final profile =
          r.muscleProfileFor(['Barbell Bench Press', 'Overhead Press']);
      expect(profile.primary, contains('Chest'));
      expect(profile.primary, contains('Shoulders'));
      expect(profile.primary, isNot(contains('Quadriceps')));
      expect(profile.primary, isNot(contains('Hamstrings')));
    });

    test('secondary never duplicates a primary group', () {
      final r = ExerciseResolver([
        ex('Barbell Bench Press', target: 'pectorals', secondary: ['triceps']),
        ex('Tricep Pushdown', target: 'triceps'),
      ]);
      final profile =
          r.muscleProfileFor(['Barbell Bench Press', 'Tricep Pushdown']);
      expect(profile.primary, contains('Triceps'));
      expect(profile.secondary, isNot(contains('Triceps')));
    });

    test('unresolvable slots are skipped, not fatal', () {
      final r = ExerciseResolver([ex('Barbell Squat', target: 'quads')]);
      final profile = r.muscleProfileFor(['Barbell Squat', 'Nordic Ham Curl']);
      expect(profile.primary, isNotEmpty);
    });

    test('an all-unresolvable day yields an empty profile', () {
      final r = ExerciseResolver([ex('Barbell Squat')]);
      final profile = r.muscleProfileFor(['Nordic Ham Curl']);
      expect(profile.primary, isEmpty);
      expect(profile.secondary, isEmpty);
    });

    test('two different days produce different profiles', () {
      final r = ExerciseResolver([
        ex('Barbell Bench Press', target: 'pectorals'),
        ex('Barbell Squat', target: 'quads'),
      ]);
      final push = r.muscleProfileFor(['Barbell Bench Press']);
      final legs = r.muscleProfileFor(['Barbell Squat']);
      expect(push.primary, isNot(equals(legs.primary)),
          reason: 'this is the whole point: per-routine, not per-program');
    });
  });

  group('exerciseIdsFor', () {
    test('returns ids in slot order and skips gaps', () {
      final a = ex('Barbell Squat');
      final b = ex('Leg Press');
      final r = ExerciseResolver([a, b]);
      expect(
        r.exerciseIdsFor(['Barbell Squat', 'Nordic Ham Curl', 'Leg Press']),
        [a.id, b.id],
      );
    });
  });
}
