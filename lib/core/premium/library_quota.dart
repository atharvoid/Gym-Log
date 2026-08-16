// [library_quota.dart]
// Free-tier ceilings for the routine library, expressed in the units users
// actually think in: programs and routines.
//
// THE BUG THIS REPLACES
// The shipped gate counts routines only:
//
//     isAtFreeRoutineLimit(
//       isPremium: isPremium,
//       routineCount: count + template.days.length - 1,
//     )
//
// A program is imported as N independent routines, so a free user with an
// empty library who taps the featured 6-day Push/Pull/Legs evaluates
// 0 + 6 - 1 = 5 >= 4 and is sent to the paywall on their FIRST import. The
// most prominent card in Explore is unreachable on the free plan, and the
// user has not yet experienced a single thing worth paying for.
//
// THE MODEL
// One active program of any size, plus four standalone routines. Size is not
// punished -- committing to a 6-day program is the behaviour we want, not the
// behaviour we tax. The paywall lands on the SECOND program, when the user has
// already run the first one and has proven intent.
//
// Pure Dart on purpose: no riverpod, no purchases_flutter. It can be unit
// tested without a container and imported from anywhere without cycles.

/// Active programs a free user may own. Any number of routines inside.
const int kFreeProgramLimit = 1;

/// Standalone routines -- ones not attached to a program -- a free user may own.
const int kFreeStandaloneRoutineLimit = 4;

/// What the user is trying to add to their library.
enum ImportKind {
  /// Import a whole program, or a subset of its routines, as a NEW program.
  program,

  /// Import one or more routines that will not belong to a program.
  standaloneRoutine,

  /// Add a routine to a program the user has ALREADY imported.
  /// Always free -- see [evaluateImport].
  routineIntoOwnedProgram,
}

/// The outcome of a quota check.
enum ImportVerdict {
  /// Proceed with the import.
  allowed,

  /// Blocked: the free plan allows only [kFreeProgramLimit] active program.
  needsPremiumProgramSlot,

  /// Blocked: the import would exceed [kFreeStandaloneRoutineLimit].
  needsPremiumRoutineSlots,
}

extension ImportVerdictX on ImportVerdict {
  bool get isAllowed => this == ImportVerdict.allowed;
  bool get isBlocked => this != ImportVerdict.allowed;
}

/// Decides whether an import may proceed on the current plan.
///
/// [ownedProgramCount] counts programs already in the library.
/// [standaloneRoutineCount] counts routines NOT attached to a program.
/// [routineCount] is how many routines this particular import would add.
///
/// Grandfathering: a user already above a cap (legacy import, or a lapsed Pro
/// subscription) keeps everything they have. The >= comparisons only prevent
/// adding more, they never delete or hide existing content.
ImportVerdict evaluateImport({
  required bool isPremium,
  required ImportKind kind,
  int ownedProgramCount = 0,
  int standaloneRoutineCount = 0,
  int routineCount = 1,
}) {
  // Pro is never gated.
  if (isPremium) return ImportVerdict.allowed;

  switch (kind) {
    // Completing something you already own is always free. Without this, a
    // user who imported 3 of 6 days could be blocked from finishing their own
    // program -- a worse trap than the one being fixed.
    case ImportKind.routineIntoOwnedProgram:
      return ImportVerdict.allowed;

    // Size-independent: a 6-day program costs the same slot as a 3-day one.
    case ImportKind.program:
      return ownedProgramCount >= kFreeProgramLimit
          ? ImportVerdict.needsPremiumProgramSlot
          : ImportVerdict.allowed;

    case ImportKind.standaloneRoutine:
      return standaloneRoutineCount + routineCount > kFreeStandaloneRoutineLimit
          ? ImportVerdict.needsPremiumRoutineSlots
          : ImportVerdict.allowed;
  }
}

/// Standalone routine slots still available, floored at zero so grandfathered
/// users never render a negative count.
int remainingStandaloneRoutineSlots({
  required bool isPremium,
  required int standaloneRoutineCount,
}) {
  if (isPremium) return kFreeStandaloneRoutineLimit;
  final remaining = kFreeStandaloneRoutineLimit - standaloneRoutineCount;
  return remaining < 0 ? 0 : remaining;
}

/// True when a free user has used their one program slot.
bool hasUsedFreeProgramSlot({
  required bool isPremium,
  required int ownedProgramCount,
}) =>
    !isPremium && ownedProgramCount >= kFreeProgramLimit;

/// Paywall copy for a blocked verdict, or null when the import is allowed.
///
/// The copy names what the user gets back, not what they did wrong.
String? importBlockedCopy(ImportVerdict verdict) {
  switch (verdict) {
    case ImportVerdict.allowed:
      return null;
    case ImportVerdict.needsPremiumProgramSlot:
      return 'Free includes one program at a time. '
          'Go Pro to run several, or swap this one out.';
    case ImportVerdict.needsPremiumRoutineSlots:
      return 'Free includes $kFreeStandaloneRoutineLimit standalone routines. '
          'Go Pro for unlimited.';
  }
}
