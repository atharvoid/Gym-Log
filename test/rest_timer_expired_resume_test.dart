import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/services/notification_service.dart';
import 'package:gymlog/features/workout/presentation/providers/rest_timer_provider.dart';
import 'package:gymlog/features/workout/presentation/providers/workout_event_provider.dart';

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

  test('resumeFromEndTime with an expired endTime fires TimerExpiredEvent',
      () async {
    final container = ProviderContainer(
      overrides: [
        notificationServiceProvider
            .overrideWithValue(MockNotificationService()),
      ],
    );
    addTearDown(container.dispose);

    final expired = <TimerExpiredEvent>[];
    final sub = container.read(workoutEventBusProvider).stream.listen((event) {
      if (event is TimerExpiredEvent) expired.add(event);
    });
    addTearDown(sub.cancel);

    container.read(restTimerProvider.notifier).resumeFromEndTime(
          endTime: DateTime.now().subtract(const Duration(seconds: 5)),
          totalSeconds: 90,
          workoutId: 'w-1',
          exerciseId: 1,
          setId: 's-1',
        );

    // Stream delivery is asynchronous; flush the microtask queue.
    await Future<void>.delayed(Duration.zero);

    expect(container.read(restTimerProvider), isNull, reason: 'timer cleared');
    expect(expired, hasLength(1), reason: 'expiry must fire TimerExpiredEvent');
    expect(expired.single.workoutId, 'w-1');
    expect(expired.single.exerciseId, 1);
    expect(expired.single.setId, 's-1');

    // Let the haptic delayed future (double buzz) run to completion so no
    // pending timers leak into the next test.
    await Future<void>.delayed(
      const Duration(milliseconds: 400),
      () => HapticFeedback.heavyImpact(),
    );
  });
}
