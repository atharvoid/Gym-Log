import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/models/rest_preference.dart';
import 'package:gymlog/core/providers/settings_provider.dart';
import 'package:gymlog/core/services/workout_draft_store.dart';
import 'package:gymlog/features/workout/domain/active_workout_state.dart';
import 'package:gymlog/features/workout/presentation/providers/active_workout_provider.dart';
import 'package:gymlog/features/workout/presentation/widgets/exercise_block.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ATOMIC-01 RestPreference & Normalization Suite', () {
    late Map<String, String> mockStorage;
    late WorkoutDraftStore store;

    setUp(() {
      mockStorage = <String, String>{};
      FlutterSecureStorage.setMockInitialValues(mockStorage);
      store = WorkoutDraftStore(const FlutterSecureStorage());
    });

    // Test 1: Default maps to null.
    test('1. Default maps to null', () {
      const pref = RestPreference.useDefault();
      expect(restPreferenceToStorage(pref), isNull);
    });

    // Test 2: Disabled maps to zero.
    test('2. Disabled maps to zero', () {
      const pref = RestPreference.disabled();
      expect(restPreferenceToStorage(pref), equals(0));
    });

    // Test 3: Custom maps to positive seconds.
    test('3. Custom maps to positive seconds', () {
      const pref = RestPreference.custom(45);
      expect(restPreferenceToStorage(pref), equals(45));
    });

    // Test 4: Null restores Default.
    test('4. Null restores Default', () {
      final pref = restPreferenceFromStorage(null);
      expect(pref, isA<RestPreferenceUseGlobalDefault>());
      expect(isDefault(pref), isTrue);
    });

    // Test 5: Zero restores Disabled.
    test('5. Zero restores Disabled', () {
      final pref = restPreferenceFromStorage(0);
      expect(pref, isA<RestPreferenceDisabled>());
      expect(isOff(pref), isTrue);
    });

    // Test 6: Custom equal to global normalizes to Default.
    test('6. Custom equal to global normalizes to Default', () {
      const global = 90;
      const customSame = RestPreference.custom(90);
      final normalized = normalizeRestPreference(
        preference: customSame,
        globalSeconds: global,
      );
      expect(normalized, equals(const RestPreference.useDefault()));
      expect(isDefault(normalized), isTrue);

      const customBelowZero = RestPreference.custom(0);
      final normZero = normalizeRestPreference(
        preference: customBelowZero,
        globalSeconds: global,
      );
      expect(normZero, equals(const RestPreference.disabled()));

      const customClamped = RestPreference.custom(1000);
      final normClamped = normalizeRestPreference(
        preference: customClamped,
        globalSeconds: global,
      );
      expect(normClamped, equals(const RestPreference.custom(600)));
    });

    // Test 7: Exactly one selection predicate is true.
    test('7. Exactly one selection predicate is true', () {
      final testCases = <RestPreference>[
        const RestPreference.useDefault(),
        const RestPreference.disabled(),
        const RestPreference.custom(45),
        const RestPreference.custom(90),
      ];

      for (final pref in testCases) {
        for (final preset in [30, 45, 60, 90, 120]) {
          final predicates = [
            isDefault(pref),
            isOff(pref),
            isCustomPreset(pref, preset),
          ];
          final trueCount = predicates.where((b) => b).length;
          expect(trueCount, lessThanOrEqualTo(1),
              reason:
                  'Preference $pref with preset $preset should have at most 1 true predicate');
        }

        final statePredicates = [
          isDefault(pref),
          isOff(pref),
          pref is RestPreferenceCustomDuration,
        ];
        expect(statePredicates.where((b) => b).length, equals(1));
      }
    });

    // Test 8: No production widget contains visible text `None`.
    testWidgets('8. No production widget contains visible text None',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          workoutDraftStoreProvider.overrideWith((ref) => store),
          defaultRestSecondsProvider.overrideWith((ref) => 90),
          activeWorkoutProvider.overrideWith((ref) => ActiveWorkoutNotifier(ref)
            ..resumeDraft(ActiveWorkoutState(
              id: 'w-none-test',
              startTime: DateTime.now(),
              exercises: const [
                WorkoutExerciseState(
                  id: 'ex-1',
                  exerciseId: 101,
                  name: 'Bench Press',
                ),
              ],
            ))),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: ExerciseBlock(
                exerciseIndex: 0,
                onRemove: () {},
                onReplace: () {},
                onAddSet: () {},
                onRemoveSet: (_) {},
                onSetChanged: (_) {},
                onToggleSetCompletion: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('None'), findsNothing);

      // Open the sheet
      final chipFinder = find.bySemanticsLabel(RegExp(r'Set rest duration'));
      expect(chipFinder, findsOneWidget);
      await tester.tap(chipFinder);
      await tester.pumpAndSettle();

      // Ensure 'None' text is absent in production override sheet
      expect(find.text('None'), findsNothing);
    });

    // Test 9: Draft round trip preserves all three states.
    test('9. Draft round trip preserves all three states', () async {
      final workout = ActiveWorkoutState(
        id: 'w-rt-3',
        startTime: DateTime.now(),
        exercises: const [
          WorkoutExerciseState(
            id: 'ex-def',
            exerciseId: 1,
            name: 'Squat',
            restSecondsOverride: null, // Default
          ),
          WorkoutExerciseState(
            id: 'ex-off',
            exerciseId: 2,
            name: 'Deadlift',
            restSecondsOverride: 0, // Disabled
          ),
          WorkoutExerciseState(
            id: 'ex-custom',
            exerciseId: 3,
            name: 'Bench Press',
            restSecondsOverride: 45, // Custom
          ),
        ],
      );

      await store.save(workout, userId: 'user-rt');
      final loaded = await store.load(currentUserId: 'user-rt');

      expect(loaded, isNotNull);
      expect(loaded!.exercises.length, equals(3));
      expect(loaded.exercises[0].restPreference,
          equals(const RestPreference.useDefault()));
      expect(loaded.exercises[1].restPreference,
          equals(const RestPreference.disabled()));
      expect(loaded.exercises[2].restPreference,
          equals(const RestPreference.custom(45)));
    });

    // Test 10: Legacy stored values restore safely.
    test('10. Legacy stored values restore safely', () {
      final legacyNull = restPreferenceFromStorage(null);
      final legacyZero = restPreferenceFromStorage(0);
      final legacyNeg = restPreferenceFromStorage(-15);
      final legacyPos = restPreferenceFromStorage(120);

      expect(legacyNull, equals(const RestPreference.useDefault()));
      expect(legacyZero, equals(const RestPreference.disabled()));
      expect(legacyNeg, equals(const RestPreference.disabled()));
      expect(legacyPos, equals(const RestPreference.custom(120)));

      expect(resolveRestSeconds(preference: legacyNull, globalSeconds: 90), 90);
      expect(resolveRestSeconds(preference: legacyZero, globalSeconds: 90),
          isNull);
      expect(resolveRestSeconds(preference: legacyPos, globalSeconds: 90), 120);
    });
  });
}
