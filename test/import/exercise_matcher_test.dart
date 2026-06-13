import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/features/import/data/exercise_matcher.dart';

void main() {
  final matcher = ExerciseMatcher(const [
    ExerciseRef(1, 'Bench Press (Barbell)'),
    ExerciseRef(2, 'Bench Press (Dumbbell)'),
    ExerciseRef(3, 'Face Pull'),
    ExerciseRef(4, 'Single Arm Lateral Raise (Cable)'),
  ]);

  test('matches identical names', () {
    expect(matcher.match('Face Pull'), 3);
  });

  test('matches case-insensitively', () {
    expect(matcher.match('face pull'), 3);
  });

  test('matches despite punctuation/spacing differences', () {
    expect(matcher.match('Single-Arm  Lateral Raise (Cable)'), 4);
  });

  test('keeps equipment variants distinct (no cross-equipment collapse)', () {
    expect(matcher.match('Bench Press (Barbell)'), 1);
    expect(matcher.match('Bench Press (Dumbbell)'), 2);
  });

  test('returns null when there is no confident match', () {
    expect(matcher.match('Zercher Squat (Barbell)'), isNull);
    expect(matcher.match('Lower Chest Fly'), isNull);
  });

  test('normalize strips punctuation but preserves equipment words', () {
    expect(ExerciseMatcher.normalize('Bench Press (Dumbbell)'),
        'bench press dumbbell');
    expect(ExerciseMatcher.normalize('Single-Arm Lateral Raise (Cable)'),
        'single arm lateral raise cable');
  });
}
