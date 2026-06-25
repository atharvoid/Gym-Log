// Seed golden test: renders SegmentedControl in all 6 accent themes.
// Proves the golden pipeline works. Any pixel drift → red test → caught before
// you ever see it.
//
// Run once to generate baselines:  flutter test --update-goldens test/golden/
// Subsequent runs diff against baselines:  flutter test test/golden/
//
// @Tags(['golden'])
@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/shared/widgets/ui/segmented_control.dart';

import 'golden_test_helpers.dart';

void main() {
  goldenTest(
    'SegmentedControl renders correctly per theme',
    fileName: 'segmented_control_all_themes',
    builder: () => allThemesGroup(
      'SegmentedControl',
      SizedBox(
        width: 320,
        child: SegmentedControl(
          segments: const ['All', 'Beginner', 'Intermediate', 'Advanced'],
          selected: 'Beginner',
          onChanged: (_) {},
        ),
      ),
    ),
  );
}
