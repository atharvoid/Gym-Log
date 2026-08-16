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

  group('programShortName', () {
    test('uses curated acronyms', () {
      expect(programShortName('Push / Pull / Legs - 6 Days/Week'), 'PPL');
      expect(
        programShortName('Upper & Lower Body - 4 Days/Week'),
        'Upper/Lower',
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

  group('routineDisplayName', () {
    test('produces a clean unprefixed name by default', () {
      expect(routineDisplayName(dayLabel: 'Day 1 - Upper A'), 'Upper A');
    });

    test('prefixes with the short name only when asked', () {
      expect(
        routineDisplayName(
          dayLabel: 'Day 1 - Upper A',
          programPrefix: 'Upper/Lower',
          prefixWithProgram: true,
        ),
        'Upper/Lower \u00b7 Upper A',
      );
    });

    test('never exceeds the routine name cap', () {
      final name = routineDisplayName(
        dayLabel: 'Day 1 - An Absurdly Long Day Label That Runs Forever',
        programPrefix: 'Upper/Lower',
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
