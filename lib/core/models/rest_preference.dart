/// Typed representation of a rest timer preference for an exercise in a workout.
///
/// Distinguishes exactly:
/// - [RestPreferenceUseGlobalDefault]: use the global Settings rest duration (stored as `null`)
/// - [RestPreferenceDisabled]: rest timer disabled for this exercise (stored as `0`)
/// - [RestPreferenceCustomDuration]: explicit custom override duration in seconds (stored as `>0`)
sealed class RestPreference {
  const RestPreference();

  const factory RestPreference.useDefault() = RestPreferenceUseGlobalDefault;

  const factory RestPreference.disabled() = RestPreferenceDisabled;

  const factory RestPreference.custom(int seconds) =
      RestPreferenceCustomDuration;

  factory RestPreference.fromRaw(int? seconds) =>
      restPreferenceFromStorage(seconds);
  int? toRaw() => restPreferenceToStorage(this);

  bool get isDefault => isDefaultPredicate(this);
  bool get isDisabled => isOff(this);
  bool get isCustom => this is RestPreferenceCustomDuration;
}

class RestPreferenceUseGlobalDefault extends RestPreference {
  const RestPreferenceUseGlobalDefault();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RestPreferenceUseGlobalDefault;

  @override
  int get hashCode => 0;
}

class RestPreferenceDisabled extends RestPreference {
  const RestPreferenceDisabled();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RestPreferenceDisabled;

  @override
  int get hashCode => 1;
}

class RestPreferenceCustomDuration extends RestPreference {
  final int seconds;
  const RestPreferenceCustomDuration(this.seconds);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RestPreferenceCustomDuration && other.seconds == seconds);

  @override
  int get hashCode => seconds.hashCode;
}

RestPreference normalizeRestPreference({
  required RestPreference preference,
  required int globalSeconds,
}) {
  return switch (preference) {
    RestPreferenceCustomDuration(:final seconds) when seconds <= 0 =>
      const RestPreference.disabled(),
    RestPreferenceCustomDuration(:final seconds)
        when seconds == globalSeconds =>
      const RestPreference.useDefault(),
    RestPreferenceCustomDuration(:final seconds) =>
      RestPreference.custom(seconds.clamp(15, 600)),
    _ => preference,
  };
}

int? resolveRestSeconds({
  required RestPreference preference,
  required int globalSeconds,
}) {
  return switch (preference) {
    RestPreferenceUseGlobalDefault() =>
      globalSeconds > 0 ? globalSeconds : null,
    RestPreferenceDisabled() => null,
    RestPreferenceCustomDuration(:final seconds) => seconds.clamp(15, 600),
  };
}

bool isDefault(RestPreference value) => value is RestPreferenceUseGlobalDefault;

bool isDefaultPredicate(RestPreference value) =>
    value is RestPreferenceUseGlobalDefault;

bool isOff(RestPreference value) => value is RestPreferenceDisabled;

bool isCustomPreset(RestPreference value, int seconds) =>
    value is RestPreferenceCustomDuration && value.seconds == seconds;

RestPreference restPreferenceFromStorage(int? value) {
  if (value == null) {
    return const RestPreference.useDefault();
  }
  if (value <= 0) {
    return const RestPreference.disabled();
  }
  return RestPreference.custom(value);
}

int? restPreferenceToStorage(RestPreference value) {
  return switch (value) {
    RestPreferenceUseGlobalDefault() => null,
    RestPreferenceDisabled() => 0,
    RestPreferenceCustomDuration(:final seconds) => seconds,
  };
}
