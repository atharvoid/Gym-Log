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
    // Skipping database close to prevent FFI block on Windows
  });

  testWidgets('timer expiry does not trigger Set removed snackbar',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        workoutDraftStoreProvider.overrideWith((ref) => store),
        notificationServiceProvider
            .overrideWithValue(MockNotificationService()),
      ],
    );

    // Seed active workout
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

    // Verify workout is rendered and set is unchecked
    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('Set removed'), findsNothing);

    // Complete the first set via the UI tap to trigger the active rest timer
    final completeBtn = find.bySemanticsLabel('Complete set');
    expect(completeBtn, findsOneWidget);
    await tester.tap(completeBtn);
    await tester.pump();

    // Rest timer should be running
    final timerState = container.read(restTimerProvider);
    expect(timerState, isNotNull);

    // Manually expire the timer by resuming with an end time in the past
    container.read(restTimerProvider.notifier).resumeFromEndTime(
          endTime: DateTime.now().subtract(const Duration(seconds: 5)),
          totalSeconds: 90,
          workoutId: container.read(activeWorkoutProvider)!.id,
          exerciseId: 1,
          setId: 's-1',
        );
    await tester.pump();
    // Let the haptic delayed future finish
    await tester.pump(const Duration(milliseconds: 500));

    // Verify timer is expired (null)
    expect(container.read(restTimerProvider), isNull);

    // Verify NO 'Set removed' snackbar was shown
    expect(find.text('Set removed'), findsNothing);

    // Clean up workout and container to cancel all timers (like WorkoutTimer)
    workoutNotifier.discardWorkout();
    container.dispose();
  });
}
