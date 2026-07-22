import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/active_workout_state.dart';

sealed class ActiveWorkoutEvent {
  const ActiveWorkoutEvent();
}

class SetCompletedEvent extends ActiveWorkoutEvent {
  final int exerciseIndex;
  final int setIndex;
  final String setId;
  const SetCompletedEvent(this.exerciseIndex, this.setIndex, this.setId);
}

class TimerStartedEvent extends ActiveWorkoutEvent {
  final int seconds;
  final String workoutId;
  final int exerciseId;
  final String setId;
  final String? exerciseName;
  const TimerStartedEvent({
    required this.seconds,
    required this.workoutId,
    required this.exerciseId,
    required this.setId,
    this.exerciseName,
  });
}

class TimerExpiredEvent extends ActiveWorkoutEvent {
  final String workoutId;
  final int exerciseId;
  final String setId;
  final String? exerciseName;
  const TimerExpiredEvent({
    required this.workoutId,
    required this.exerciseId,
    required this.setId,
    this.exerciseName,
  });
}

class TimerCancelledEvent extends ActiveWorkoutEvent {
  const TimerCancelledEvent();
}

class SetRemovedEvent extends ActiveWorkoutEvent {
  final int exerciseIndex;
  final int setIndex;
  final WorkoutSetState removedSet;
  final RemovedSetSnapshot? snapshot;
  const SetRemovedEvent(this.exerciseIndex, this.setIndex, this.removedSet,
      {this.snapshot});
}

class ActiveWorkoutEventBus {
  final _controller = StreamController<ActiveWorkoutEvent>.broadcast();

  Stream<ActiveWorkoutEvent> get stream => _controller.stream;

  void fire(ActiveWorkoutEvent event) {
    if (!_controller.isClosed) {
      _controller.add(event);
    }
  }

  void dispose() {
    _controller.close();
  }
}

final workoutEventBusProvider = Provider<ActiveWorkoutEventBus>((ref) {
  final bus = ActiveWorkoutEventBus();
  ref.onDispose(() => bus.dispose());
  return bus;
});
