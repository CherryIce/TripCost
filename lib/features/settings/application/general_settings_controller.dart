import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trip_cost/app/locale_controller.dart';
import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/domain/repositories.dart';
import 'package:trip_cost/core/infrastructure/app_providers.dart';
import 'package:trip_cost/core/money/currency.dart';
import 'package:trip_cost/core/storage/settings/drift_settings_repository.dart';

final generalSettingsControllerProvider =
    AsyncNotifierProvider<GeneralSettingsController, UserSettingsModel>(
      GeneralSettingsController.new,
    );

final class GeneralSettingsController extends AsyncNotifier<UserSettingsModel> {
  StreamSubscription<void>? _cacheSubscription;

  @override
  Future<UserSettingsModel> build() async {
    final repository = ref.watch(settingsRepositoryProvider);
    _observe(repository);
    final existing = await repository.load();
    final value = existing ?? _defaults();
    ref.read(localeControllerProvider.notifier).setMode(value.languageMode);
    return value;
  }

  Future<void> setDefaultCurrency(Currency currency) =>
      _update(defaultCurrency: currency);

  Future<void> setRefreshInterval(Duration interval) =>
      _update(refreshInterval: interval);

  Future<void> setWifiOnlyRefresh(bool value) =>
      _update(wifiOnlyRefresh: value);

  Future<void> setLanguage(AppLanguageMode mode) async {
    ref.read(localeControllerProvider.notifier).setMode(mode);
    await _update(languageMode: mode);
  }

  Future<void> _update({
    Currency? defaultCurrency,
    AppLanguageMode? languageMode,
    Duration? refreshInterval,
    bool? wifiOnlyRefresh,
  }) async {
    final repository = ref.read(settingsRepositoryProvider);
    final previous = await repository.load() ?? state.value ?? _defaults();
    final nextDefaultCurrency = defaultCurrency ?? previous.defaultCurrency;
    final next = UserSettingsModel(
      metadata: SyncRecordMetadata(
        recordId: DriftSettingsRepository.settingsRecordId,
        syncVersion: previous.metadata.syncVersion + 1,
        updatedAt: DateTime.now().toUtc(),
      ),
      defaultCurrency: nextDefaultCurrency,
      lastTransactionCurrency: previous.lastTransactionCurrency,
      // Retained only for backward-compatible decoding of older settings.
      favoriteCurrencies: previous.favoriteCurrencies,
      languageMode: languageMode ?? previous.languageMode,
      refreshInterval: refreshInterval ?? previous.refreshInterval,
      wifiOnlyRefresh: wifiOnlyRefresh ?? previous.wifiOnlyRefresh,
      syncEnabled: previous.syncEnabled,
    );
    state = AsyncData(next);
    try {
      await repository.save(next);
      await ref.read(localDataChangeCoordinatorProvider).notify();
    } on Object catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  UserSettingsModel _defaults() {
    final catalog = CurrencyCatalog();
    return UserSettingsModel(
      metadata: SyncRecordMetadata(
        recordId: DriftSettingsRepository.settingsRecordId,
        syncVersion: 1,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      ),
      defaultCurrency: catalog.resolve('CNY'),
      lastTransactionCurrency: catalog.resolve('USD'),
      favoriteCurrencies: const <Currency>[],
      languageMode: AppLanguageMode.system,
      refreshInterval: const Duration(hours: 6),
      wifiOnlyRefresh: false,
      syncEnabled: false,
    );
  }

  void _observe(SettingsRepository repository) {
    unawaited(_cacheSubscription?.cancel());
    _cacheSubscription = repository is CacheRepositoryObserver
        ? (repository as CacheRepositoryObserver).watchChanges().listen((_) {
            if (ref.mounted) unawaited(_reloadFromCache());
          })
        : null;
    ref.onDispose(() => _cacheSubscription?.cancel());
  }

  Future<void> _reloadFromCache() async {
    final value =
        await ref.read(settingsRepositoryProvider).load() ?? _defaults();
    if (!ref.mounted) return;
    state = AsyncData(value);
    ref.read(localeControllerProvider.notifier).setMode(value.languageMode);
  }
}
