// P0-02 widget tests — set entry adapts cleanly to MeasurementType.
//
// Requirement coverage:
//   R1  Render only the fields required for the selected measurement type.
//   R2  "Complete set" action is stable in position and meaning.
//   R3  Explicit units; reps-only / duration / distance complete without weight.
//   R4  weightAndReps cannot complete with reps only — weight also required.
//   R5  Exercise switch resets incompatible draft fields.
//   R6  Inline validation: tapping check when incomplete does not call toggle.
//   R7  Double-tap prevention — completes exactly once.
//   R8  Focus order and keyboard actions are correct per type.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/models/measurement_type.dart';
import 'package:gymlog/features/workout/domain/active_workout_state.dart';
import 'package:gymlog/features/workout/presentation/widgets/set_row.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

Widget _host(SetRow row) => MaterialApp(home: Scaffold(body: row));

SetRow _row({
  MeasurementType type = MeasurementType.weightAndReps,
  WorkoutSetState? data,
  double? previousWeight,
  int? previousReps,
  String unit = 'kg',
  ValueChanged<WorkoutSetState>? onChanged,
  VoidCallback? onToggle,
  int index = 0,
}) =>
    SetRow(
      setIndex: index,
      setData: data ?? const WorkoutSetState(id: 'test-set'),
      measurementType: type,
      previousWeight: previousWeight,
      previousReps: previousReps,
      unit: unit,
      onChanged: onChanged ?? (_) {},
      onToggleComplete: onToggle ?? () {},
    );

