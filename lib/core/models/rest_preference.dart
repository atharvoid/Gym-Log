/// Typed representation of a rest timer preference for an exercise in a workout.
///
/// Distinguishes exactly:
/// - [RestPreferenceUseGlobalDefault]: use the global Settings rest duration (stored as `null`)
/// - [RestPreferenceDisabled]: rest timer disabled for this exercise (stored as `0`)
/// - [RestPreferenceCustomDuration]: explicit custom override duration in seconds (stored as `>0`)
sealed class RestPreference {
  const RestPreference();

  factory RestPreference.fromRaw(int? seconds) {
    if (seconds == null) return const RestPreferenceUseGlobalDefault();
    if (seconds == 0) return const RestPreferenceDisabled();
    return RestPreferenceCustomDuration(seconds);
  }

  int? toRaw() => switch (this) {
        RestPreferenceUseGlobalDefault() => null,
        RestPreferenceDisabled() => 0,
        RestPreferenceCustomDuration(:final seconds) => seconds,
      };

  bool get isDefault => this is RestPreferenceUseGlobalDefault;
  bool get isDisabled => this is RestPreferenceDisabled;
  bool get isCustom => this is RestPreferenceCustomDuration;
}

class RestPreferenceUseGlobalDefault extends RestPreference {
  const RestPreferenceUseGlobalDefault();
}

class RestPreferenceDisabled extends RestPreference {
  const RestPreferenceDisabled();
}

class RestPreferenceCustomDuration extends RestPreference {
  final int seconds;
  const RestPreferenceCustomDuration(this.seconds);
}
