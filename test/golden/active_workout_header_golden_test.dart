@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/features/workout/presentation/widgets/active_workout_header.dart';

import 'golden_test_helpers.dart';

Widget _header() => SizedBox(
      width: 390,
      child: ActiveWorkoutHeader(
        isEditing: false,
        workoutName: 'Active Workout',
        elapsedTime: '00:12:34',
        volumeKg: 1250.0,
        completedSets: 8,
        weightUnit: 'kg',
        finishEnabled: true,
        onMinimize: () {},
        onClose: () {},
        onFinish: () {},
      ),
    );

Widget _headerLargeText() => MediaQuery(
      data: const MediaQueryData(
        size: Size(320, 568),
        textScaler: TextScaler.linear(2.0),
      ),
      child: SizedBox(
        width: 320,
        child: ActiveWorkoutHeader(
          isEditing: false,
          workoutName: 'Active Workout',
          elapsedTime: '00:12:34',
          volumeKg: 1250.0,
          completedSets: 8,
          weightUnit: 'kg',
          finishEnabled: true,
          onMinimize: () {},
          onClose: () {},
          onFinish: () {},
        ),
      ),
    );

void main() {
  goldenTest(
    'ActiveWorkoutHeader renders correctly per theme (normal layout)',
    fileName: 'active_workout_header_normal',
    builder: () => allThemesGroup(
      'ActiveWorkoutHeader (normal)',
      _header(),
    ),
  );

  goldenTest(
    'ActiveWorkoutHeader renders correctly per theme (large-text compact)',
    fileName: 'active_workout_header_large_text',
    builder: () => allThemesGroup(
      'ActiveWorkoutHeader (large-text)',
      _headerLargeText(),
    ),
  );
}
