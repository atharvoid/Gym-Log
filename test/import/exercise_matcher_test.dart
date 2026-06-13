import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/features/import/data/exercise_matcher.dart';

void main() {
  // Mixed naming conventions on purpose: library word-order vs Hevy parenthetical.
  final matcher = ExerciseMatcher(const [
    ExerciseRef(1, 'Barbell Bench Press'),
    ExerciseRef(2, 'Bench Press (Dumbbell)'),
    ExerciseRef(3, 'Triceps Pushdown (Cable - Rope)'),
    ExerciseRef(4, 'Face Pull (Cable)'),
  ]);

  test('exact match (case-insensitive)', () {
    expect(matcher.match('Barbell Bench Press'), 1);
    expect(matcher.match('bench press (dumbbell)'), 2);
  });

  test('word-order independent: parenthetical ↔ prefixed equipment', () {
    // "Bench Press (Barbell)" must reach the library's "Barbell Bench Press".
    expect(matcher.match('Bench Press (Barbell)'), 1);
    // and the reverse word order resolves the dumbbell variant.
    expect(matcher.match('Dumbbell Bench Press'), 2);
  });

  test('equipment is preserved (no cross-equipment link)', () {
    expect(matcher.match('Bench Press (Barbell)'), 1);
    expect(matcher.match('Bench Press (Dumbbell)'), 2);
    // Same movement, equipment we don't stock, and it's ambiguous → no link.
    expect(matcher.match('Bench Press (Smith Machine)'), isNull);
  });

  test('equipment-less import name links to the single movement match', () {
    expect(matcher.match('Triceps Pushdown'), 3);
    expect(matcher.match('Face Pull'), 4);
  });

  test('returns null when the movement is unknown', () {
    expect(matcher.match('Zercher Squat (Barbell)'), isNull);
    expect(matcher.match('Jefferson Curl'), isNull);
  });

  test('movementKey strips equipment and ignores word order', () {
    expect(ExerciseMatcher.movementKey('Barbell Bench Press'),
        ExerciseMatcher.movementKey('Bench Press (Barbell)'));
    expect(ExerciseMatcher.movementKey('Bench Press (Barbell)'), 'bench press');
  });

  test('equipFromName reads parenthetical or prefixed equipment', () {
    expect(ExerciseMatcher.equipFromName('Bench Press (Barbell)'), 'barbell');
    expect(ExerciseMatcher.equipFromName('Dumbbell Curl'), 'dumbbell');
    expect(ExerciseMatcher.equipFromName('Pull Up'), 'other');
  });
}