/// Pump once to process synchronous state changes, then advance the fake clock
/// by 1.5 s to drain both pending timers introduced in P0-02:
///   • _completing reset  — fires after 400 ms
///   • _showValidationHint reset — fires after 1 400 ms
///
/// Call this after any tap on the check button to avoid the
/// `!timersPending` assertion that the Flutter test framework raises when a
/// testWidgets block exits with outstanding Future.delayed timers.
Future<void> _drainTimers(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1500));
}

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── R1: Field visibility per measurement type ───────────────────────────

  group('R1 — Field visibility', () {
    testWidgets('weightAndReps: both weight and reps fields visible',
        (tester) async {
      await tester.pumpWidget(_host(_row(type: MeasurementType.weightAndReps)));
      final fields =
          tester.widgetList<TextField>(find.byType(TextField)).toList();
      expect(fields.length, 2,
          reason: 'weightAndReps must render exactly 2 text fields');
    });

    testWidgets('repsOnly: weight field absent, reps field present',
        (tester) async {
      await tester.pumpWidget(_host(_row(type: MeasurementType.repsOnly)));
      final fields =
          tester.widgetList<TextField>(find.byType(TextField)).toList();
      expect(fields.length, 1,
          reason: 'repsOnly must render exactly 1 text field (reps only)');
    });

    testWidgets('duration: weight field absent, reps field present',
        (tester) async {
      await tester.pumpWidget(_host(_row(type: MeasurementType.duration)));
      final fields =
          tester.widgetList<TextField>(find.byType(TextField)).toList();
      expect(fields.length, 1,
          reason: 'duration must render exactly 1 text field (seconds)');
    });

    testWidgets('distance: weight-slot field present, reps field absent',
        (tester) async {
      await tester.pumpWidget(_host(_row(type: MeasurementType.distance)));
      final fields =
          tester.widgetList<TextField>(find.byType(TextField)).toList();
      expect(fields.length, 1,
          reason: 'distance must render exactly 1 text field (distance)');
    });

    testWidgets('check button is always present regardless of type',
        (tester) async {
      for (final type in MeasurementType.values) {
        await tester.pumpWidget(_host(_row(type: type)));
        expect(find.byIcon(Icons.check_rounded), findsOneWidget,
            reason: 'check button must exist for $type');
      }
    });
  });

  // ── R2: Completion action stable ─────────────────────────────────────────

  group('R2 — Stable completion action', () {
    testWidgets('tapping check never throws — even with empty required fields',
        (tester) async {
      for (final type in MeasurementType.values) {
        await tester.pumpWidget(_host(_row(type: type)));
        await tester.tap(find.byIcon(Icons.check_rounded));
        // Drain both possible pending timers before the next iteration.
        await _drainTimers(tester);
        expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      }
    });
  });

  // ── R3: Types that complete without weight ────────────────────────────────

  group('R3 — Reps-only / duration / distance complete without weight kg', () {
    testWidgets('repsOnly completes with reps only', (tester) async {
      var toggled = false;
      await tester.pumpWidget(_host(_row(
        type: MeasurementType.repsOnly,
        data: const WorkoutSetState(id: 's', reps: 10),
        onToggle: () => toggled = true,
      )));

      await tester.tap(find.byIcon(Icons.check_rounded));
      await _drainTimers(tester);
      expect(toggled, isTrue);
    });

    testWidgets('duration completes with reps (seconds) only', (tester) async {
      var toggled = false;
      await tester.pumpWidget(_host(_row(
        type: MeasurementType.duration,
        data: const WorkoutSetState(id: 's', reps: 60),
        onToggle: () => toggled = true,
      )));

      await tester.tap(find.byIcon(Icons.check_rounded));
      await _drainTimers(tester);
      expect(toggled, isTrue);
    });

    testWidgets('distance completes with distance (weightKg) only',
        (tester) async {
      var toggled = false;
      await tester.pumpWidget(_host(_row(
        type: MeasurementType.distance,
        data: const WorkoutSetState(id: 's', weightKg: 400),
        onToggle: () => toggled = true,
      )));

      await tester.tap(find.byIcon(Icons.check_rounded));
      await _drainTimers(tester);
      expect(toggled, isTrue);
    });

    testWidgets('repsOnly completes when only previousReps is available',
        (tester) async {
      var toggled = false;
      await tester.pumpWidget(_host(_row(
        type: MeasurementType.repsOnly,
        previousReps: 12,
        onToggle: () => toggled = true,
      )));

      await tester.tap(find.byIcon(Icons.check_rounded));
      await _drainTimers(tester);
      expect(toggled, isTrue);
    });
  });

  // ── R4: weightAndReps requires both fields ────────────────────────────────

  group('R4 — weightAndReps requires weight AND reps', () {
    testWidgets('cannot complete with reps only (no weight, no previous)',
        (tester) async {
      var toggled = false;
      await tester.pumpWidget(_host(_row(
        type: MeasurementType.weightAndReps,
        data: const WorkoutSetState(id: 's', reps: 10),
        onToggle: () => toggled = true,
      )));

      await tester.tap(find.byIcon(Icons.check_rounded));
      await _drainTimers(tester); // drains the validation-flash timer
      expect(toggled, isFalse,
          reason: 'weightAndReps must not complete with reps only');
    });

    testWidgets('cannot complete with weight only (no reps, no previous)',
        (tester) async {
      var toggled = false;
      await tester.pumpWidget(_host(_row(
        type: MeasurementType.weightAndReps,
        data: const WorkoutSetState(id: 's', weightKg: 60),
        onToggle: () => toggled = true,
      )));

      await tester.tap(find.byIcon(Icons.check_rounded));
      await _drainTimers(tester);
      expect(toggled, isFalse,
          reason: 'weightAndReps must not complete with weight only');
    });

    testWidgets('completes with both weight and reps present', (tester) async {
      var toggled = false;
      await tester.pumpWidget(_host(_row(
        type: MeasurementType.weightAndReps,
        data: const WorkoutSetState(id: 's', weightKg: 60, reps: 10),
        onToggle: () => toggled = true,
      )));

      await tester.tap(find.byIcon(Icons.check_rounded));
      await _drainTimers(tester);
      expect(toggled, isTrue);
    });

    testWidgets(
        'completes when previousWeight satisfies the weight requirement',
        (tester) async {
      var toggled = false;
      await tester.pumpWidget(_host(_row(
        type: MeasurementType.weightAndReps,
        data: const WorkoutSetState(id: 's', reps: 10),
        previousWeight: 60.0,
        onToggle: () => toggled = true,
      )));

      await tester.tap(find.byIcon(Icons.check_rounded));
      await _drainTimers(tester);
      expect(toggled, isTrue);
    });
  });

  // ── R5: Exercise switch clears incompatible fields ────────────────────────

  group('R5 — Exercise type switch', () {
    testWidgets(
        'switching from weightAndReps to repsOnly hides the weight field',
        (tester) async {
      const data = WorkoutSetState(id: 's', weightKg: 80, reps: 8);

      await tester.pumpWidget(_host(_row(
        type: MeasurementType.weightAndReps,
        data: data,
      )));
      expect(tester.widgetList<TextField>(find.byType(TextField)).length, 2);

      // Rebuild with repsOnly — same setData, different type.
      await tester.pumpWidget(_host(_row(
        type: MeasurementType.repsOnly,
        data: data,
      )));
      await tester.pump();

      expect(tester.widgetList<TextField>(find.byType(TextField)).length, 1);
    });

    testWidgets('switching from repsOnly to distance hides reps field',
        (tester) async {
      await tester.pumpWidget(_host(_row(
        type: MeasurementType.repsOnly,
        data: const WorkoutSetState(id: 's', reps: 10),
      )));

      await tester.pumpWidget(_host(_row(
        type: MeasurementType.distance,
        data: const WorkoutSetState(id: 's', reps: 10),
      )));
      await tester.pump();

      expect(tester.widgetList<TextField>(find.byType(TextField)).length, 1);
    });
  });

  // ── R6: Inline validation ─────────────────────────────────────────────────

  group('R6 — Inline validation', () {
    testWidgets(
        'tapping check with empty required fields does NOT call onToggleComplete',
        (tester) async {
      var toggled = false;
      await tester.pumpWidget(_host(_row(
        type: MeasurementType.weightAndReps,
        onToggle: () => toggled = true,
      )));

      await tester.tap(find.byIcon(Icons.check_rounded));
      await _drainTimers(tester); // drains the 1400ms validation-flash timer
      expect(toggled, isFalse);
    });

    testWidgets('widget survives validation tap without throwing',
        (tester) async {
      await tester.pumpWidget(_host(_row(
        type: MeasurementType.weightAndReps,
      )));

      await tester.tap(find.byIcon(Icons.check_rounded));
      await _drainTimers(tester);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });
  });

  // ── R7: Rapid-tap idempotency ─────────────────────────────────────────────

  group('R7 — Double-tap prevention', () {
    testWidgets('double-tap on completable set fires onToggleComplete once',
        (tester) async {
      var count = 0;
      await tester.pumpWidget(_host(_row(
        type: MeasurementType.repsOnly,
        data: const WorkoutSetState(id: 's', reps: 10),
        onToggle: () => count++,
      )));

      final check = find.byIcon(Icons.check_rounded);
      await tester.tap(check);
      await tester.pump(); // process first tap
      await tester.tap(check); // rapid second tap — within the 400ms guard
      await _drainTimers(tester); // drain the completing timer

      expect(count, 1, reason: 'rapid double-tap must complete exactly once');
    });
  });

  // ── R8: Keyboard and focus behaviour ─────────────────────────────────────

  group('R8 — Focus order and keyboard actions', () {
    testWidgets(
        'weightAndReps: weight has TextInputAction.next, reps has .done',
        (tester) async {
      await tester.pumpWidget(_host(_row(type: MeasurementType.weightAndReps)));

      final fields =
          tester.widgetList<TextField>(find.byType(TextField)).toList();
      expect(fields.length, 2);
      expect(fields[0].textInputAction, TextInputAction.next,
          reason: 'weight field should advance to reps');
      expect(fields[1].textInputAction, TextInputAction.done,
          reason: 'reps field should dismiss keyboard');
    });

    testWidgets('repsOnly: the single field has TextInputAction.done',
        (tester) async {
      await tester.pumpWidget(_host(_row(type: MeasurementType.repsOnly)));

      final fields =
          tester.widgetList<TextField>(find.byType(TextField)).toList();
      expect(fields.length, 1);
      expect(fields[0].textInputAction, TextInputAction.done);
    });

    testWidgets('duration: the single field has TextInputAction.done',
        (tester) async {
      await tester.pumpWidget(_host(_row(type: MeasurementType.duration)));

      final fields =
          tester.widgetList<TextField>(find.byType(TextField)).toList();
      expect(fields.length, 1);
      expect(fields[0].textInputAction, TextInputAction.done);
    });

    testWidgets(
        'distance: the single (weight-slot) field has TextInputAction.next',
        (tester) async {
      await tester.pumpWidget(_host(_row(type: MeasurementType.distance)));

      final fields =
          tester.widgetList<TextField>(find.byType(TextField)).toList();
      expect(fields.length, 1);
      expect(fields[0].textInputAction, TextInputAction.next);
    });
  });

  // ── Previous-session label formatting ─────────────────────────────────────

  group('Previous label formatting', () {
    testWidgets('weightAndReps shows "15kg x 12"', (tester) async {
      await tester.pumpWidget(_host(_row(
        type: MeasurementType.weightAndReps,
        previousWeight: 15,
        previousReps: 12,
      )));
      expect(find.text('15kg x 12'), findsOneWidget);
    });

    testWidgets('repsOnly shows "12 reps"', (tester) async {
      await tester.pumpWidget(_host(_row(
        type: MeasurementType.repsOnly,
        previousReps: 12,
      )));
      expect(find.text('12 reps'), findsOneWidget);
    });

    testWidgets('duration shows "60s"', (tester) async {
      await tester.pumpWidget(_host(_row(
        type: MeasurementType.duration,
        previousReps: 60,
      )));
      expect(find.text('60s'), findsOneWidget);
    });

    testWidgets('distance shows "400m"', (tester) async {
      await tester.pumpWidget(_host(_row(
        type: MeasurementType.distance,
        previousWeight: 400,
      )));
      expect(find.text('400m'), findsOneWidget);
    });

    testWidgets('no previous data renders empty string in PREVIOUS column',
        (tester) async {
      await tester.pumpWidget(_host(_row(type: MeasurementType.weightAndReps)));
      final texts = tester.widgetList<Text>(find.byType(Text));
      expect(texts.any((t) => t.data == ''), isTrue);
    });
  });

  // ── Previous-session backfill on completion ───────────────────────────────

  group('Previous-session backfill on complete', () {
    testWidgets('repsOnly: backfills previousReps into state', (tester) async {
      WorkoutSetState? captured;
      await tester.pumpWidget(_host(_row(
        type: MeasurementType.repsOnly,
        previousReps: 15,
        onChanged: (s) => captured = s,
        onToggle: () {},
      )));

      await tester.tap(find.byIcon(Icons.check_rounded));
      await _drainTimers(tester);
      expect(captured?.reps, 15);
    });

    testWidgets('weightAndReps: backfills both weight and reps',
        (tester) async {
      WorkoutSetState? captured;
      await tester.pumpWidget(_host(_row(
        type: MeasurementType.weightAndReps,
        previousWeight: 80,
        previousReps: 5,
        onChanged: (s) => captured = s,
        onToggle: () {},
      )));

      await tester.tap(find.byIcon(Icons.check_rounded));
      await _drainTimers(tester);
      expect(captured?.weightKg, 80.0);
      expect(captured?.reps, 5);
    });
  });
}
