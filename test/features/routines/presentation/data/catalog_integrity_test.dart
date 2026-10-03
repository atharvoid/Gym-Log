import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/features/routines/presentation/data/catalog_integrity.dart';
import 'package:gymlog/features/routines/presentation/data/explore_catalog.dart';
import 'package:gymlog/features/routines/presentation/data/routine_index.dart';

/// The equipment violations present in the catalog TODAY.
///
/// This is a pin, not an approval. Fix one upstream in the generator dataset
/// and delete its line; the test will tell you when the list is stale.
const Set<String> kKnownEquipmentViolations = {
  'starter-full-body-3-days-week-dumbbell/full-body-c | Floor Press (Barbell)',
  'push-pull-legs-6-days-week-dumbbell/push-b | Floor Press (Barbell)',
  'starter-full-body-3-days-week-no-equipment/full-body-a | '
      'Standing Calf Raise (Machine)',
  'push-pull-legs-6-days-week-no-equipment/legs-a | '
      'Standing Calf Raise (Machine)',
  'push-pull-legs-6-days-week-no-equipment/legs-b | '
      'Dumbbell Single Leg Calf Raise',
  'hiit-fat-loss-4-days-week-no-equipment/full-body-circuit-b | '
      'Standing Calf Raise (Machine)',
  'hiit-fat-loss-4-days-week-no-equipment/full-body-circuit-b-repeat | '
      'Standing Calf Raise (Machine)',
};

void main() {
  group('slotEquipmentFor', () {
    test('reads the parenthetical qualifier', () {
      expect(slotEquipmentFor('Bench Press (Barbell)'), SlotEquipment.barbell);
      expect(
        slotEquipmentFor('Incline Bench Press (Dumbbell)'),
        SlotEquipment.dumbbell,
      );
      expect(
        slotEquipmentFor('Standing Calf Raise (Machine)'),
        SlotEquipment.machine,
      );
      expect(
        slotEquipmentFor('Triceps Pushdown (Cable - Rope)'),
        SlotEquipment.cable,
      );
      expect(
        slotEquipmentFor('Bulgarian Split Squat (Bodyweight)'),
        SlotEquipment.bodyweight,
      );
    });

    test('reads a leading equipment word', () {
      expect(
        slotEquipmentFor('Dumbbell Single Leg Calf Raise'),
        SlotEquipment.dumbbell,
      );
      expect(slotEquipmentFor('Barbell Row'), SlotEquipment.barbell);
      expect(slotEquipmentFor('Cable Crunch'), SlotEquipment.cable);
    });

    test('treats an unmarked name as unspecified, never as a violation', () {
      for (final name in const [
        'Push Up',
        'Air Squat',
        'Towel Row',
        'Goblet Squat',
        'Pistol Squat',
        'Weighted Front Plank',
      ]) {
        expect(slotEquipmentFor(name), SlotEquipment.unspecified, reason: name);
      }
    });
  });

  group('allowedSlotEquipment', () {
    test('a full gym permits everything', () {
      expect(
        allowedSlotEquipment(ProgramEquipment.fullGym),
        containsAll(SlotEquipment.values),
      );
    });

    test('no-equipment programs permit no loaded equipment at all', () {
      final allowed = allowedSlotEquipment(ProgramEquipment.bodyweight);
      expect(allowed, isNot(contains(SlotEquipment.machine)));
      expect(allowed, isNot(contains(SlotEquipment.dumbbell)));
      expect(allowed, isNot(contains(SlotEquipment.barbell)));
      expect(allowed, isNot(contains(SlotEquipment.cable)));
    });

    test('dumbbell-only programs permit dumbbells but not barbells', () {
      final allowed = allowedSlotEquipment(ProgramEquipment.dumbbellOnly);
      expect(allowed, contains(SlotEquipment.dumbbell));
      expect(allowed, isNot(contains(SlotEquipment.barbell)));
      expect(allowed, isNot(contains(SlotEquipment.machine)));
    });
  });

  group('catalogEquipmentIssues', () {
    test('matches the pinned set exactly', () {
      final issues = catalogEquipmentIssues();
      final keys = issues.map((issue) => issue.key).toSet();

      expect(
        keys,
        kKnownEquipmentViolations,
        reason: 'Catalog equipment violations changed.\n'
            'Found:\n${issues.join('\n')}',
      );
      expect(issues.length, 7);
    });

    test('no full-gym program can ever be flagged', () {
      for (final issue in catalogEquipmentIssues()) {
        expect(issue.programEquipment, isNot(ProgramEquipment.fullGym));
      }
    });

    test('a no-equipment filter still hands the user a machine today', () {
      // The headline consequence, stated as a test so it cannot be lost in a
      // changelog: this is what the "No Equipment" filter currently returns.
      final bodyweightIssues = catalogEquipmentIssues()
          .where((i) => i.programEquipment == ProgramEquipment.bodyweight)
          .toList();

      expect(bodyweightIssues.length, 5);
      expect(
        bodyweightIssues.where((i) => i.slotEquipment == SlotEquipment.machine),
        hasLength(4),
      );
    });
  });

  group('duplicate exercise aliases', () {
    test('both spellings are still present, so the pin is still needed', () {
      final names = allCatalogExerciseNames().toSet();

      for (final (first, second) in kKnownDuplicateExerciseAliases) {
        expect(
          names,
          containsAll(<String>[first, second]),
          reason: 'Alias pair resolved upstream -- delete it from '
              'kKnownDuplicateExerciseAliases.',
        );
      }
    });

    test('the alias pair sits inside one program, splitting its history', () {
      final pullA = exploreRoutineBySlug[
          'push-pull-legs-6-days-week-no-equipment/pull-a']!;
      final pullB = exploreRoutineBySlug[
          'push-pull-legs-6-days-week-no-equipment/pull-b']!;

      expect(
        pullA.exerciseNames,
        contains('Inverted Row with Underhand Grip'),
      );
      expect(pullB.exerciseNames, contains('Inverted Row - Underhand'));
      expect(pullA.programName, pullB.programName);
    });
  });
}
