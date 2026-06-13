import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/features/import/domain/import_models.dart';
import 'package:gymlog/features/import/data/workout_csv_parser.dart';

import 'import_fixtures.dart';

double _volume(ImportParseResult r) =>
    r.sessions.fold(0.0, (s, x) => s + x.totalVolumeKg);

int _sets(ImportParseResult r) =>
    r.sessions.fold(0, (s, x) => s + x.setCount);

int _warmups(ImportParseResult r) => r.sessions.fold(
      0,
      (s, x) =>
          s +
          x.exercises.fold(
            0,
            (a, e) => a + e.sets.where((st) => st.setType == SetTypes.warmup).length,
          ),
    );

void main() {
  group('Hevy', () {
    test('parses sessions, sets, and kg volume from a real export', () {
      // Prepend a BOM to also exercise BOM stripping.
      final r = WorkoutCsvParser.parse('\u{FEFF}$hevySampleCsv');
      expect(r.source, ImportSource.hevy);
      expect(r.sessions.length, 2);
      expect(_sets(r), 22);
      expect(_volume(r), closeTo(9483.0, 0.01));
      expect(r.weightUnitAssumed, isFalse);
    });

    test('respects the explicit set_type column (no warmups here)', () {
      // The two "Warmup" tokens live in exercise_notes, not set_type, so Hevy
      // keeps them as normal sets — exactly as the app recorded them.
      final r = WorkoutCsvParser.parse(hevySampleCsv);
      expect(_warmups(r), 0);
    });

    test('orders sets 0-based and contiguous within each exercise', () {
      final r = WorkoutCsvParser.parse(hevySampleCsv);
      final chest =
          r.sessions.firstWhere((s) => s.name == 'Monday Chest Day');
      final incline = chest.exercises.first;
      expect(incline.name, 'Incline Bench Press (Dumbbell)');
      expect(incline.sets.map((s) => s.orderIndex), [0, 1, 2]);
    });

    test('reads weight_lbs header variant and converts to kg', () {
      const csv = 'title,start_time,exercise_title,set_index,set_type,'
          'weight_lbs,reps\n'
          'W,"30 Jun 2025, 19:56",Bench,0,normal,100,5';
      final r = WorkoutCsvParser.parse(csv);
      expect(r.assumedUnit, 'lbs');
      expect(r.sessions.single.exercises.single.sets.single.weightKg,
          closeTo(45.359237, 0.0001));
    });
  });

  group('Strong', () {
    test('parses semicolon export and converts lbs → kg', () {
      final r = WorkoutCsvParser.parse(strongSampleCsv);
      expect(r.source, ImportSource.strong);
      expect(r.sessions.length, 2);
      expect(_sets(r), 22);
      expect(_volume(r), closeTo(9481.31, 0.5));
    });

    test('infers warmups from the Notes column', () {
      final r = WorkoutCsvParser.parse(strongSampleCsv);
      expect(_warmups(r), 2);
    });

    test('derives session end time from Workout Duration', () {
      final r = WorkoutCsvParser.parse(strongSampleCsv);
      final s = r.sessions.firstWhere((x) => x.name == 'Monday Chest Day');
      expect(s.endedAt, isNotNull);
      expect(s.endedAt!.difference(s.startedAt), const Duration(minutes: 62));
    });

    test('flags an assumed unit when Weight Unit column is missing', () {
      const csv = 'Date;Workout Name;Exercise Name;Set Order;Weight;Reps\n'
          '2025-06-30 19:56:00;W;Squat;1;100;5';
      final r = WorkoutCsvParser.parse(csv, assumedStrongUnit: 'lbs');
      expect(r.weightUnitAssumed, isTrue);
      expect(r.assumedUnit, 'lbs');
      expect(r.sessions.single.exercises.single.sets.single.weightKg,
          closeTo(45.359237, 0.0001));
    });
  });

  group('cross-check', () {
    test('Hevy and Strong files describe the same training volume', () {
      final hevy = _volume(WorkoutCsvParser.parse(hevySampleCsv));
      final strong = _volume(WorkoutCsvParser.parse(strongSampleCsv));
      // Difference is only Strong rounding lbs to one decimal.
      expect((hevy - strong).abs() / hevy, lessThan(0.01));
    });
  });

  group('errors', () {
    test('throws on an unrecognised header', () {
      expect(
        () => WorkoutCsvParser.parse('foo,bar,baz\n1,2,3'),
        throwsA(isA<ImportException>()),
      );
    });

    test('throws on an empty file', () {
      expect(() => WorkoutCsvParser.parse('   '),
          throwsA(isA<ImportException>()));
    });
  });
}
