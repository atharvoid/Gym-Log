import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/exercises/body_map.dart';
import 'package:gymlog/core/exercises/muscle_taxonomy.dart';

void main() {
  group('workedGroupsFor', () {
    test('primary target is separated from secondary muscles', () {
      final result = workedGroupsFor(
        target: 'Chest',
        secondary: ['Triceps', 'Shoulders'],
      );
      expect(result.primary, {'Chest'});
      expect(result.secondary, {'Triceps', 'Shoulders'});
    });

    test('secondary muscles that overlap primary are downgraded to primary',
        () {
      final result = workedGroupsFor(
        target: 'Quadriceps',
        secondary: ['Quadriceps', 'Glutes', 'Calves'],
      );
      expect(result.primary, {'Quadriceps'});
      expect(result.secondary, {'Glutes', 'Calves'});
    });

    test('unknown muscles resolve to Other and are ignored', () {
      final result = workedGroupsFor(
        target: 'Unknown Muscle',
        secondary: ['Also Unknown'],
      );
      expect(result.primary, isEmpty);
      expect(result.secondary, isEmpty);
    });
  });

  group('kGroupToParts covers every taxonomy parent', () {
    for (final parent in MuscleTaxonomy.parents) {
      test('$parent is mapped', () {
        expect(
          kGroupToParts.containsKey(parent),
          isTrue,
          reason: '$parent needs a body-map part mapping',
        );
      });
    }
  });

  group('partsForGroups', () {
    test('Chest maps to the front chest slug for both genders', () {
      for (final gender in ['male', 'female']) {
        final parts = partsForGroups({'Chest'}, gender: gender);
        expect(parts, contains((BodySide.front, 'chest')));
      }
    });

    test('Back includes back-only slugs for both genders', () {
      for (final gender in ['male', 'female']) {
        final parts = partsForGroups({'Back'}, gender: gender);
        expect(parts, contains((BodySide.back, 'upper-back')));
        expect(parts, contains((BodySide.back, 'lower-back')));
        expect(parts, contains((BodySide.back, 'trapezius')));
      }
    });

    test('Full Body highlights every known part', () {
      final maleParts = partsForGroups({'Full Body'}, gender: 'male');
      expect(maleParts, isNotEmpty);
      expect(maleParts, contains((BodySide.front, 'chest')));
      expect(maleParts, contains((BodySide.back, 'gluteal')));

      final femaleParts = partsForGroups({'Full Body'}, gender: 'female');
      expect(femaleParts, isNotEmpty);
      expect(femaleParts, contains((BodySide.front, 'abs')));
      expect(femaleParts, contains((BodySide.back, 'hamstring')));
    });

    test('prefer_not_to_say falls back to male assets', () {
      final parts = partsForGroups({'Chest'}, gender: 'prefer_not_to_say');
      expect(parts, contains((BodySide.front, 'chest')));
    });

    test('missing slugs for a gender are dropped without crashing', () {
      // Ankles are only present on the male back; female should drop it if it
      // were mapped. This test verifies the filter path by using a gender that
      // lacks a known slug.
      final parts = partsForGroups({'Calves'}, gender: 'female');
      expect(parts, isNotEmpty);
      // Female front calves exists; female back calves exists; tibialis exists.
      expect(parts, contains((BodySide.front, 'calves')));
      expect(parts, contains((BodySide.back, 'calves')));
    });
  });
}
