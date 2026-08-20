import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/app/locale_controller.dart';
import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/infrastructure/app_providers.dart';
import 'package:trip_cost/core/money/currency.dart';
import 'package:trip_cost/features/settings/application/general_settings_controller.dart';

import '../../../helpers/m4_fakes.dart';

void main() {
  test('defaults to CNY home currency and USD transaction currency', () async {
    final container = ProviderContainer(
      overrides: [
        systemLocaleProvider.overrideWithValue(const Locale('en', 'US')),
        settingsRepositoryProvider.overrideWithValue(
          MemorySettingsRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final settings = await container.read(
      generalSettingsControllerProvider.future,
    );

    expect(settings.defaultCurrency.code, 'CNY');
    expect(settings.lastTransactionCurrency.code, 'USD');
  });

  test('persists currency, refresh, Wi-Fi, and language settings', () async {
    final catalog = CurrencyCatalog();
    final repository = MemorySettingsRepository(
      UserSettingsModel(
        metadata: SyncRecordMetadata(
          recordId: 'app',
          syncVersion: 1,
          updatedAt: DateTime.utc(2026, 8, 17),
        ),
        defaultCurrency: catalog.resolve('CNY'),
        lastTransactionCurrency: catalog.resolve('JPY'),
        favoriteCurrencies: <Currency>[catalog.resolve('JPY')],
        languageMode: AppLanguageMode.system,
        refreshInterval: const Duration(hours: 6),
        wifiOnlyRefresh: false,
        syncEnabled: true,
      ),
    );
    final container = ProviderContainer(
      overrides: [
        systemLocaleProvider.overrideWithValue(const Locale('en', 'US')),
        settingsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    await container.read(generalSettingsControllerProvider.future);
    final notifier = container.read(generalSettingsControllerProvider.notifier);

    await notifier.setDefaultCurrency(CurrencyCatalog().resolve('USD'));
    await notifier.setRefreshInterval(const Duration(hours: 24));
    await notifier.setWifiOnlyRefresh(true);
    await notifier.setLanguage(AppLanguageMode.simplifiedChinese);

    expect(repository.value?.defaultCurrency.code, 'USD');
    expect(repository.value?.lastTransactionCurrency.code, 'JPY');
    expect(repository.value?.refreshInterval, const Duration(hours: 24));
    expect(repository.value?.wifiOnlyRefresh, isTrue);
    expect(repository.value?.languageMode, AppLanguageMode.simplifiedChinese);
    expect(repository.value?.syncEnabled, isTrue);
    expect(
      repository.value?.favoriteCurrencies.map((currency) => currency.code),
      <String>['JPY'],
    );
    expect(container.read(localeControllerProvider), const Locale('zh', 'US'));
  });

  test(
    'keeps USD as the transaction currency when home changes to USD',
    () async {
      final repository = MemorySettingsRepository();
      final container = ProviderContainer(
        overrides: [
          systemLocaleProvider.overrideWithValue(const Locale('en', 'US')),
          settingsRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      await container.read(generalSettingsControllerProvider.future);

      await container
          .read(generalSettingsControllerProvider.notifier)
          .setDefaultCurrency(CurrencyCatalog().resolve('USD'));

      expect(repository.value?.defaultCurrency.code, 'USD');
      expect(repository.value?.lastTransactionCurrency.code, 'USD');
    },
  );
}
