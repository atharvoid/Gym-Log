import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/routines/program_membership.dart';

void main() {
  const sample = ProgramMembership(
    programSlug: 'push-pull-legs-6-days-week',
    programLabel: 'PPL 6d',
    orderIndex: 2,
    totalRoutines: 6,
    routineSlug: 'legs-a',
  );

  group('encode / decode', () {
    test('round-trips every field', () {
      final decoded = decodeProgramMembership(encodeProgramMembership(sample));
      expect(decoded, sample);
    });

    test('round-trips the migration undo field', () {
      const migrated = ProgramMembership(
        programSlug: 'upper-lower-body-4-days-week',
        programLabel: 'Upper/Low',
        orderIndex: 0,
        totalRoutines: 4,
        routineSlug: 'upper-a',
        importedAs: 'Upper & Lower Body · Upper A',
      );
      final decoded =
          decodeProgramMembership(encodeProgramMembership(migrated));
      expect(decoded, migrated);
      expect(decoded!.wasMigrated, isTrue);
      expect(decoded.importedAs, 'Upper & Lower Body · Upper A');
    });

    test('separator characters inside a label cannot corrupt the record', () {
      const nasty = ProgramMembership(
        programSlug: 'weird',
        programLabel: 'A; order=99; of=1 = B\nsecond line',
        orderIndex: 1,
        totalRoutines: 3,
        routineSlug: 'day-2',
      );
      final line = encodeProgramMembership(nasty);
      expect(line.split('\n').length, 1, reason: 'must stay a single line');
      final decoded = decodeProgramMembership(line);
      expect(decoded, nasty);
      expect(decoded!.orderIndex, 1, reason: 'injected order= must be ignored');
      expect(decoded.totalRoutines, 3);
    });

    test('day number is 1-based', () {
      expect(sample.dayNumber, 3);
    });
  });

  group('decode tolerance', () {
    test('returns null for standalone routines', () {
      expect(decodeProgramMembership(null), isNull);
      expect(decodeProgramMembership(''), isNull);
      expect(decodeProgramMembership('Felt strong today.'), isNull);
    });

    test('returns null instead of throwing on a malformed line', () {
      expect(decodeProgramMembership('gymlog:program:v1'), isNull);
      expect(decodeProgramMembership('gymlog:program:v1 garbage'), isNull);
      expect(
        decodeProgramMembership('gymlog:program:v1 slug=x; day=y'),
        isNull,
        reason: 'a missing order cannot be guessed',
      );
      expect(
        decodeProgramMembership('gymlog:program:v1 slug=x; order=0'),
        isNull,
        reason: 'a missing day slug cannot be guessed',
      );
      expect(
        decodeProgramMembership('gymlog:program:v1 slug=x; order=-1; day=y'),
        isNull,
      );
    });

    test('a missing total never reports a group smaller than reality', () {
      final decoded =
          decodeProgramMembership('gymlog:program:v1 slug=x; order=4; day=y');
      expect(decoded, isNotNull);
      expect(decoded!.totalRoutines, 5);
    });

    test('a nonsensical total is corrected upward', () {
      final decoded = decodeProgramMembership(
          'gymlog:program:v1 slug=x; order=4; of=2; day=y');
      expect(decoded!.totalRoutines, 5);
    });

    test('finds the record even when the user typed above it', () {
      final notes = 'My own note\n${encodeProgramMembership(sample)}';
      expect(decodeProgramMembership(notes), sample);
    });
  });

  group('notes handling', () {
    test('strips the metadata line from what the user sees', () {
      final notes = withProgramMembership('Deload week.', sample);
      expect(notes.contains(kProgramMetaTag), isTrue);
      expect(userVisibleNotes(notes), 'Deload week.');
    });

    test('user notes with no metadata are returned untouched', () {
      expect(userVisibleNotes('Just a note.'), 'Just a note.');
      expect(userVisibleNotes(null), '');
    });

    test('writing membership twice does not duplicate the line', () {
      var notes = withProgramMembership('Keep me.', sample);
      notes = withProgramMembership(notes, sample.copyWith(orderIndex: 5));
      final lines =
          notes.split('\n').where((l) => l.contains(kProgramMetaTag)).length;
      expect(lines, 1);
      expect(decodeProgramMembership(notes)!.orderIndex, 5);
      expect(userVisibleNotes(notes), 'Keep me.');
    });

    test('removing membership keeps the user note', () {
      final notes = withProgramMembership('Keep me.', sample);
      final stripped = withoutProgramMembership(notes);
      expect(hasProgramMembership(stripped), isFalse);
      expect(stripped, 'Keep me.');
    });

    test('clearing the undo field drops was= from the line', () {
      final migrated = sample.copyWith(importedAs: 'Old Name');
      expect(encodeProgramMembership(migrated).contains('was='), isTrue);
      final cleared = migrated.copyWith(clearImportedAs: true);
      expect(encodeProgramMembership(cleared).contains('was='), isFalse);
      expect(cleared.wasMigrated, isFalse);
    });
  });

  group('sortByProgramOrder', () {
    ProgramMembership at(int i) => sample.copyWith(orderIndex: i);

    test('puts training days back in ascending order', () {
      final shuffled = [at(5), at(0), at(3), at(1)];
      final sorted = sortByProgramOrder(shuffled, (m) => m);
      expect(sorted.map((m) => m.orderIndex).toList(), [0, 1, 3, 5]);
    });

    test('undecodable rows sort last in their original order', () {
      final items = <String>['bad-a', 'day-2', 'bad-b', 'day-1'];
      ProgramMembership? lookup(String s) => switch (s) {
            'day-1' => at(0),
            'day-2' => at(1),
            _ => null,
          };
      expect(sortByProgramOrder(items, lookup),
          ['day-1', 'day-2', 'bad-a', 'bad-b']);
    });

    test('is stable for equal order values', () {
      final items = <String>['a', 'b', 'c'];
      expect(sortByProgramOrder(items, (_) => at(0)), ['a', 'b', 'c']);
    });

    test('an empty list is fine', () {
      expect(sortByProgramOrder(<String>[], (_) => null), isEmpty);
    });
  });
}
