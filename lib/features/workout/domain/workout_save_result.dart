import '../../../../core/models/personal_record.dart';

sealed class WorkoutSaveResult {
  const WorkoutSaveResult();

  factory WorkoutSaveResult.success(List<PersonalRecord> prs) =
      WorkoutSaveSuccess;
  factory WorkoutSaveResult.failure(String reason, {bool retryable}) =
      WorkoutSaveFailure;
}

class WorkoutSaveSuccess extends WorkoutSaveResult {
  final List<PersonalRecord> prs;
  const WorkoutSaveSuccess(this.prs) : super();
}

class WorkoutSaveFailure extends WorkoutSaveResult {
  final String reason;
  final bool retryable;
  const WorkoutSaveFailure(this.reason, {this.retryable = true}) : super();
}
