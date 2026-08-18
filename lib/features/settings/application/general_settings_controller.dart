import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trip_cost/app/locale_controller.dart';
import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/infrastructure/app_providers.dart';
import 'package:trip_cost/core/money/currency.dart';
import 'package:trip_cost/core/storage/settings/drift_settings_repository.dart';

final generalSettingsControllerProvider =
    AsyncNotifierProvider<GeneralSettingsController, UserSettingsModel>(
      GeneralSettingsController.new,
    );

final class GeneralSettingsController extends AsyncNotifier<UserSettingsModel> {
  @override
  Future<UserSettingsModel> build() async {
    final existing = await ref.watch(settingsRepositoryProvider).load();
    return existing ?? _defaults();
  }

  Future<void> setDefaultCurrency(Currency currency) =>
      _update(defaultCurrency: currency);

  Future<void> setFavoriteCurrencies(List<Currency> currencies) =>
      _update(favoriteCurrencies: currencies);

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
    List<Currency>? favoriteCurrencies,
    AppLanguageMode? languageMode,
    Duration? refreshInterval,
    bool? wifiOnlyRefresh,
  }) async {
    final repository = ref.read(settingsRepositoryProvider);
    final previous = await repository.load() ?? state.value ?? _defaults();
    final next = UserSettingsModel(
      metadata: SyncRecordMetadata(
        recordId: DriftSettingsRepository.settingsRecordId,
        syncVersion: previous.metadata.syncVersion + 1,
        updatedAt: DateTime.now().toUtc(),
      ),
      defaultCurrency: defaultCurrency ?? previous.defaultCurrency,
      favoriteCurrencies: favoriteCurrencies ?? previous.favoriteCurrencies,
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
      favoriteCurrencies: <Currency>[
        catalog.resolve('JPY'),
        catalog.resolve('USD'),
        catalog.resolve('EUR'),
      ],
      languageMode: AppLanguageMode.system,
      refreshInterval: const Duration(hours: 6),
      wifiOnlyRefresh: false,
      syncEnabled: false,
    );
  }
}
