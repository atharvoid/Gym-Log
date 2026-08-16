import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/features/routines/domain/routine_naming.dart';

void main() {
  group('cleanRoutineLabel', () {
    test('strips the generated "Day N -" prefix', () {
      expect(cleanRoutineLabel('Day 1 - Upper A'), 'Upper A');
      expect(cleanRoutineLabel('Day 12 - Lower B'), 'Lower B');
    });

    test('strips en dash, em dash and colon separators', () {
      expect(cleanRoutineLabel('Day 2 \u2013 Push'), 'Push');
      expect(cleanRoutineLabel('Day 2 \u2014 Push'), 'Push');
      expect(cleanRoutineLabel('Day 2: Push'), 'Push');
    });

    test('keeps parenthetical qualifiers', () {
      expect(
        cleanRoutineLabel('Day 3 - Full Body A (repeat)'),
        'Full Body A (repeat)',
      );
    });

    test('keeps a bare "Workout A1" -- the old regex missed this entirely', () {
      expect(cleanRoutineLabel('Workout A1'), 'Workout A1');
      expect(cleanRoutineLabel('Workout B'), 'Workout B');
    });

    test('strips a "Workout A1 -" prefix when a real name follows', () {
      expect(cleanRoutineLabel('Workout A1 - Push'), 'Push');
    });

    test('collapses whitespace and trims', () {
      expect(cleanRoutineLabel('  Day 4   -   Legs   B '), 'Legs B');
    });

    test('returns empty for empty input', () {
      expect(cleanRoutineLabel('   '), '');
    });
  });

  group('splitProgramName', () {
    test('drops the cadence suffix', () {
      final parts = splitProgramName('Push / Pull / Legs - 6 Days/Week');
      expect(parts.base, 'Push / Pull / Legs');
      expect(parts.variant, '');
    });

    test('preserves the equipment variant', () {
      final parts =
          splitProgramName('Starter Full Body - 3 Days/Week \u00b7 Dumbbell');
      expect(parts.base, 'Starter Full Body');
      expect(parts.variant, 'Dumbbell');
    });
  });

  group('programCadence', () {
    test('reads sessions per week from the catalog name', () {
      expect(programCadence('Push / Pull / Legs - 6 Days/Week'), 6);
      expect(programCadence('Starter Full Body - 3 Days/Week'), 3);
      expect(
        programCadence('Upper & Lower Body - 4 Days/Week \u00b7 Dumbbell'),
        4,
      );
    });

    test('returns null when the name carries no cadence', () {
      expect(programCadence('Some Program Without A Cadence'), isNull);
    });
  });

  group('programShortName', () {
    test('uses curated acronyms', () {
      expect(programShortName('Push / Pull / Legs - 6 Days/Week'), 'PPL');
      expect(
        programShortName('Upper & Lower Body - 4 Days/Week'),
        'Upper/Low',
      );
    });

    test('keeps equipment variants distinguishable', () {
      final gym = programShortName('Starter Full Body - 3 Days/Week');
      final dumbbell =
          programShortName('Starter Full Body - 3 Days/Week \u00b7 Dumbbell');
      final bodyweight = programShortName(
        'Starter Full Body - 3 Days/Week \u00b7 No Equipment',
      );

      expect(gym, 'Full Body');
      expect(dumbbell, 'Full Body DB');
      expect(bodyweight, 'Full Body BW');
      expect({gym, dumbbell, bodyweight}.length, 3);
    });

    test('regression: the DB suffix survives the cap on Upper/Lower', () {
      // 'Upper/Lower DB' is 14 chars and used to truncate to 'Upper/Lowe...',
      // silently dropping the variant marker this module exists to preserve.
      final dumbbell = programShortName(
        'Upper & Lower Body - 4 Days/Week \u00b7 Dumbbell',
      );
      expect(dumbbell, 'Upper/Low DB');
      expect(dumbbell.contains('DB'), isTrue);
      expect(dumbbell.contains('\u2026'), isFalse);
    });

    test('every curated name leaves room for an equipment suffix', () {
      for (final entry in kProgramShortNames.entries) {
        expect(
          entry.value.length,
          lessThanOrEqualTo(kMaxProgramShortNameLength - 3),
          reason: '${entry.key} -> ${entry.value} cannot fit " DB"',
        );
      }
    });

    test('never exceeds the short-name cap', () {
      for (final name in const [
        'Push / Pull / Legs - 6 Days/Week',
        'Upper & Lower Body - 4 Days/Week',
        'Starter Full Body - 3 Days/Week \u00b7 No Equipment',
        'Classic Push & Pull Split - 6 Days/Week',
        'Some Extremely Long Uncatalogued Program Name - 5 Days/Week',
      ]) {
        expect(
          programShortName(name).length,
          lessThanOrEqualTo(kMaxProgramShortNameLength),
          reason: name,
        );
      }
    });

    test('falls back to initials for long unknown programs', () {
      expect(
        programShortName('Some Extremely Long Uncatalogued Program Name'),
        'SELUPN',
      );
    });
  });

  group('uniqueProgramShortNames', () {
    test('adds cadence only where two programs actually collide', () {
      final labels = uniqueProgramShortNames(const [
        'Push / Pull / Legs - 6 Days/Week',
        'Push / Pull / Legs - 3 Days/Week',
        'Push / Pull / Legs - 6 Days/Week \u00b7 Dumbbell',
        'Upper & Lower Body - 4 Days/Week',
      ]);

      expect(labels['Push / Pull / Legs - 6 Days/Week'], 'PPL 6d');
      expect(labels['Push / Pull / Legs - 3 Days/Week'], 'PPL 3d');
      expect(labels['Push / Pull / Legs - 6 Days/Week \u00b7 Dumbbell'], 'PPL DB');
      expect(labels['Upper & Lower Body - 4 Days/Week'], 'Upper/Low');
    });

    test('leaves an unambiguous catalog untouched', () {
      final labels = uniqueProgramShortNames(const [
        'Push / Pull / Legs - 6 Days/Week',
        'Upper & Lower Body - 4 Days/Week',
      ]);

      expect(labels['Push / Pull / Legs - 6 Days/Week'], 'PPL');
      expect(labels['Upper & Lower Body - 4 Days/Week'], 'Upper/Low');
    });

    test('every resolved label is unique and within the cap', () {
      final labels = uniqueProgramShortNames(const [
        'Push / Pull / Legs - 6 Days/Week',
        'Push / Pull / Legs - 3 Days/Week',
        'Starter Full Body - 3 Days/Week',
        'Starter Full Body - 3 Days/Week \u00b7 Dumbbell',
        'Starter Full Body - 3 Days/Week \u00b7 No Equipment',
      ]);

      expect(labels.values.toSet().length, labels.length);
      for (final label in labels.values) {
        expect(label.length, lessThanOrEqualTo(kMaxProgramShortNameLength));
      }
    });

    test('preserves input order', () {
      final names = const [
        'Upper & Lower Body - 4 Days/Week',
        'Push / Pull / Legs - 6 Days/Week',
      ];
      expect(uniqueProgramShortNames(names).keys.toList(), names);
    });
  });

  group('routineDisplayName', () {
    test('produces a clean unprefixed name by default', () {
      expect(routineDisplayName(dayLabel: 'Day 1 - Upper A'), 'Upper A');
    });

    test('prefixes with the short name only when asked', () {
      expect(
        routineDisplayName(
          dayLabel: 'Day 1 - Upper A',
          programPrefix: 'Upper/Low',
          prefixWithProgram: true,
        ),
        'Upper/Low \u00b7 Upper A',
      );
    });

    test('never exceeds the routine name cap', () {
      final name = routineDisplayName(
        dayLabel: 'Day 1 - An Absurdly Long Day Label That Runs Forever',
        programPrefix: 'Upper/Low',
        prefixWithProgram: true,
      );
      expect(name.length, lessThanOrEqualTo(kMaxRoutineNameLength));
    });

    test('falls back to a safe name for empty labels', () {
      expect(routineDisplayName(dayLabel: '  '), 'Routine');
    });
  });

  group('routineSlug', () {
    test('builds a stable program/routine slug', () {
      expect(
        routineSlug(programSlug: 'ppl-6day-gym', dayLabel: 'Day 1 - Push A'),
        'ppl-6day-gym/push-a',
      );
    });

    test('is stable across separator styles', () {
      expect(
        routineSlug(programSlug: 'ppl-6day-gym', dayLabel: 'Day 1: Push A'),
        routineSlug(programSlug: 'ppl-6day-gym', dayLabel: 'Day 1 - Push A'),
      );
    });
  });

  group('dedupeRoutineNames', () {
    test('suffixes repeats and leaves uniques alone', () {
      expect(
        dedupeRoutineNames(['Push', 'Pull', 'Push', 'Legs', 'Push']),
        ['Push', 'Pull', 'Push 2', 'Legs', 'Push 3'],
      );
    });

    test('is case insensitive', () {
      expect(dedupeRoutineNames(['Push', 'push']), ['Push', 'push 2']);
    });
  });
}
