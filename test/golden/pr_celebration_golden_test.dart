@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/models/personal_record.dart';
import 'package:gymlog/features/workout/presentation/widgets/pr_celebration_overlay.dart';

import 'golden_test_helpers.dart';

List<PrRecord> buildPrs() => List.generate(
      4,
      (i) => PersonalRecord(
        type: PersonalRecordType.estimatedOneRepMax,
        exerciseId: i,
        exerciseName: 'Bench Press',
        value: 100 + i.toDouble(),
        unit: 'kg',
        setId: 's$i',
        previousValue: i == 0 ? null : 90 + i.toDouble(),
      ),
    );

void _noop() {}

Widget _card() => PrCelebrationCard(prs: buildPrs(), onKeepGoing: _noop);

void main() {
  goldenTest(
    'PrCelebrationCard renders per theme',
    fileName: 'pr_celebration_card',
    builder: () => allThemesGroup('PrCelebrationCard', _card()),
  );

  goldenTest(
    'PrCelebrationCard fits a short viewport with a bottom inset (3-button '
    'nav edge-to-edge) — Keep Going must stay on-screen',
    fileName: 'pr_celebration_card_small_viewport',
    builder: () => allThemesGroup(
      'PrCelebrationCard (320x568, bottom inset 24)',
      MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 568),
          viewPadding: EdgeInsets.only(bottom: 24),
        ),
        child: _card(),
      ),
    ),
  );
}
