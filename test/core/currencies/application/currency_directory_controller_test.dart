import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/core/currencies/application/currency_directory_controller.dart';
import 'package:trip_cost/core/currencies/data/currency_directory_repository.dart';
import 'package:trip_cost/core/infrastructure/app_providers.dart';
import 'package:trip_cost/core/rates/data/frankfurter_api_client.dart';
import 'package:trip_cost/core/rates/data/frankfurter_dtos.dart';
import 'package:trip_cost/core/storage/database/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() => database = AppDatabase.inMemory());
  tearDown(() => database.close());

  test(
    'uses the eight in-memory currencies when first launch is offline',
    () async {
      final container = ProviderContainer(
        overrides: [
          currencyDirectoryRepositoryProvider.overrideWithValue(
            CurrencyDirectoryRepository(
              database: database,
              gateway: const _OfflineGateway(),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final initial = container.read(currencyDirectoryProvider);
      expect(initial.source, CurrencyDirectorySource.fallback);
      expect(initial.currencies, hasLength(8));

      await pumpEventQueue(times: 10);
      final settled = container.read(currencyDirectoryProvider);
      expect(settled.source, CurrencyDirectorySource.fallback);
      expect(settled.isRefreshing, isFalse);
      expect(settled.currencies, hasLength(8));
    },
  );

  test('publishes Drift cache before an offline refresh settles', () async {
    final now = DateTime.utc(2026, 8, 18);
    await database.coreDao.upsertCurrency(
      CurrenciesCompanion.insert(
        code: 'AUD',
        numericCode: const Value<String?>('036'),
        name: 'Australian Dollar',
        symbol: r'$',
        minorUnits: 2,
        updatedAt: now,
      ),
    );
    final container = ProviderContainer(
      overrides: [
        currencyDirectoryRepositoryProvider.overrideWithValue(
          CurrencyDirectoryRepository(
            database: database,
            gateway: const _OfflineGateway(),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(currencyDirectoryProvider);
    await pumpEventQueue(times: 10);
    final settled = container.read(currencyDirectoryProvider);

    expect(settled.source, CurrencyDirectorySource.cache);
    expect(settled.isRefreshing, isFalse);
    expect(settled.currencies.single.code, 'AUD');
  });
}

final class _OfflineGateway implements FrankfurterRatesGateway {
  const _OfflineGateway();

  @override
  Future<List<FrankfurterCurrencyDto>> getCurrencies() =>
      throw Exception('offline');

  @override
  Future<FrankfurterRateDto> getRate({
    required String baseCurrencyCode,
    required String quoteCurrencyCode,
    DateTime? date,
  }) => throw UnimplementedError();

  @override
  Future<List<FrankfurterRateDto>> getRates({
    required String baseCurrencyCode,
    required Iterable<String> quoteCurrencyCodes,
    DateTime? date,
  }) => throw UnimplementedError();
}
