import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/features/routines/presentation/data/explore_catalog.dart';
import 'package:gymlog/features/routines/presentation/data/routine_index.dart';
import 'package:gymlog/features/routines/presentation/providers/explore_providers.dart';

void main() {
  group('equipment capability', () {
    test('a full gym can perform everything', () {
      expect(performableWith(ProgramEquipment.fullGym),
          ProgramEquipment.values.toSet());
    });

    test('dumbbells can also perform bodyweight', () {
      expect(performableWith(ProgramEquipment.dumbbellOnly), {
        ProgramEquipment.dumbbellOnly,
        ProgramEquipment.bodyweight,
      });
    });

    test('bodyweight is the floor', () {
      expect(performableWith(ProgramEquipment.bodyweight),
          {ProgramEquipment.bodyweight});
    });

    test('owning more equipment never shows less', () {
      final gym = applyExploreFilters(
        exploreRoutines,
        const ExploreFilters(equipment: ProgramEquipment.fullGym),
      );
      final dumbbell = applyExploreFilters(
        exploreRoutines,
        const ExploreFilters(equipment: ProgramEquipment.dumbbellOnly),
      );
      final bodyweight = applyExploreFilters(
        exploreRoutines,
        const ExploreFilters(equipment: ProgramEquipment.bodyweight),
      );
      expect(gym.length, greaterThanOrEqualTo(dumbbell.length));
      expect(dumbbell.length, greaterThanOrEqualTo(bodyweight.length));
      expect(gym.length, exploreRoutines.length,
          reason: 'a full gym hides nothing');
    });
  });

  group('applyExploreFilters', () {
    test('no filters returns everything', () {
      expect(applyExploreFilters(exploreRoutines, const ExploreFilters()).length,
          exploreRoutines.length);
    });

    test('an empty filter set is reported as empty', () {
      expect(const ExploreFilters().isEmpty, isTrue);
      expect(const ExploreFilters().activeCount, 0);
    });

    test('search finds routines by exercise name', () {
      final results = applyExploreFilters(
        exploreRoutines,
        const ExploreFilters(query: 'pistol'),
      );
      expect(results, isNotEmpty,
          reason: 'searching an exercise used to return nothing');
    });

    test('a nonsense query returns nothing rather than everything', () {
      final results = applyExploreFilters(
        exploreRoutines,
        const ExploreFilters(query: 'zzzzqqqq'),
      );
      expect(results, isEmpty);
    });

    test('level filter keeps only matching routines', () {
      final beginner = applyExploreFilters(
        exploreRoutines,
        const ExploreFilters(levels: {TemplateLevel.beginner}),
      );
      expect(beginner, isNotEmpty);
      expect(
        beginner.every((r) => r.levels.contains(TemplateLevel.beginner)),
        isTrue,
      );
    });

    test('duration filter keeps only matching bands', () {
      final quick = applyExploreFilters(
        exploreRoutines,
        const ExploreFilters(durations: {RoutineDuration.quick}),
      );
      expect(quick.every((r) => r.duration == RoutineDuration.quick), isTrue);
    });

    test('filters compose', () {
      final combined = applyExploreFilters(
        exploreRoutines,
        const ExploreFilters(
          levels: {TemplateLevel.beginner},
          equipment: ProgramEquipment.bodyweight,
        ),
      );
      for (final r in combined) {
        expect(r.levels.contains(TemplateLevel.beginner), isTrue);
        expect(r.equipment, ProgramEquipment.bodyweight);
      }
    });

    test('activeCount tracks how many constraints are on', () {
      const filters = ExploreFilters(
        query: 'push',
        levels: {TemplateLevel.beginner},
        equipment: ProgramEquipment.fullGym,
      );
      expect(filters.activeCount, 3);
      expect(filters.isEmpty, isFalse);
    });

    test('clearing equipment removes the constraint', () {
      const filters = ExploreFilters(equipment: ProgramEquipment.bodyweight);
      expect(filters.copyWith(clearEquipment: true).equipment, isNull);
    });
  });
}
