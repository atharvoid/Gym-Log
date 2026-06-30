// Golden tests for the themed MuscleMap widget.
//
// Run once to generate baselines: flutter test --update-goldens test/golden/
// Subsequent runs diff against baselines: flutter test test/golden/
//
// @Tags(['golden'])
@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/theme/theme_palette.dart';
import 'package:gymlog/shared/widgets/body/muscle_map.dart';

import 'golden_test_helpers.dart';

void main() {
  goldenTest(
    'MuscleMap front-only male highlights Chest and Triceps',
    fileName: 'muscle_map_front_male',
    builder: () => allThemesGroup(
      'MuscleMap front male',
      const SizedBox(
        width: 200,
        child: MuscleMap(
          primaryGroups: {'Chest', 'Triceps'},
          secondaryGroups: {'Shoulders'},
          gender: 'male',
          showBack: false,
          showLegend: true,
        ),
      ),
    ),
  );

  goldenTest(
    'MuscleMap front+back female highlights Back and Biceps',
    fileName: 'muscle_map_full_female',
    builder: () => allThemesGroup(
      'MuscleMap full female',
      const SizedBox(
        width: 320,
        child: MuscleMap(
          primaryGroups: {'Back', 'Biceps'},
          secondaryGroups: {'Forearms'},
          gender: 'female',
          showBack: true,
          showLegend: true,
        ),
      ),
    ),
  );

  goldenTest(
    'MuscleMap recolors with the active accent (Volt vs Purple)',
    fileName: 'muscle_map_accent_compare',
    builder: () => GoldenTestGroup(
      scenarioConstraints: const BoxConstraints(maxWidth: 400),
      children: [
        GoldenTestScenario(
          name: 'Volt',
          child: gymlogApp(
            ThemePalette.higgsfield,
            const SizedBox(
              width: 160,
              child: MuscleMap(
                primaryGroups: {'Quadriceps', 'Calves'},
                secondaryGroups: {'Glutes'},
                gender: 'male',
                showBack: false,
              ),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'Purple',
          child: gymlogApp(
            ThemePalette.neonPurple,
            const SizedBox(
              width: 160,
              child: MuscleMap(
                primaryGroups: {'Quadriceps', 'Calves'},
                secondaryGroups: {'Glutes'},
                gender: 'male',
                showBack: false,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
