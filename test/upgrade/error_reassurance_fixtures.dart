import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/providers/app_info_provider.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/database/daos/routines_dao.dart';
import 'package:gymlog/core/database/daos/workouts_dao.dart';
import 'package:gymlog/core/providers/premium_provider.dart';
import 'package:gymlog/core/services/notification_service.dart';
import 'package:gymlog/core/services/sync_engine.dart';
import 'package:gymlog/core/services/sync_status_provider.dart';
import 'package:gymlog/core/theme/app_theme.dart';
import 'package:gymlog/core/theme/theme_palette.dart';
import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';
import 'package:gymlog/features/profile/presentation/screens/settings_screen.dart';
import 'package:gymlog/features/routines/presentation/providers/routines_provider.dart';
import 'package:gymlog/features/routines/presentation/screens/routine_detail_screen.dart';
import 'package:gymlog/shared/widgets/app_error_screen.dart';
import 'package:gymlog/shared/widgets/async_error_state.dart';
import 'package:gymlog/shared/widgets/ui/app_action_row.dart';
import 'session_1_fixtures.dart';

class _OfflineStatus extends SyncStatusController {
  _OfflineStatus(this._phase);
  final SyncPhase _phase;
  @override
  Stream<SyncStatus> build() => Stream.value(SyncStatus(_phase));
}

class _Notifications extends Fake implements NotificationService {
  @override
  Future<bool> hasPermission() async => false;
}

Widget errorFixtureApp(String name, ThemePalette palette, double scale,
    {Key? captureKey}) {
  if (name == 'detail-error' || name == 'roles') {
    return fixtureApp(name, palette, scale, captureKey: captureKey);
  }
  return ProviderScope(
    overrides: [
      authProvider.overrideWithValue(null),
      isPremiumProvider.overrideWithValue(name != 'storage-free'),
      appVersionProvider.overrideWith((ref) async => '1.0.3'),
      // Synthetic sync phase in this fixture's root scope, not app scoping.
      // ignore: scoped_providers_should_specify_dependencies
      syncStatusControllerProvider.overrideWith(() => _OfflineStatus(
          name == 'sync-error' ? SyncPhase.error : SyncPhase.offline)),
      notificationServiceProvider.overrideWithValue(_Notifications()),
      routineDetailProvider('r1').overrideWith((ref) => Stream.value(
          HydratedRoutineDetail(
              routine: Routine(
                  id: 'r1',
                  userId: 'fixture',
                  name: 'Push A',
                  notes: '',
                  createdAt: fixtureDate,
                  updatedAt: fixtureDate),
              exercises: const []))),
      routineLastSetsProvider('r1').overrideWith((ref) => Stream.value({})),
      routineSessionStatsProvider('r1').overrideWith((ref) => Stream.value(
          const RoutineSessionStats(
              count: 0, bestVolumeKg: 0, totalVolumeKg: 0))),
      routineDailyVolumeProvider(('r1', '6M')).overrideWith(
          (ref) => Stream.error(StateError('synthetic read error'))),
      routineDailyVolumeProvider(('r1', 'All'))
          .overrideWith((ref) => Stream.value([])),
    ],
    child: RepaintBoundary(
        key: captureKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(palette.tokens, palette: palette),
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!),
          home: name == 'app-error'
              ? const AppErrorScreen()
              : name == 'async-error'
                  ? Scaffold(body: AsyncErrorState(onRetry: () {}))
                  : name == 'routine-error'
                      ? const RoutineDetailScreen(routineId: 'r1')
                      : const SettingsScreen(),
        )),
  );
}

Future<void> prepareErrorFixture(WidgetTester tester, String name) async {
  if (name == 'routine-error') {
    await tester.ensureVisible(find.byType(AsyncErrorState));
    await tester.pumpAndSettle();
  } else if (name.startsWith('storage-')) {
    await tester.scrollUntilVisible(find.text('Your data'), 250);
    // Invoke the existing action for copy capture; this does not qualify touch
    // behavior (the pre-existing Settings large-text row can be offscreen).
    tester
        .widgetList<AppActionRow>(find.byType(AppActionRow))
        .firstWhere((row) => row.title == 'Your data')
        .onTap
        ?.call();
    await tester.pumpAndSettle();
  } else if (name == 'offline' || name == 'sync-error') {
    await tester.scrollUntilVisible(
        find.text('Sync workout data to cloud'), 250);
    await tester.pumpAndSettle();
  }
}
