import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/exercises/muscle_split.dart';

void main() {
  group('groupMuscleSetsByParent', () {
    test('rolls specific muscles up into parent groups', () {
      final out = groupMuscleSetsByParent({
        'Upper Chest': 3,
        'Lower Chest': 2,
        'Lats': 4,
        'Triceps': 1,
      });
      expect(out, {'Chest': 5, 'Back': 4, 'Triceps': 1});
    });

    test('keeps unknown muscles under their own name (never dropped)', () {
      expect(groupMuscleSetsByParent({'Frobnicate': 2}), {'Frobnicate': 2});
    });

    test('ignores zero / negative counts', () {
      expect(groupMuscleSetsByParent({'Chest': 0, 'Lats': 3}), {'Back': 3});
    });
  });

  group('largestRemainderPercents', () {
    test('sums to exactly 100', () {
      for (final values in [
        [1, 1, 1],
        [5, 3, 2, 1],
        [7],
        [10, 10, 10, 10, 10, 10, 10],
      ]) {
        final p = largestRemainderPercents(values);
        expect(p.fold<int>(0, (a, b) => a + b), 100, reason: '$values');
      }
    });

    test('thirds round to 34/33/33', () {
      expect(largestRemainderPercents([1, 1, 1]), [34, 33, 33]);
    });

    test('clean ratios are exact', () {
      expect(largestRemainderPercents([3, 1]), [75, 25]);
    });

    test('non-positive total yields zeros', () {
      expect(largestRemainderPercents([0, 0]), [0, 0]);
    });
  });
}
