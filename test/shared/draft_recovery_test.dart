import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/services/workout_draft_store.dart';
import 'package:gymlog/features/workout/domain/active_workout_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UX-95-02 — Safe Draft Recovery', () {
    late Map<String, String> mockStorage;

    setUp(() {
      mockStorage = <String, String>{};
      FlutterSecureStorage.setMockInitialValues(mockStorage);
    });

    test('defensive try/catch around store.clear() at call site is safe',
        () async {
      final store = WorkoutDraftStore(const FlutterSecureStorage());
      final state = ActiveWorkoutState(
        id: 'draft-1',
        startTime: DateTime.now(),
        name: 'Test Workout',
      );

      await store.save(state, userId: 'user-1');
      expect(await store.load(currentUserId: 'user-1'), isNotNull);

      // Simulate the AppShell's defensive pattern from _maybeOfferResume.
      try {
        await store.clear();
      } catch (_) {
        fail('store.clear() should never throw; it is internally guarded');
      }

      expect(await store.load(currentUserId: 'user-1'), isNull);
    });

    test('defensive try/catch around store.loadSnapshot() at call site is safe',
        () async {
      final store = WorkoutDraftStore(const FlutterSecureStorage());

      // Simulate the AppShell's defensive pattern from _maybeOfferResume:
      // loadSnapshot returns null when no draft exists (not an error).
      WorkoutDraftSnapshot? snapshot;
      try {
        snapshot = await store.loadSnapshot(currentUserId: 'user-1');
      } catch (_) {
        fail(
            'store.loadSnapshot() should never throw; it is internally guarded');
      }

      expect(snapshot, isNull);
    });

    test('store.loadSnapshot handles corrupted payload internally', () async {
      const storageKey = 'active_workout_draft_v2';
      mockStorage[storageKey] = '{"corrupted: no closing brace';

      final store = WorkoutDraftStore(const FlutterSecureStorage());
      WorkoutDraftSnapshot? snapshot;
      try {
        snapshot = await store.loadSnapshot(currentUserId: 'user-1');
      } catch (_) {
        fail('loadSnapshot must not throw on corrupt payload');
      }

      expect(snapshot, isNull);
      expect(mockStorage.containsKey(storageKey), isFalse);
    });

    test('store.clear() survives when called on empty storage', () async {
      final store = WorkoutDraftStore(const FlutterSecureStorage());
      try {
        await store.clear();
      } catch (_) {
        fail('store.clear() must not throw on empty storage');
      }
    });

    test('store.loadSnapshot returns null for missing storage', () async {
      final store = WorkoutDraftStore(const FlutterSecureStorage());
      final snapshot = await store.loadSnapshot(currentUserId: 'user-1');
      expect(snapshot, isNull);
    });
  });
}
