// Golden tests for MuscleLoadBar across all six accent palettes.
//
// Run once to generate baselines: flutter test --update-goldens test/golden/
// Subsequent runs diff against baselines: flutter test test/golden/
// Baselines land under test/golden/goldens/<platform>/ (flutter_test_config).
//
// @Tags(['golden'])
@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/shared/widgets/body/muscle_load_bar.dart';

import 'golden_test_helpers.dart';

void main() {
  goldenTest(
    'MuscleLoadBar renders in all six accent palettes',
    fileName: 'muscle_load_bar_all_themes',
    builder: () => allThemesGroup(
      'MuscleLoadBar all themes',
      const SizedBox(
        width: 400,
        child: MuscleLoadBar(
          entries: [
            MuscleLoadEntry('chest', 0.5),
            MuscleLoadEntry('back', 0.3),
            MuscleLoadEntry('legs', 0.15),
            MuscleLoadEntry('arms', 0.05),
          ],
          primaryGroups: {'chest'},
          secondaryGroups: {'back', 'legs'},
          gender: 'male',
        ),
      ),
    ),
  );
}
