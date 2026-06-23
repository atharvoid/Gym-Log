import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'sync_engine.dart';

part 'sync_status_provider.g.dart';

/// Sync status as a first-class, code-generated Riverpod provider.
///
/// Supersedes the legacy `ValueNotifier<SyncStatus>` that `SyncEngine` used to
/// expose. Widgets and other providers watch [syncStatusControllerProvider]
/// and receive an `AsyncValue<SyncStatus>`. The underlying stream replays the
/// engine's current snapshot immediately, so there is no transient "loading"
/// gap on first build.
///
/// Because the provider is derived from [syncEngineProvider], it is rebuilt
/// cleanly whenever the engine is recreated — there are no manual listener
/// attach/detach steps and no disposal bugs to get wrong.
@riverpod
class SyncStatusController extends _$SyncStatusController {
  @override
  Stream<SyncStatus> build() {
    final engine = ref.watch(syncEngineProvider);
    return engine.statusStream;
  }
}
