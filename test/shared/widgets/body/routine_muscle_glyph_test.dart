import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/exercises/body_map.dart';
import 'package:gymlog/shared/widgets/body/routine_muscle_glyph.dart';

void main() {
  group('routineGlyphZonesFor', () {
    test('a push routine lights chest, shoulders and arms -- not legs', () {
      final zones = routineGlyphZonesFor({'Chest', 'Shoulders', 'Triceps'});
      expect(zones, {
        RoutineGlyphZone.chest,
        RoutineGlyphZone.shoulders,
        RoutineGlyphZone.arms,
      });
      expect(zones.contains(RoutineGlyphZone.legs), isFalse);
    });

    test('a leg routine collapses every lower-body group into one zone', () {
      expect(
        routineGlyphZonesFor({'Quadriceps', 'Hamstrings', 'Glutes', 'Calves'}),
        {RoutineGlyphZone.legs},
      );
    });

    test('the Full Body sentinel lights everything', () {
      expect(
        routineGlyphZonesFor({'Full Body'}),
        RoutineGlyphZone.values.toSet(),
      );
    });

    test('unknown and unmapped groups are dropped, not thrown', () {
      expect(routineGlyphZonesFor({'Other', 'Neck', 'Nonsense'}), isEmpty);
    });

    test('empty in, empty out', () {
      expect(routineGlyphZonesFor(const <String>{}), isEmpty);
    });
  });

  group('integration with body_map', () {
    test('every mappable group name is a real body_map group', () {
      for (final group in kGroupToGlyphZone.keys) {
        expect(
          kGroupToParts.containsKey(group),
          isTrue,
          reason: '"$group" is not a group in kGroupToParts',
        );
      }
    });

    test('workedGroupsFor output feeds the glyph directly', () {
      final worked = workedGroupsFor(
        target: 'pectorals',
        secondary: const ['triceps', 'delts'],
      );

      expect(routineGlyphZonesFor(worked.primary), {RoutineGlyphZone.chest});
      expect(
        routineGlyphZonesFor(worked.secondary),
        {RoutineGlyphZone.arms, RoutineGlyphZone.shoulders},
      );
    });
  });

  group('routineGlyphSemanticLabel', () {
    test('names the trained groups', () {
      expect(
        routineGlyphSemanticLabel({'Chest', 'Back'}),
        'Trains back, chest',
      );
    });

    test('handles the full body sentinel and the empty case', () {
      expect(routineGlyphSemanticLabel({'Full Body'}), 'Trains the full body');
      expect(
        routineGlyphSemanticLabel(const <String>{}),
        'No muscle data for this routine',
      );
    });
  });
}
