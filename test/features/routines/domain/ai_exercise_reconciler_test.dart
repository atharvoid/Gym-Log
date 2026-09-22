import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/features/routines/domain/ai_import_models.dart';
import 'package:gymlog/features/routines/domain/ai_exercise_reconciler.dart';
import 'package:gymlog/features/routines/domain/exercise_resolver.dart';

void main() {
  final catalog = [
    const ResolvedExercise(
      id: 101,
      name: 'Incline Dumbbell Bench Press',
      target: 'pectorals',
      equipment: 'dumbbell',
      bodyPart: 'chest',
    ),
    const ResolvedExercise(
      id: 102,
      name: 'Barbell Bench Press',
      target: 'pectorals',
      equipment: 'barbell',
      bodyPart: 'chest',
    ),
    const ResolvedExercise(
      id: 103,
      name: 'Romanian Deadlift',
      target: 'hamstrings',
      equipment: 'barbell',
      bodyPart: 'upper legs',
    ),
    const ResolvedExercise(
      id: 104,
      name: 'Cable Lat Pulldown',
      target: 'lats',
      equipment: 'cable',
      bodyPart: 'back',
    ),
    const ResolvedExercise(
      id: 105,
      name: 'Overhead Press (Barbell)',
      target: 'delts',
      equipment: 'barbell',
      bodyPart: 'shoulders',
    ),
    const ResolvedExercise(
      id: 106,
      name: 'Lying Triceps Extension',
      target: 'triceps',
      equipment: 'barbell',
      bodyPart: 'arms',
    ),
    const ResolvedExercise(
      id: 107,
      name: 'Bicep Curl (Dumbbell)',
      target: 'biceps',
      equipment: 'dumbbell',
      bodyPart: 'arms',
    ),
    const ResolvedExercise(
      id: 108,
      name: 'Crossbody Cable Triceps Extension',
      target: 'triceps',
      equipment: 'cable',
      bodyPart: 'arms',
    ),
    const ResolvedExercise(
      id: 109,
      name: 'Triceps Pushdown (Cable - Rope)',
      target: 'triceps',
      equipment: 'cable',
      bodyPart: 'arms',
    ),
    const ResolvedExercise(
      id: 110,
      name: 'Single Arm Lateral Raise (Cable)',
      target: 'delts',
      equipment: 'cable',
      bodyPart: 'shoulders',
    ),
  ];

  late AiExerciseReconciler reconciler;

  setUp(() {
    reconciler = AiExerciseReconciler(catalog: catalog);
  });

  group('AiExerciseReconciler - Exercise Matching', () {
    test('resolves exact match to verified status', () {
      const input = RawExtractedExercise(
        rawName: 'Barbell Bench Press',
        sets: 3,
        reps: '10',
      );

      final result = reconciler.reconcileExercise(input);
      expect(result.status, ReconciliationStatus.verified);
      expect(result.matchedExerciseId, 102);
      expect(result.matchedExerciseName, 'Barbell Bench Press');
      expect(result.sets, 3);
      expect(result.isDefaultedSets, false);
      expect(result.defaultReps, 10);
    });

    test('resolves common gym acronyms and aliases via Tier 1 dictionary', () {
      // RDL -> Romanian Deadlift
      final rdl = reconciler.reconcileExercise(
        const RawExtractedExercise(rawName: 'RDL', sets: 4, reps: '8'),
      );
      expect(rdl.status, ReconciliationStatus.verified);
      expect(rdl.matchedExerciseId, 103);
      expect(rdl.matchedExerciseName, 'Romanian Deadlift');

      // OHP -> Overhead Press
      final ohp = reconciler.reconcileExercise(
        const RawExtractedExercise(rawName: 'OHP', sets: 3, reps: '5'),
      );
      expect(ohp.status, ReconciliationStatus.verified);
      expect(ohp.matchedExerciseId, 105);

      // Skullcrushers -> Lying Triceps Extension
      final skulls = reconciler.reconcileExercise(
        const RawExtractedExercise(
            rawName: 'Skullcrushers', sets: 3, reps: '12'),
      );
      expect(skulls.status, ReconciliationStatus.verified);
      expect(skulls.matchedExerciseId, 106);

      // Lat pulldown -> Cable Lat Pulldown
      final lat = reconciler.reconcileExercise(
        const RawExtractedExercise(
            rawName: 'Lat Pulldown', sets: 3, reps: '10'),
      );
      expect(lat.status, ReconciliationStatus.verified);
      expect(lat.matchedExerciseId, 104);
    });

    test('strictly preserves equipment isolation (DB vs Barbell)', () {
      final dbBench = reconciler.reconcileExercise(
        const RawExtractedExercise(
            rawName: 'Incline DB Bench', sets: 3, reps: '8-10'),
      );
      expect(dbBench.status, ReconciliationStatus.verified);
      expect(dbBench.matchedExerciseId, 101); // Incline Dumbbell Bench Press
      expect(
          dbBench.matchedExerciseId, isNot(102)); // Never Barbell Bench Press
    });

    test(
        'marks novel or non-existent exercises as unmatched without dropping them',
        () {
      final novel = reconciler.reconcileExercise(
        const RawExtractedExercise(
          rawName: 'Quantum Space Thrust',
          sets: 3,
          reps: '15',
        ),
      );
      expect(novel.status, ReconciliationStatus.unmatched);
      expect(novel.matchedExerciseId, isNull);
      expect(novel.rawName, 'Quantum Space Thrust');
      expect(novel.sets, 3);
      expect(novel.defaultReps, 15);
    });

    test(
        'strips coach styles and fuses compound words to match catalog (N1-Style Cross-Body Triceps Extension)',
        () {
      final ex = reconciler.reconcileExercise(
        const RawExtractedExercise(
          rawName: 'N1-Style Cross-Body Triceps Extension',
          sets: 2,
          reps: '10-12',
        ),
      );
      expect(ex.status, ReconciliationStatus.verified);
      expect(ex.matchedExerciseId, 108); // Crossbody Cable Triceps Extension
      expect(ex.displayName, 'Crossbody Cable Triceps Extension');
    });

    test(
        'strips muscle annotations and maps cable y-raise to catalog lateral raise',
        () {
      final ex = reconciler.reconcileExercise(
        const RawExtractedExercise(
          rawName: 'Cross-Body Cable Y-Raise (Side Delt)',
          sets: 3,
          reps: '12-15',
        ),
      );
      expect(ex.status, ReconciliationStatus.verified);
      expect(ex.matchedExerciseId, 110); // Single Arm Lateral Raise (Cable)
    });

    test('strips superset tags and duration from raw exercise names', () {
      final a1 = reconciler.reconcileExercise(
        const RawExtractedExercise(
          rawName: 'A1. Press-Around',
          sets: 2,
          reps: '12-15',
        ),
      );
      expect(a1.rawName, 'Press-Around');

      final a2 = reconciler.reconcileExercise(
        const RawExtractedExercise(
          rawName: 'A2. Pec Static Stretch 30s',
          sets: 2,
          reps: '30s HOLD',
        ),
      );
      expect(a2.rawName, 'Pec Static Stretch');
    });

    test(
        'provides intelligent catalog suggestions for near-miss lifts like Larsen Press',
        () {
      final larsen = reconciler.reconcileExercise(
        const RawExtractedExercise(
          rawName: 'Larsen Press',
          sets: 2,
          reps: '10',
        ),
      );
      expect(larsen.status, ReconciliationStatus.unmatched);
      expect(larsen.suggestions.isNotEmpty, true);
      expect(
        larsen.suggestions.any((s) => s.name == 'Barbell Bench Press'),
        true,
        reason: 'Larsen Press should suggest Barbell Bench Press as candidate',
      );
    });
  });

  group('AiExerciseReconciler - Numeric Sets & Reps & Weight Conversion', () {
    test('parses rep ranges by picking representative midpoint', () {
      final ex = reconciler.reconcileExercise(
        const RawExtractedExercise(
          rawName: 'Barbell Bench Press',
          sets: 3,
          reps: '8-12',
        ),
      );
      expect(ex.defaultReps, 10);
      expect(ex.rawReps, '8-12');
    });

    test('converts weight from lbs to kg when preferred unit is kg', () {
      final ex = reconciler.reconcileExercise(
        const RawExtractedExercise(
          rawName: 'Barbell Bench Press',
          sets: 3,
          reps: '5',
          weight: 225.0,
          weightUnit: 'lbs',
        ),
        targetUnit: 'kg',
      );
      // 225 lbs = 102.058 kg -> rounded to 102.0 kg
      expect(ex.defaultWeightKg, closeTo(102.0, 0.5));
    });

    test('preserves kg weight when target unit is kg', () {
      final ex = reconciler.reconcileExercise(
        const RawExtractedExercise(
          rawName: 'Barbell Bench Press',
          sets: 3,
          reps: '5',
          weight: 100.0,
          weightUnit: 'kg',
        ),
        targetUnit: 'kg',
      );
      expect(ex.defaultWeightKg, 100.0);
    });

    test('flags isDefaultedSets as true when sets is omitted in raw input', () {
      final ex = reconciler.reconcileExercise(
        const RawExtractedExercise(
          rawName: 'Barbell Bench Press',
          sets: null,
        ),
      );
      expect(ex.sets, 3);
      expect(ex.isDefaultedSets, true);
    });
  });

  group('AiExerciseReconciler - Multi-Day Routine Structure', () {
    test('reconciles multi-day routine preserving day groupings', () {
      const rawRoutine = RawExtractedRoutine(
        routineName: 'Upper / Lower Split',
        days: [
          RawExtractedDay(
            dayName: 'Day 1 - Upper',
            exercises: [
              RawExtractedExercise(
                  rawName: 'Barbell Bench Press', sets: 4, reps: '6'),
              RawExtractedExercise(
                  rawName: 'Lat Pulldown', sets: 4, reps: '10'),
            ],
          ),
          RawExtractedDay(
            dayName: 'Day 2 - Lower',
            exercises: [
              RawExtractedExercise(rawName: 'RDL', sets: 3, reps: '8'),
            ],
          ),
        ],
      );

      final reconciled = reconciler.reconcileRoutine(rawRoutine);
      expect(reconciled.routineName, 'Upper / Lower Split');
      expect(reconciled.days.length, 2);
      expect(reconciled.days[0].dayName, 'Day 1 - Upper');
      expect(reconciled.days[0].exercises.length, 2);
      expect(reconciled.days[0].exercises[0].matchedExerciseId, 102);
      expect(reconciled.days[1].dayName, 'Day 2 - Lower');
      expect(reconciled.days[1].exercises[0].matchedExerciseId, 103);
    });
  });
}
