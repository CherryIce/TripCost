import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/money/currency.dart';
import 'package:trip_cost/core/storage/database/app_database.dart'
    hide Currency;
import 'package:trip_cost/core/storage/settings/drift_settings_repository.dart';

void main() {
  late AppDatabase database;
  late DriftSettingsRepository repository;
  final catalog = CurrencyCatalog();
  final now = DateTime.utc(2026, 8, 17, 8);

  setUp(() {
    database = AppDatabase.inMemory();
    repository = DriftSettingsRepository(database, currencyCatalog: catalog);
  });

  tearDown(() => database.close());

  test(
    'round-trips home, transaction, favorites, locale and refresh policy',
    () async {
      await repository.save(
        UserSettingsModel(
          metadata: SyncRecordMetadata(
            recordId: DriftSettingsRepository.settingsRecordId,
            syncVersion: 3,
            updatedAt: now,
          ),
          defaultCurrency: catalog.resolve('CNY'),
          lastTransactionCurrency: catalog.resolve('USD'),
          favoriteCurrencies: <Currency>[
            catalog.resolve('JPY'),
            catalog.resolve('EUR'),
          ],
          languageMode: AppLanguageMode.simplifiedChinese,
          refreshInterval: const Duration(hours: 6),
          wifiOnlyRefresh: true,
          syncEnabled: true,
        ),
      );

      final restored = await repository.load();
      expect(restored, isNotNull);
      expect(restored!.defaultCurrency.code, 'CNY');
      expect(restored.lastTransactionCurrency.code, 'USD');
      expect(
        restored.favoriteCurrencies.map((currency) => currency.code),
        <String>['JPY', 'EUR'],
      );
      expect(restored.languageMode, AppLanguageMode.simplifiedChinese);
      expect(restored.refreshInterval, const Duration(hours: 6));
      expect(restored.wifiOnlyRefresh, isTrue);
      expect(restored.syncEnabled, isTrue);
      expect(restored.metadata.syncVersion, 3);
      expect(restored.metadata.updatedAt, now);
    },
  );

  test('round-trips an identical USD transaction and home currency', () async {
    await repository.save(
      UserSettingsModel(
        metadata: SyncRecordMetadata(
          recordId: DriftSettingsRepository.settingsRecordId,
          syncVersion: 1,
          updatedAt: now,
        ),
        defaultCurrency: catalog.resolve('USD'),
        lastTransactionCurrency: catalog.resolve('USD'),
        favoriteCurrencies: const <Currency>[],
        languageMode: AppLanguageMode.system,
        refreshInterval: const Duration(hours: 6),
        wifiOnlyRefresh: false,
        syncEnabled: false,
      ),
    );

    final restored = await repository.load();

    expect(restored?.defaultCurrency.code, 'USD');
    expect(restored?.lastTransactionCurrency.code, 'USD');
  });
}
