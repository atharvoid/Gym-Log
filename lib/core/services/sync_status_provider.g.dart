// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_status_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$syncStatusControllerHash() =>
    r'65cdea73db27e17ffbfaa525e77a9eda4c66376d';

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
///
/// Copied from [SyncStatusController].
@ProviderFor(SyncStatusController)
final syncStatusControllerProvider = AutoDisposeStreamNotifierProvider<
    SyncStatusController, SyncStatus>.internal(
  SyncStatusController.new,
  name: r'syncStatusControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$syncStatusControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SyncStatusController = AutoDisposeStreamNotifier<SyncStatus>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
