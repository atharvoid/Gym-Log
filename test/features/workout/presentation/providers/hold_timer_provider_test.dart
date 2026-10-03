import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymlog/features/workout/domain/hold_timer_state.dart';
import 'package:gymlog/features/workout/presentation/providers/hold_timer_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('HoldTimerNotifier Tests', () {
    test('starts in countdown mode when targetSeconds > 0', () {
      final notifier = container.read(holdTimerProvider.notifier);
      notifier.start(
        workoutId: 'w1',
        exerciseIndex: 0,
        setIndex: 0,
        setId: 's1',
        exerciseName: 'Plank',
        targetSeconds: 45,
        enablePrep: false,
      );

      final state = container.read(holdTimerProvider);
      expect(state, isNotNull);
      expect(state!.mode, HoldTimerMode.countdown);
      expect(state.phase, HoldTimerPhase.holding);
      expect(state.targetSeconds, 45);
      expect(state.displaySeconds, 45);
      expect(state.formattedTime, '0:45');
    });

    test('starts in stopwatch mode when targetSeconds is null or 0', () {
      final notifier = container.read(holdTimerProvider.notifier);
      notifier.start(
        workoutId: 'w1',
        exerciseIndex: 0,
        setIndex: 0,
        setId: 's1',
        exerciseName: 'Dead Hang',
        targetSeconds: null,
        enablePrep: false,
      );

      final state = container.read(holdTimerProvider);
      expect(state, isNotNull);
      expect(state!.mode, HoldTimerMode.stopwatch);
      expect(state.phase, HoldTimerPhase.holding);
      expect(state.elapsedSeconds, 0);
      expect(state.displaySeconds, 0);
      expect(state.formattedTime, '0:00');
    });

    test('starts in prep phase when enablePrep is true', () {
      final notifier = container.read(holdTimerProvider.notifier);
      notifier.start(
        workoutId: 'w1',
        exerciseIndex: 0,
        setIndex: 0,
        setId: 's1',
        exerciseName: 'Pec Stretch',
        targetSeconds: 30,
        enablePrep: true,
      );

      final state = container.read(holdTimerProvider);
      expect(state, isNotNull);
      expect(state!.phase, HoldTimerPhase.prep);
      expect(state.prepSecondsRemaining, 3);
      expect(state.isPrep, isTrue);
      expect(state.formattedTime, '3s');

      notifier.skipPrep();
      final updated = container.read(holdTimerProvider);
      expect(updated!.phase, HoldTimerPhase.holding);
      expect(updated.isPrep, isFalse);
    });

    test('pause and resume adjusts totalPausedDuration', () {
      final notifier = container.read(holdTimerProvider.notifier);
      notifier.start(
        workoutId: 'w1',
        exerciseIndex: 0,
        setIndex: 0,
        setId: 's1',
        exerciseName: 'Wall Sit',
        targetSeconds: 60,
        enablePrep: false,
      );

      notifier.pause();
      expect(container.read(holdTimerProvider)!.phase, HoldTimerPhase.paused);
      expect(container.read(holdTimerProvider)!.isPaused, isTrue);

      notifier.resume();
      expect(container.read(holdTimerProvider)!.phase, HoldTimerPhase.holding);
      expect(container.read(holdTimerProvider)!.isHolding, isTrue);
    });

    test('addSeconds adjusts target in countdown mode', () {
      final notifier = container.read(holdTimerProvider.notifier);
      notifier.start(
        workoutId: 'w1',
        exerciseIndex: 0,
        setIndex: 0,
        setId: 's1',
        exerciseName: 'Plank',
        targetSeconds: 45,
        enablePrep: false,
      );

      notifier.addSeconds(15);
      expect(container.read(holdTimerProvider)!.targetSeconds, 60);

      notifier.addSeconds(-10);
      expect(container.read(holdTimerProvider)!.targetSeconds, 50);
    });

    test('cancel clears timer state', () {
      final notifier = container.read(holdTimerProvider.notifier);
      notifier.start(
        workoutId: 'w1',
        exerciseIndex: 0,
        setIndex: 0,
        setId: 's1',
        exerciseName: 'Dead Hang',
        enablePrep: false,
      );

      expect(container.read(holdTimerProvider), isNotNull);
      notifier.cancel();
      expect(container.read(holdTimerProvider), isNull);
    });
  });
}
