// Guards the Explore catalog against broken exercise references.
//
// Every _TemplateSlot in explore_routines_screen.dart names an exact entry in
// the bundled Exercise Library (assets/db/exercises.json). This test parses the
// catalog's slot names straight from source and asserts each one exists — so a
// future typo or rename can never silently ship a routine that imports with
// missing exercises again.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every Explore catalog exercise exists in the library', () {
    final libraryNames = (jsonDecode(
      File('assets/db/exercises.json').readAsStringSync(),
    )['exercises'] as List)
        .map((e) => (e as Map)['name'] as String)
        .toSet();
    expect(libraryNames.length, greaterThan(400),
        reason: 'exercise library failed to load');

    final source = File(
      'lib/features/routines/presentation/screens/explore_routines_screen.dart',
    ).readAsStringSync();

    // Matches _TemplateSlot('Exact Name', ...). Names carry no quotes, so a
    // simple single-quote capture is exact.
    final slotPattern = RegExp(r"_TemplateSlot\('([^']+)'");
    final names =
        slotPattern.allMatches(source).map((m) => m.group(1)!).toList();

    expect(names.length, greaterThan(90),
        reason: 'catalog parse found too few slots — regex likely broke');

    final missing = names.where((n) => !libraryNames.contains(n)).toSet();
    expect(missing, isEmpty,
        reason: 'Explore references exercises absent from the library: '
            '${missing.join(", ")}');
  });
}
