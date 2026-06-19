// Guards the Explore catalog against broken exercise references.
//
// Every TemplateSlot in explore_catalog.dart names an exact entry in the
// bundled Exercise Library (assets/db/exercises.json). This test imports the
// TYPED catalog (no longer regex-scraping widget source) and asserts each slot
// name exists — so a future typo or rename can never silently ship a routine
// that imports with missing exercises.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/features/routines/presentation/data/explore_catalog.dart';

void main() {
  test('every Explore catalog exercise exists in the library', () {
    final libraryNames = (jsonDecode(
      File('assets/db/exercises.json').readAsStringSync(),
    )['exercises'] as List)
        .map((e) => (e as Map)['name'] as String)
        .toSet();
    expect(libraryNames.length, greaterThan(400),
        reason: 'exercise library failed to load');

    final names =
        exploreTemplates.expand((t) => t.slots).map((s) => s.name).toList();
    expect(names.length, greaterThan(90),
        reason: 'catalog has too few slots — did the data move?');

    final missing = names.where((n) => !libraryNames.contains(n)).toSet();
    expect(missing, isEmpty,
        reason: 'Explore references exercises absent from the library: '
            '${missing.join(", ")}');
  });

  test('every template is in a known category and is non-empty', () {
    for (final t in exploreTemplates) {
      expect(exploreCategoryOrder, contains(t.category),
          reason: '"${t.name}" has uncategorized section "${t.category}"');
      expect(t.slots, isNotEmpty, reason: '"${t.name}" has no exercises');
    }
  });
}
