// Guards the Explore catalog against broken exercise references.
//
// Every non-conditioning-note TemplateSlot across every ProgramDay of every
// RoutineTemplate names an exact entry in the bundled Exercise Library
// (assets/db/exercises.json). This test imports the TYPED catalog and
// asserts each importable slot name exists, so a future typo or rename can
// never silently ship a program that imports with missing exercises.
// Conditioning-note slots (e.g. "Incline Treadmill Intervals") are
// deliberately excluded -- they render as a manual-log badge in the UI
// rather than an exercise lookup, by design.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/features/routines/presentation/data/explore_catalog.dart';

void main() {
  test('every importable Explore catalog exercise exists in the library', () {
    final libraryNames = (jsonDecode(
      File('assets/db/exercises.json').readAsStringSync(),
    )['exercises'] as List)
        .map((e) => (e as Map)['name'] as String)
        .toSet();
    expect(libraryNames.length, greaterThan(400),
        reason: 'exercise library failed to load');

    final importableNames = exploreTemplates
        .expand((t) => t.days)
        .expand((d) => d.importableSlots)
        .map((s) => s.name)
        .toList();
    expect(importableNames.length, greaterThan(300),
        reason: 'catalog has too few importable slots -- did the data move?');

    final missing =
        importableNames.where((n) => !libraryNames.contains(n)).toSet();
    expect(missing, isEmpty,
        reason: 'Explore references exercises absent from the library: '
            '${missing.join(", ")}');
  });

  test('conditioning-note slots are intentionally excluded from lookup', () {
    final noteNames = exploreTemplates
        .expand((t) => t.days)
        .expand((d) => d.slots)
        .where((s) => s.isConditioningNote)
        .map((s) => s.name)
        .toSet();
    // A generous ceiling, not a target -- this catches an accidental mass
    // mis-flag (e.g. every slot in a day marked as a note by mistake), while
    // still allowing legitimate conditioning-note gaps like interval work.
    expect(noteNames.length, lessThan(20),
        reason: 'unexpectedly many conditioning-note slots: '
            '${noteNames.join(", ")}');
  });

  test('every template is in a known category, non-empty, and well-formed', () {
    for (final t in exploreTemplates) {
      expect(exploreCategoryOrder, contains(t.category),
          reason: '"${t.name}" has uncategorized section "${t.category}"');
      expect(t.days, isNotEmpty, reason: '"${t.name}" has no days');
      expect(t.totalSlots, greaterThan(0),
          reason: '"${t.name}" has no exercises across any day');
      expect(t.levels, isNotEmpty, reason: '"${t.name}" has no assigned level');
      for (final day in t.days) {
        expect(day.slots, isNotEmpty,
            reason: '"${t.name}" has an empty day "${day.label}"');
      }
    }
  });
}
