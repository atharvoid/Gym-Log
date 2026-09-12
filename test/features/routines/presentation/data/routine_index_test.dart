import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/features/routines/presentation/data/explore_catalog.dart';
import 'package:gymlog/features/routines/presentation/data/routine_index.dart';

void main() {
  group('index shape', () {
    test('projects every program day into exactly one routine', () {
      final expected = exploreTemplates.fold<int>(
        0,
        (running, template) => running + template.days.length,
      );

      expect(expected, 70);
      expect(exploreRoutines.length, 70);
      expect(exploreRoutinesByProgramSlug.length, exploreTemplates.length);
      expect(exploreProgramBySlug.length, 16);
    });

    test('every program keeps all of its days, in order', () {
      for (final template in exploreTemplates) {
        final routines = routinesForProgram(programSlugFor(template));
        expect(routines.length, template.days.length, reason: template.name);

        for (var i = 0; i < routines.length; i++) {
          expect(routines[i].dayIndex, i);
          expect(routines[i].slots, same(template.days[i].slots));
        }
      }
    });

    test('slugs are unique, lowercase and addressable', () {
      final slugs = exploreRoutines.map((r) => r.slug).toList();
      expect(slugs.toSet().length, slugs.length);

      for (final slug in slugs) {
        expect(slug, equals(slug.toLowerCase()));
        expect(slug.split('/').length, 2, reason: slug);
        expect(slug, isNot(contains(' ')));
      }

      expect(
        exploreRoutineBySlug['linear-strength-builder-3-days-week/workout-a1'],
        isNotNull,
      );
      expect(
        exploreRoutineBySlug['upper-lower-body-4-days-week/upper-a'],
        isNotNull,
      );
    });
  });

  group('naming', () {
    test('no routine keeps generated day scaffolding', () {
      for (final routine in exploreRoutines) {
        expect(routine.name, isNotEmpty);
        expect(routine.name.startsWith('Day '), isFalse, reason: routine.slug);
        expect(routine.name, isNot(contains(' \u00b7 ')));
      }
    });

    test('fixes the reported Upper & Lower Body naming wall', () {
      final routines = routinesForProgram('upper-lower-body-4-days-week');

      expect(
        routines.map((r) => r.name).toList(),
        ['Upper A', 'Lower A', 'Upper B', 'Lower B'],
      );
      expect(routines.first.qualifiedName, 'Upper/Low \u00b7 Upper A');
    });

    test('program labels are unique across the whole catalog', () {
      final labels = exploreProgramLabels.values.toList();
      expect(labels.toSet().length, labels.length);
      expect(
          exploreProgramLabels['Push / Pull / Legs - 6 Days/Week'], 'PPL 6d');
      expect(
          exploreProgramLabels['Push / Pull / Legs - 3 Days/Week'], 'PPL 3d');
      expect(
        exploreProgramLabels[
            'Push / Pull / Legs - 6 Days/Week \u00b7 Dumbbell'],
        'PPL DB',
      );
    });

    test('routine names are unique within a program', () {
      for (final entry in exploreRoutinesByProgramSlug.entries) {
        final names = entry.value.map((r) => r.name.toLowerCase()).toList();
        expect(names.toSet().length, names.length, reason: entry.key);
      }
    });
  });

  group('duration', () {
    test('matches the program formula when every day is equal', () {
      final template = exploreTemplates.firstWhere(
        (t) => t.name == 'Starter Full Body - 3 Days/Week',
      );
      final routines = routinesForProgram(programSlugFor(template));

      expect(routines.map((r) => r.totalSets).toSet(), {17});
      for (final routine in routines) {
        expect(routine.estMinutes, template.estMinutes);
        expect(routine.estMinutes, 55);
      }
    });

    test('exposes the per-session spread the program average hid', () {
      final gzclp = exploreRoutineBySlug[
          'linear-strength-builder-3-days-week/workout-a1']!;
      final arnoldArms = exploreRoutineBySlug[
          'classic-push-pull-split-6-days-week/shoulders-arms-a']!;

      expect(gzclp.estMinutes, 45);
      expect(gzclp.duration, RoutineDuration.quick);
      expect(arnoldArms.estMinutes, 80);
      expect(arnoldArms.duration, RoutineDuration.long);
    });

    test('bands are contiguous and ordered', () {
      expect(durationBandFor(45), RoutineDuration.quick);
      expect(durationBandFor(50), RoutineDuration.standard);
      expect(durationBandFor(65), RoutineDuration.standard);
      expect(durationBandFor(70), RoutineDuration.long);
    });
  });

  group('slots', () {
    test('conditioning notes are excluded from the exercise count', () {
      final circuit =
          exploreRoutineBySlug['fat-loss-circuit-4-days-week/full-body-a']!;

      expect(circuit.slots.length, 7);
      expect(circuit.exerciseCount, 6);
      expect(circuit.conditioningNotes, ['Incline Treadmill / Bike Intervals']);
      expect(circuit.exerciseNames,
          isNot(contains('Incline Treadmill / Bike Intervals')));
    });

    test('every routine has at least one importable exercise', () {
      for (final routine in exploreRoutines) {
        expect(routine.exerciseCount, greaterThan(0), reason: routine.slug);
      }
    });
  });

  group('filtering', () {
    test('returns the whole catalog with no constraints', () {
      expect(filterExploreRoutines().length, 70);
    });

    test('filters by equipment', () {
      expect(
        filterExploreRoutines(
          equipment: {ProgramEquipment.bodyweight},
        ).length,
        13,
      );
      expect(
        filterExploreRoutines(
          equipment: {ProgramEquipment.dumbbellOnly},
        ).length,
        13,
      );
      expect(
        filterExploreRoutines(equipment: {ProgramEquipment.fullGym}).length,
        44,
      );
    });

    test('filters by level, matching any tagged tier', () {
      expect(
        filterExploreRoutines(levels: {TemplateLevel.beginner}).length,
        24,
      );
    });

    test('combines axes', () {
      final results = filterExploreRoutines(
        levels: {TemplateLevel.beginner},
        equipment: {ProgramEquipment.bodyweight},
      );

      expect(results, isNotEmpty);
      for (final routine in results) {
        expect(routine.equipment, ProgramEquipment.bodyweight);
        expect(routine.levels, contains(TemplateLevel.beginner));
      }
    });
  });

  group('search', () {
    test('finds a routine by an exercise buried inside it', () {
      final results = filterExploreRoutines(query: 'pistol');
      expect(results.length, 1);
      expect(results.single.exerciseNames, contains('Pistol Squat'));

      expect(filterExploreRoutines(query: 'goblet').length, 3);
    });

    test('matches on prefixes across multiple tokens', () {
      final results = filterExploreRoutines(query: 'push');
      expect(results, isNotEmpty);
      for (final routine in results) {
        expect(routine.matches('push'), isTrue);
      }
    });

    test('an empty query constrains nothing', () {
      expect(filterExploreRoutines(query: '   ').length, 70);
    });
  });

  group('catalog integrity', () {
    test('GZCLP is the only cadence mismatch in the catalog', () {
      final mismatches = programsWithCadenceMismatch();

      expect(
        mismatches.map((t) => t.name).toList(),
        ['Linear Strength Builder - 3 Days/Week'],
      );
      expect(mismatches.single.days.length, 4);
      expect(
          routinesForProgram('linear-strength-builder-3-days-week').length, 4);
    });
  });
}
