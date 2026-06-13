// Validates the bundled unified catalog (assets/db/exercises.json) and proves
// end-to-end that real Hevy/Strong export names LINK to it (instead of creating
// duplicate custom exercises).

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/exercises/muscle_taxonomy.dart';
import 'package:gymlog/features/import/data/exercise_matcher.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Map<String, dynamic>> ex;

  setUpAll(() async {
    final raw = await rootBundle.loadString('assets/db/exercises.json');
    ex = ((jsonDecode(raw) as Map<String, dynamic>)['exercises'] as List)
        .cast<Map<String, dynamic>>();
  });

  test('catalog is large and well-formed', () {
    expect(ex.length, greaterThan(800));
    for (final e in ex) {
      expect((e['name'] as String).trim(), isNotEmpty);
      expect((e['bodyPart'] as String).trim(), isNotEmpty);
      expect((e['equipment'] as String).trim(), isNotEmpty);
      expect((e['target'] as String).trim(), isNotEmpty);
    }
  });

  test('every exerciseDbId is unique', () {
    final ids = ex.map((e) => e['id'] as String).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('GIF invariant: only real ExerciseDB ids carry a GIF', () {
    for (final e in ex) {
      final hasGif = e['gif'] == true;
      final id = e['id'] as String;
      // Synthetic ids (no GIF yet) are prefixed "g"; real ExerciseDB ids are numeric.
      if (hasGif) expect(id.startsWith('g'), isFalse, reason: '$id should be real');
      if (id.startsWith('g')) expect(hasGif, isFalse, reason: '$id must have no GIF');
    }
  });

  test('every primary muscle is covered by the taxonomy', () {
    final uncovered = <String>{};
    for (final e in ex) {
      if (MuscleTaxonomy.parentOf(e['target'] as String) == 'Other') {
        uncovered.add(e['target'] as String);
      }
    }
    expect(uncovered, isEmpty, reason: 'targets missing from taxonomy: $uncovered');
  });

  test('real Hevy/Strong export names LINK to the catalog (no duplicates)', () {
    // Build the matcher exactly as the import service does.
    final matcher = ExerciseMatcher([
      for (var i = 0; i < ex.length; i++) ExerciseRef(i, ex[i]['name'] as String),
    ]);

    const sampleNames = [
      'Incline Bench Press (Dumbbell)',
      'Bench Press (Dumbbell)',
      'Lower Chest Fly',
      'Seated Overhead Press (Barbell)',
      'Shoulder Press (Dumbbell)',
      'Triceps Pushdown',
      'Single Arm Lateral Raise (Cable)',
      'Face Pull',
      // Strong word-order variants must also link to the same catalog.
      'Barbell Bench Press',
      'Dumbbell Shrug',
    ];

    for (final n in sampleNames) {
      expect(matcher.match(n), isNotNull, reason: '"$n" should link, not duplicate');
    }
  });
}
