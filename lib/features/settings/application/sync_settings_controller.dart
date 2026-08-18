import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/domain/repositories.dart';
import 'package:trip_cost/core/infrastructure/app_providers.dart';
import 'package:trip_cost/core/storage/settings/drift_settings_repository.dart';
import 'package:trip_cost/core/sync/domain/sync_models.dart';

final syncSettingsControllerProvider =
    AsyncNotifierProvider<SyncSettingsController, SyncSettingsState>(
      SyncSettingsController.new,
    );

final class SyncSettingsState {
  const SyncSettingsState({
    required this.enabled,
    required this.runtime,
    required this.conflicts,
  });

  final bool enabled;
  final SyncRuntimeStatus runtime;
  final List<SyncConflictModel> conflicts;
}

final class SyncSettingsController extends AsyncNotifier<SyncSettingsState> {
  UserSettingsModel? _settings;
  final List<StreamSubscription<void>> _cacheSubscriptions =
      <StreamSubscription<void>>[];

  @override
  Future<SyncSettingsState> build() async {
    final settingsRepository = ref.watch(settingsRepositoryProvider);
    final store = ref.watch(syncStoreProvider);
    _observe(<Object>[settingsRepository, store]);
    _settings = await settingsRepository.load();
    final value = await _load();
    if (value.enabled) {
      unawaited(_run(force: false));
    }
    return value;
  }

  void _observe(List<Object> sources) {
    for (final subscription in _cacheSubscriptions) {
      unawaited(subscription.cancel());
    }
    _cacheSubscriptions.clear();
    for (final source in sources.whereType<CacheRepositoryObserver>()) {
      _cacheSubscriptions.add(
        source.watchChanges().listen((_) {
          if (ref.mounted) unawaited(_reloadObservedState());
        }),
      );
    }
    ref.onDispose(() {
      for (final subscription in _cacheSubscriptions) {
        unawaited(subscription.cancel());
      }
    });
  }

  Future<void> _reloadObservedState() async {
    _settings = await ref.read(settingsRepositoryProvider).load();
    final value = await _load();
    if (ref.mounted) state = AsyncData(value);
  }

  Future<void> setEnabled(bool enabled) async {
    final repository = ref.read(settingsRepositoryProvider);
    final previous = await repository.load() ?? _settings;
    final now = DateTime.now().toUtc();
    final next = UserSettingsModel(
      metadata: SyncRecordMetadata(
        recordId: DriftSettingsRepository.settingsRecordId,
        syncVersion: (previous?.metadata.syncVersion ?? 0) + 1,
        updatedAt: now,
      ),
      defaultCurrency:
          previous?.defaultCurrency ??
          (throw StateError('Complete onboarding before changing sync.')),
      favoriteCurrencies: previous!.favoriteCurrencies,
      languageMode: previous.languageMode,
      refreshInterval: previous.refreshInterval,
      wifiOnlyRefresh: previous.wifiOnlyRefresh,
      syncEnabled: enabled,
    );
    await repository.save(next);
    _settings = next;
    if (enabled) {
      await _run(force: true);
    } else {
      final current = await ref.read(syncStoreProvider).status();
      await ref
          .read(syncStoreProvider)
          .updateRuntime(
            accountState: current.accountState,
            phase: SyncPhase.disabled,
          );
      state = AsyncData(await _load());
    }
  }

  Future<void> synchronizeNow() => _run(force: true);

  Future<void> resolveConflict(
    SyncConflictModel conflict, {
    required bool useRemoteValue,
  }) async {
    await ref
        .read(syncStoreProvider)
        .resolveActualAmountConflict(conflict, useRemoteValue: useRemoteValue);
    await _run(force: true);
  }

  Future<void> _run({required bool force}) async {
    final current = state.value;
    if (current != null) state = AsyncData(current);
    await ref.read(syncOrchestratorProvider).synchronize(force: force);
    try {
      await ref.read(widgetSnapshotServiceProvider).refresh();
    } on Object {
      // Widget sharing failure is surfaced by its own placeholder and must not
      // change Cloud sync success or block local data.
    }
    state = AsyncData(await _load());
  }

  Future<SyncSettingsState> _load() async {
    if (_settings?.syncEnabled != true) {
      return const SyncSettingsState(
        enabled: false,
        runtime: SyncRuntimeStatus(
          accountState: SyncAccountState.couldNotDetermine,
          phase: SyncPhase.disabled,
          failureCount: 0,
        ),
        conflicts: <SyncConflictModel>[],
      );
    }
    final store = ref.read(syncStoreProvider);
    return SyncSettingsState(
      enabled: _settings?.syncEnabled ?? false,
      runtime: await store.status(),
      conflicts: await store.unresolvedConflicts(),
    );
  }
}
