// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'active_workout_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$WorkoutSetState {
  String get id => throw _privateConstructorUsedError;
  String get setType => throw _privateConstructorUsedError;
  double get weightKg => throw _privateConstructorUsedError;
  int get reps => throw _privateConstructorUsedError;
  bool get isCompleted => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $WorkoutSetStateCopyWith<WorkoutSetState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkoutSetStateCopyWith<$Res> {
  factory $WorkoutSetStateCopyWith(
          WorkoutSetState value, $Res Function(WorkoutSetState) then) =
      _$WorkoutSetStateCopyWithImpl<$Res, WorkoutSetState>;
  @useResult
  $Res call(
      {String id, String setType, double weightKg, int reps, bool isCompleted});
}

/// @nodoc
class _$WorkoutSetStateCopyWithImpl<$Res, $Val extends WorkoutSetState>
    implements $WorkoutSetStateCopyWith<$Res> {
  _$WorkoutSetStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? setType = null,
    Object? weightKg = null,
    Object? reps = null,
    Object? isCompleted = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      setType: null == setType
          ? _value.setType
          : setType // ignore: cast_nullable_to_non_nullable
              as String,
      weightKg: null == weightKg
          ? _value.weightKg
          : weightKg // ignore: cast_nullable_to_non_nullable
              as double,
      reps: null == reps
          ? _value.reps
          : reps // ignore: cast_nullable_to_non_nullable
              as int,
      isCompleted: null == isCompleted
          ? _value.isCompleted
          : isCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WorkoutSetStateImplCopyWith<$Res>
    implements $WorkoutSetStateCopyWith<$Res> {
  factory _$$WorkoutSetStateImplCopyWith(_$WorkoutSetStateImpl value,
          $Res Function(_$WorkoutSetStateImpl) then) =
      __$$WorkoutSetStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id, String setType, double weightKg, int reps, bool isCompleted});
}

