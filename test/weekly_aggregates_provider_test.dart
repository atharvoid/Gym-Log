import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/database/daos/workouts_dao.dart';
import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';
import 'package:gymlog/features/profile/presentation/providers/profile_stats_provider.dart';

/// Listens to [weeklyAggregatesProvider] (which attaches watchers, so the
/// mapped value recomputes as the underlying stream settles) and returns the
/// final state once it leaves loading.
Future<AsyncValue<List<WeeklyAggregate>>> _settle(
    ProviderContainer container) async {
  final states = <AsyncValue<List<WeeklyAggregate>>>[];
  final sub = container.listen<AsyncValue<List<WeeklyAggregate>>>(
    weeklyAggregatesProvider,
    (_, next) => states.add(next),
    fireImmediately: true,
  );
  await pumpEventQueue();
  sub.close();
  return states.last;
}

void main() {
  test('weeklyAggregatesProvider surfaces a stream error (no zeroed weeks)',
      () async {
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWithValue(null),
        sessionStatsProvider.overrideWith(
          (ref) => Stream<List<SessionStat>>.error(
            Exception('forced stream failure'),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final value = await _settle(container);
    expect(value.isLoading, isFalse);
    expect(value.hasError, isTrue,
        reason: 'a failed stream must surface as an error, not all-zero weeks');
    expect(value.valueOrNull, isNull);
  });

  test('weeklyAggregatesProvider maps a data stream to 8 weekly buckets',
      () async {
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWithValue(null),
        sessionStatsProvider.overrideWith(
          (ref) => Stream<List<SessionStat>>.value([
            SessionStat(
              date: DateTime(2026, 7, 1, 12),
              volumeKg: 3000,
              reps: 120,
              duration: const Duration(minutes: 45),
            ),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);

    final value = await _settle(container);
    expect(value.hasError, isFalse);
    expect(value.valueOrNull, hasLength(8),
        reason: 'always 8 continuous weeks');
    expect(value.valueOrNull!.where((w) => w.workoutCount > 0).length, 1);
  });
}
