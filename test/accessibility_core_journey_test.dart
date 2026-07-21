import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import 'package:gymlog/core/services/workout_draft_store.dart';
import 'package:gymlog/core/services/notification_service.dart';
import 'package:gymlog/features/workout/domain/active_workout_state.dart';
import 'package:gymlog/features/workout/presentation/providers/active_workout_provider.dart';
import 'package:gymlog/features/workout/presentation/providers/rest_timer_provider.dart';
import 'package:gymlog/features/workout/presentation/screens/active_workout_screen.dart';
import 'package:gymlog/features/workout/presentation/widgets/rest_timer_bar.dart';

class MockNotificationService extends NotificationService {
  @override
  Future<void> init() async {}
  @override
  Future<bool> requestPermissions() async => true;
  @override
  Future<bool> hasPermission() async => true;
  @override
  Future<void> scheduleRestTimerNotification({
    required String exerciseName,
    required DateTime endTime,
  }) async {}
  @override
  Future<void> cancelRestTimerNotification() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late Map<String, String> mockStorage;
  late WorkoutDraftStore store;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    mockStorage = <String, String>{};
    FlutterSecureStorage.setMockInitialValues(mockStorage);
    SharedPreferences.setMockInitialValues({});
    store = WorkoutDraftStore(const FlutterSecureStorage());
  });

  tearDown(() async {
    // Skipping db close to prevent FFI hangs on Windows
  });

  Future<void> setupAndPumpWorkout(
      WidgetTester tester, ProviderContainer container) async {
    final workoutNotifier = container.read(activeWorkoutProvider.notifier);
    await workoutNotifier.startWorkout(
      routineId: 'r1',
      name: 'Push Day',
      initialExercises: const [
        WorkoutExerciseState(
          id: 'ex-1',
          exerciseId: 1,
          name: 'Bench Press',
          sets: [
            WorkoutSetState(id: 's-1', reps: 10, weightKg: 100),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: ActiveWorkoutScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('SetRow interactive elements meet 48dp touch target requirements',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        workoutDraftStoreProvider.overrideWith((ref) => store),
        notificationServiceProvider
            .overrideWithValue(MockNotificationService()),
      ],
    );

    await setupAndPumpWorkout(tester, container);

    // Find Mark Completed check button detector
    final checkButton = find
        .ancestor(
          of: find.bySemanticsLabel('Complete set'),
          matching: find.byType(GestureDetector),
        )
        .first;

    // Find Set Type indicator button detector
    final typeButton = find
        .ancestor(
          of: find.bySemanticsLabel(RegExp(r'Set type.*')),
          matching: find.byType(GestureDetector),
        )
        .first;

    expect(checkButton, findsOneWidget);
    expect(typeButton, findsOneWidget);

    final checkSize = tester.getSize(checkButton);
    final typeSize = tester.getSize(typeButton);

    expect(checkSize.height, greaterThanOrEqualTo(48));
    expect(checkSize.width, greaterThanOrEqualTo(48));

    expect(typeSize.height, greaterThanOrEqualTo(48));
    expect(typeSize.width, greaterThanOrEqualTo(48));

    container.dispose();
  });

  testWidgets('RestOverrideChip meets 48dp touch target requirements',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        workoutDraftStoreProvider.overrideWith((ref) => store),
        notificationServiceProvider
            .overrideWithValue(MockNotificationService()),
      ],
    );

    await setupAndPumpWorkout(tester, container);

    final chipFinder = find.descendant(
      of: find.bySemanticsLabel(RegExp(r'Set rest duration override.*')),
      matching: find.byType(InkWell),
    );

    expect(chipFinder, findsOneWidget);
    final size = tester.getSize(chipFinder);

    expect(size.height, greaterThanOrEqualTo(48));
    expect(size.width, greaterThanOrEqualTo(48));

    container.dispose();
  });

  testWidgets('RestOverride sheet elements meet 48dp touch target requirements',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        workoutDraftStoreProvider.overrideWith((ref) => store),
        notificationServiceProvider
            .overrideWithValue(MockNotificationService()),
      ],
    );

    await setupAndPumpWorkout(tester, container);

    // Tap RestOverrideChip to open sheet
    final chipFinder = find.descendant(
      of: find.bySemanticsLabel(RegExp(r'Set rest duration override.*')),
      matching: find.byType(InkWell),
    );
    expect(chipFinder, findsOneWidget);
    await tester.tap(chipFinder);
    await tester.pumpAndSettle(); // Let bottom sheet slide up animation finish

    // Verify sheet title is visible
    expect(find.text('Rest Timer Override'), findsOneWidget);

    // Find adjustment buttons (+15s, -15s)
    final minus15 = find.widgetWithText(InkWell, '-15s');
    final plus15 = find.widgetWithText(InkWell, '+15s');

    expect(minus15, findsOneWidget);
    expect(plus15, findsOneWidget);

    final minusSize = tester.getSize(minus15);
    final plusSize = tester.getSize(plus15);

    expect(minusSize.height, greaterThanOrEqualTo(48));
    expect(plusSize.height, greaterThanOrEqualTo(48));

    // Find preset chips (e.g. '1:00', '0:30')
    final oneMinChip = find.widgetWithText(InkWell, '1:00');
    final thirtySecsChip = find.widgetWithText(InkWell, '0:30');

    expect(oneMinChip, findsOneWidget);
    expect(thirtySecsChip, findsOneWidget);

    final oneMinSize = tester.getSize(oneMinChip);
    final thirtySize = tester.getSize(thirtySecsChip);

    expect(oneMinSize.height, greaterThanOrEqualTo(48));
    expect(oneMinSize.width, greaterThanOrEqualTo(48));
    expect(thirtySize.height, greaterThanOrEqualTo(48));
    expect(thirtySize.width, greaterThanOrEqualTo(48));

    container.dispose();
  });

  testWidgets('RestTimerBar action buttons meet 48dp height requirement',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        workoutDraftStoreProvider.overrideWith((ref) => store),
        notificationServiceProvider
            .overrideWithValue(MockNotificationService()),
      ],
    );

    // Seed active timer
    container.read(restTimerProvider.notifier).start(
          seconds: 90,
          workoutId: 'w-1',
          exerciseId: 1,
          setId: 's-1',
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            bottomNavigationBar: Consumer(
              builder: (context, ref, child) {
                final state = ref.watch(restTimerProvider);
                if (state == null) return const SizedBox.shrink();
                return RestTimerBar(state: state);
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final plus15Finder = find.widgetWithText(InkWell, '+15s');
    final skipFinder = find.widgetWithText(InkWell, 'Skip');

    expect(plus15Finder, findsOneWidget);
    expect(skipFinder, findsOneWidget);

    final plus15Size = tester.getSize(plus15Finder);
    final skipSize = tester.getSize(skipFinder);

    expect(plus15Size.height, greaterThanOrEqualTo(48));
    expect(skipSize.height, greaterThanOrEqualTo(48));

    container.dispose();
  });

  testWidgets(
      'ActiveWorkoutScreen renders correctly at 200% text scale without overflow',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        workoutDraftStoreProvider.overrideWith((ref) => store),
        notificationServiceProvider
            .overrideWithValue(MockNotificationService()),
      ],
    );

    final workoutNotifier = container.read(activeWorkoutProvider.notifier);
    await workoutNotifier.startWorkout(
      routineId: 'r1',
      name: 'Push Day Extra Long Title That Might Wrap Under Text Scale',
      initialExercises: const [
        WorkoutExerciseState(
          id: 'ex-1',
          exerciseId: 1,
          name:
              'Bench Press With Extremely Long Description Exercise Name Column',
          sets: [
            WorkoutSetState(id: 's-1', reps: 10, weightKg: 100),
            WorkoutSetState(id: 's-2', reps: 8, weightKg: 102.5),
          ],
        ),
      ],
    );

    // Pump widget at 2.0 text scaling factor
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: ThemeData(),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(2.0),
              ),
              child: child!,
            );
          },
          home: const ActiveWorkoutScreen(),
        ),
      ),
    );

    await tester.pump();

    // Verify there are no layout exceptions or system errors
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Bench Press'), findsOneWidget);

    container.dispose();
  });
}
