import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/premium/library_quota.dart';

void main() {
  group('the free-tier dead end', () {
    test('a new free user CAN import the featured 6-day program', () {
      // Old gate: 0 + 6 - 1 = 5 >= kFreeRoutineLimit(4) -> paywall on the
      // first ever import. This is the regression under test.
      final verdict = evaluateImport(
        isPremium: false,
        kind: ImportKind.program,
        ownedProgramCount: 0,
        standaloneRoutineCount: 0,
        routineCount: 6,
      );
      expect(verdict, ImportVerdict.allowed);
    });

    test('program size does not consume routine slots', () {
      for (final size in const [1, 3, 4, 5, 6, 7]) {
        expect(
          evaluateImport(
            isPremium: false,
            kind: ImportKind.program,
            ownedProgramCount: 0,
            routineCount: size,
          ),
          ImportVerdict.allowed,
          reason: '$size-day program should fit the free program slot',
        );
      }
    });
  });

  group('program slot', () {
    test('the second program is where the paywall lands', () {
      expect(
        evaluateImport(
          isPremium: false,
          kind: ImportKind.program,
          ownedProgramCount: 1,
        ),
        ImportVerdict.needsPremiumProgramSlot,
      );
    });

    test('Pro is never gated', () {
      expect(
        evaluateImport(
          isPremium: true,
          kind: ImportKind.program,
          ownedProgramCount: 12,
        ),
        ImportVerdict.allowed,
      );
    });

    test('hasUsedFreeProgramSlot tracks the cap', () {
      expect(
        hasUsedFreeProgramSlot(isPremium: false, ownedProgramCount: 0),
        isFalse,
      );
      expect(
        hasUsedFreeProgramSlot(isPremium: false, ownedProgramCount: 1),
        isTrue,
      );
      expect(
        hasUsedFreeProgramSlot(isPremium: true, ownedProgramCount: 9),
        isFalse,
      );
    });
  });

  group('completing an owned program is always free', () {
    test('even when both caps are already exhausted', () {
      expect(
        evaluateImport(
          isPremium: false,
          kind: ImportKind.routineIntoOwnedProgram,
          ownedProgramCount: 1,
          standaloneRoutineCount: 4,
          routineCount: 3,
        ),
        ImportVerdict.allowed,
      );
    });
  });

  group('standalone routines', () {
    test('fills exactly to the cap', () {
      expect(
        evaluateImport(
          isPremium: false,
          kind: ImportKind.standaloneRoutine,
          standaloneRoutineCount: 3,
          routineCount: 1,
        ),
        ImportVerdict.allowed,
      );
    });

    test('blocks the one that would overflow', () {
      expect(
        evaluateImport(
          isPremium: false,
          kind: ImportKind.standaloneRoutine,
          standaloneRoutineCount: 4,
          routineCount: 1,
        ),
        ImportVerdict.needsPremiumRoutineSlots,
      );
    });

    test('checks the whole batch, not one at a time', () {
      expect(
        evaluateImport(
          isPremium: false,
          kind: ImportKind.standaloneRoutine,
          standaloneRoutineCount: 2,
          routineCount: 3,
        ),
        ImportVerdict.needsPremiumRoutineSlots,
      );
    });

    test('remaining slots never go negative for grandfathered users', () {
      expect(
        remainingStandaloneRoutineSlots(
          isPremium: false,
          standaloneRoutineCount: 9,
        ),
        0,
      );
      expect(
        remainingStandaloneRoutineSlots(
          isPremium: false,
          standaloneRoutineCount: 1,
        ),
        3,
      );
    });
  });

  group('copy', () {
    test('allowed has no blocking copy', () {
      expect(importBlockedCopy(ImportVerdict.allowed), isNull);
    });

    test('every blocked verdict has copy', () {
      for (final verdict in ImportVerdict.values) {
        if (verdict.isBlocked) {
          expect(importBlockedCopy(verdict), isNotNull, reason: '$verdict');
        }
      }
    });
  });
}
