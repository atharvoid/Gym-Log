import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/exercises/muscle_taxonomy.dart';

void main() {
  test('parent groups exist and are ordered', () {
    expect(MuscleTaxonomy.parents, isNotEmpty);
    expect(MuscleTaxonomy.parents, containsAll(['Chest', 'Back', 'Shoulders']));
  });

  test('specific muscle resolves to its parent group', () {
    expect(MuscleTaxonomy.parentOf('Lats'), 'Back');
    expect(MuscleTaxonomy.parentOf('Lower Back'), 'Back');
    expect(MuscleTaxonomy.parentOf('Upper Chest'), 'Chest');
    expect(MuscleTaxonomy.parentOf('Rear Delts'), 'Shoulders');
    expect(MuscleTaxonomy.parentOf('Triceps'), 'Triceps');
  });

  test('specific muscle resolves to its coarse region', () {
    expect(MuscleTaxonomy.regionOf('Lats'), 'back');
    expect(MuscleTaxonomy.regionOf('Quadriceps'), 'legs');
    expect(MuscleTaxonomy.regionOf('Biceps'), 'arms');
    expect(MuscleTaxonomy.regionOf('Abdominals'), 'core');
  });

  test('parent → child lists are populated (e.g. Back)', () {
    final back = MuscleTaxonomy.childrenOf('Back');
    expect(back, containsAll(['Lats', 'Lower Back', 'Upper Back', 'Traps']));
  });

  test('unknown muscle falls back gracefully', () {
    expect(MuscleTaxonomy.parentOf('Made Up Muscle'), 'Other');
    expect(MuscleTaxonomy.regionOf('Made Up Muscle'), 'other');
  });
}