/// @nodoc
class __$$WorkoutSetStateImplCopyWithImpl<$Res>
    extends _$WorkoutSetStateCopyWithImpl<$Res, _$WorkoutSetStateImpl>
    implements _$$WorkoutSetStateImplCopyWith<$Res> {
  __$$WorkoutSetStateImplCopyWithImpl(
      _$WorkoutSetStateImpl _value, $Res Function(_$WorkoutSetStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? setType = null,
    Object? weightKg = null,
    Object? reps = null,
    Object? isCompleted = null,
  }) {
    return _then(_$WorkoutSetStateImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      setType: null == setType
          ? _value.setType
          : setType // ignore: cast_nullable_to_non_nullable
              as String,
      weightKg: null == weightKg
          ? _value.weightKg
          : weightKg // ignore: cast_nullable_to_non_nullable
              as double,
      reps: null == reps
          ? _value.reps
          : reps // ignore: cast_nullable_to_non_nullable
              as int,
      isCompleted: null == isCompleted
          ? _value.isCompleted
          : isCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$WorkoutSetStateImpl implements _WorkoutSetState {
  const _$WorkoutSetStateImpl(
      {this.id = '',
      this.setType = 'normal',
      this.weightKg = 0.0,
      this.reps = 0,
      this.isCompleted = false});

  @override
  @JsonKey()
  final String id;
  @override
  @JsonKey()
  final String setType;
  @override
  @JsonKey()
  final double weightKg;
  @override
  @JsonKey()
  final int reps;
  @override
  @JsonKey()
  final bool isCompleted;

  @override
  String toString() {
    return 'WorkoutSetState(id: $id, setType: $setType, weightKg: $weightKg, reps: $reps, isCompleted: $isCompleted)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorkoutSetStateImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.setType, setType) || other.setType == setType) &&
            (identical(other.weightKg, weightKg) ||
                other.weightKg == weightKg) &&
            (identical(other.reps, reps) || other.reps == reps) &&
            (identical(other.isCompleted, isCompleted) ||
                other.isCompleted == isCompleted));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, setType, weightKg, reps, isCompleted);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WorkoutSetStateImplCopyWith<_$WorkoutSetStateImpl> get copyWith =>
      __$$WorkoutSetStateImplCopyWithImpl<_$WorkoutSetStateImpl>(
          this, _$identity);
}

abstract class _WorkoutSetState implements WorkoutSetState {
  const factory _WorkoutSetState(
      {final String id,
      final String setType,
      final double weightKg,
      final int reps,
      final bool isCompleted}) = _$WorkoutSetStateImpl;

  @override
  String get id;
  @override
  String get setType;
  @override
  double get weightKg;
  @override
  int get reps;
  @override
  bool get isCompleted;
  @override
  @JsonKey(ignore: true)
  _$$WorkoutSetStateImplCopyWith<_$WorkoutSetStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$WorkoutExerciseState {
  int get exerciseId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  List<WorkoutSetState> get sets => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $WorkoutExerciseStateCopyWith<WorkoutExerciseState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkoutExerciseStateCopyWith<$Res> {
  factory $WorkoutExerciseStateCopyWith(WorkoutExerciseState value,
          $Res Function(WorkoutExerciseState) then) =
      _$WorkoutExerciseStateCopyWithImpl<$Res, WorkoutExerciseState>;
  @useResult
  $Res call({int exerciseId, String name, List<WorkoutSetState> sets});
}

/// @nodoc
class _$WorkoutExerciseStateCopyWithImpl<$Res,
        $Val extends WorkoutExerciseState>
    implements $WorkoutExerciseStateCopyWith<$Res> {
  _$WorkoutExerciseStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? exerciseId = null,
    Object? name = null,
    Object? sets = null,
  }) {
    return _then(_value.copyWith(
      exerciseId: null == exerciseId
          ? _value.exerciseId
          : exerciseId // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      sets: null == sets
          ? _value.sets
          : sets // ignore: cast_nullable_to_non_nullable
              as List<WorkoutSetState>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WorkoutExerciseStateImplCopyWith<$Res>
    implements $WorkoutExerciseStateCopyWith<$Res> {
  factory _$$WorkoutExerciseStateImplCopyWith(_$WorkoutExerciseStateImpl value,
          $Res Function(_$WorkoutExerciseStateImpl) then) =
      __$$WorkoutExerciseStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int exerciseId, String name, List<WorkoutSetState> sets});
}

/// @nodoc
class __$$WorkoutExerciseStateImplCopyWithImpl<$Res>
    extends _$WorkoutExerciseStateCopyWithImpl<$Res, _$WorkoutExerciseStateImpl>
    implements _$$WorkoutExerciseStateImplCopyWith<$Res> {
  __$$WorkoutExerciseStateImplCopyWithImpl(_$WorkoutExerciseStateImpl _value,
      $Res Function(_$WorkoutExerciseStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? exerciseId = null,
    Object? name = null,
    Object? sets = null,
  }) {
    return _then(_$WorkoutExerciseStateImpl(
      exerciseId: null == exerciseId
          ? _value.exerciseId
          : exerciseId // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      sets: null == sets
          ? _value._sets
          : sets // ignore: cast_nullable_to_non_nullable
              as List<WorkoutSetState>,
    ));
  }
}

/// @nodoc

class _$WorkoutExerciseStateImpl implements _WorkoutExerciseState {
  const _$WorkoutExerciseStateImpl(
      {required this.exerciseId,
      required this.name,
      final List<WorkoutSetState> sets = const []})
      : _sets = sets;

  @override
  final int exerciseId;
  @override
  final String name;
  final List<WorkoutSetState> _sets;
  @override
  @JsonKey()
  List<WorkoutSetState> get sets {
    if (_sets is EqualUnmodifiableListView) return _sets;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sets);
  }

  @override
  String toString() {
    return 'WorkoutExerciseState(exerciseId: $exerciseId, name: $name, sets: $sets)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorkoutExerciseStateImpl &&
            (identical(other.exerciseId, exerciseId) ||
                other.exerciseId == exerciseId) &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality().equals(other._sets, _sets));
  }

  @override
  int get hashCode => Object.hash(runtimeType, exerciseId, name,
      const DeepCollectionEquality().hash(_sets));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WorkoutExerciseStateImplCopyWith<_$WorkoutExerciseStateImpl>
      get copyWith =>
          __$$WorkoutExerciseStateImplCopyWithImpl<_$WorkoutExerciseStateImpl>(
              this, _$identity);
}

abstract class _WorkoutExerciseState implements WorkoutExerciseState {
  const factory _WorkoutExerciseState(
      {required final int exerciseId,
      required final String name,
      final List<WorkoutSetState> sets}) = _$WorkoutExerciseStateImpl;

  @override
  int get exerciseId;
  @override
  String get name;
  @override
  List<WorkoutSetState> get sets;
  @override
  @JsonKey(ignore: true)
  _$$WorkoutExerciseStateImplCopyWith<_$WorkoutExerciseStateImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$ActiveWorkoutState {
  String get id => throw _privateConstructorUsedError;
  DateTime get startTime => throw _privateConstructorUsedError;
  String? get routineId => throw _privateConstructorUsedError;
  List<WorkoutExerciseState> get exercises =>
      throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $ActiveWorkoutStateCopyWith<ActiveWorkoutState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ActiveWorkoutStateCopyWith<$Res> {
  factory $ActiveWorkoutStateCopyWith(
          ActiveWorkoutState value, $Res Function(ActiveWorkoutState) then) =
      _$ActiveWorkoutStateCopyWithImpl<$Res, ActiveWorkoutState>;
  @useResult
  $Res call(
      {String id,
      DateTime startTime,
      String? routineId,
      List<WorkoutExerciseState> exercises});
}

/// @nodoc
class _$ActiveWorkoutStateCopyWithImpl<$Res, $Val extends ActiveWorkoutState>
    implements $ActiveWorkoutStateCopyWith<$Res> {
  _$ActiveWorkoutStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? startTime = null,
    Object? routineId = freezed,
    Object? exercises = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      routineId: freezed == routineId
          ? _value.routineId
          : routineId // ignore: cast_nullable_to_non_nullable
              as String?,
      exercises: null == exercises
          ? _value.exercises
          : exercises // ignore: cast_nullable_to_non_nullable
              as List<WorkoutExerciseState>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ActiveWorkoutStateImplCopyWith<$Res>
    implements $ActiveWorkoutStateCopyWith<$Res> {
  factory _$$ActiveWorkoutStateImplCopyWith(_$ActiveWorkoutStateImpl value,
          $Res Function(_$ActiveWorkoutStateImpl) then) =
      __$$ActiveWorkoutStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      DateTime startTime,
      String? routineId,
      List<WorkoutExerciseState> exercises});
}

/// @nodoc
class __$$ActiveWorkoutStateImplCopyWithImpl<$Res>
    extends _$ActiveWorkoutStateCopyWithImpl<$Res, _$ActiveWorkoutStateImpl>
    implements _$$ActiveWorkoutStateImplCopyWith<$Res> {
  __$$ActiveWorkoutStateImplCopyWithImpl(_$ActiveWorkoutStateImpl _value,
      $Res Function(_$ActiveWorkoutStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? startTime = null,
    Object? routineId = freezed,
    Object? exercises = null,
  }) {
    return _then(_$ActiveWorkoutStateImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      routineId: freezed == routineId
          ? _value.routineId
          : routineId // ignore: cast_nullable_to_non_nullable
              as String?,
      exercises: null == exercises
          ? _value._exercises
          : exercises // ignore: cast_nullable_to_non_nullable
              as List<WorkoutExerciseState>,
    ));
  }
}

/// @nodoc

class _$ActiveWorkoutStateImpl implements _ActiveWorkoutState {
  const _$ActiveWorkoutStateImpl(
      {required this.id,
      required this.startTime,
      this.routineId,
      final List<WorkoutExerciseState> exercises = const []})
      : _exercises = exercises;

  @override
  final String id;
  @override
  final DateTime startTime;
  @override
  final String? routineId;
  final List<WorkoutExerciseState> _exercises;
  @override
  @JsonKey()
  List<WorkoutExerciseState> get exercises {
    if (_exercises is EqualUnmodifiableListView) return _exercises;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_exercises);
  }

  @override
  String toString() {
    return 'ActiveWorkoutState(id: $id, startTime: $startTime, routineId: $routineId, exercises: $exercises)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ActiveWorkoutStateImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.routineId, routineId) ||
                other.routineId == routineId) &&
            const DeepCollectionEquality()
                .equals(other._exercises, _exercises));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, startTime, routineId,
      const DeepCollectionEquality().hash(_exercises));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ActiveWorkoutStateImplCopyWith<_$ActiveWorkoutStateImpl> get copyWith =>
      __$$ActiveWorkoutStateImplCopyWithImpl<_$ActiveWorkoutStateImpl>(
          this, _$identity);
}

abstract class _ActiveWorkoutState implements ActiveWorkoutState {
  const factory _ActiveWorkoutState(
      {required final String id,
      required final DateTime startTime,
      final String? routineId,
      final List<WorkoutExerciseState> exercises}) = _$ActiveWorkoutStateImpl;

  @override
  String get id;
  @override
  DateTime get startTime;
  @override
  String? get routineId;
  @override
  List<WorkoutExerciseState> get exercises;
  @override
  @JsonKey(ignore: true)
  _$$ActiveWorkoutStateImplCopyWith<_$ActiveWorkoutStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
