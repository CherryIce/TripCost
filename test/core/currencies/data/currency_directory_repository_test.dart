import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/core/currencies/data/currency_directory_repository.dart';
import 'package:trip_cost/core/currencies/data/iso_currency_metadata.dart';
import 'package:trip_cost/core/rates/data/frankfurter_api_client.dart';
import 'package:trip_cost/core/rates/data/frankfurter_dtos.dart';
import 'package:trip_cost/core/storage/database/app_database.dart';
import 'package:trip_cost/core/storage/database/database_bootstrapper.dart';

void main() {
  late AppDatabase database;

  setUp(() => database = AppDatabase.inMemory());
  tearDown(() => database.close());

  test('filters non-travel entries and enriches ISO accounting digits', () {
    final metadata = IsoCurrencyMetadata();

    expect(metadata.enrich(_currency('XAU')), isNull);
    expect(metadata.enrich(_currency('CNH')), isNull);
    expect(metadata.enrich(_currency('CLF')), isNull);
    expect(metadata.enrich(_currency('JPY'))!.minorUnits, 0);
    expect(metadata.enrich(_currency('KWD'))!.minorUnits, 3);
    expect(metadata.enrich(_currency('USD'))!.minorUnits, 2);

    final cny = metadata.enrich(_currency('CNY'))!;
    expect(metadata.localizedName(cny, 'zh'), isNot(cny.name));
    expect(metadata.localizedName(cny, 'en'), isNotEmpty);
  });

  test(
    'refresh replaces the active Drift directory with API-supported fiat',
    () async {
      await DatabaseBootstrapper(database).seedCurrencyMetadata();
      final repository = CurrencyDirectoryRepository(
        database: database,
        gateway: _Gateway(<FrankfurterCurrencyDto>[
          _currency('AUD'),
          _currency('JPY'),
          _currency('KWD'),
          _currency('XAU'),
          _currency('CNH'),
        ]),
        clock: () => DateTime.utc(2026, 8, 18, 10),
      );

      final refreshed = await repository.refresh();
      final cached = await repository.loadCached();

      expect(refreshed.map((item) => item.code), <String>['AUD', 'JPY', 'KWD']);
      expect(cached.map((item) => item.code), <String>['AUD', 'JPY', 'KWD']);
      expect(cached.singleWhere((item) => item.code == 'JPY').minorUnits, 0);
      expect(cached.singleWhere((item) => item.code == 'KWD').minorUnits, 3);
    },
  );

  test(
    'failed refresh preserves the eight seeded offline currencies',
    () async {
      await DatabaseBootstrapper(database).seedCurrencyMetadata();
      final repository = CurrencyDirectoryRepository(
        database: database,
        gateway: const _Gateway.failure(),
      );

      await expectLater(repository.refresh(), throwsException);
      final cached = await repository.loadCached();

      expect(cached.map((item) => item.code).toSet(), {
        'CNY',
        'USD',
        'EUR',
        'JPY',
        'KRW',
        'GBP',
        'CHF',
        'KWD',
      });
    },
  );
}

FrankfurterCurrencyDto _currency(String code) {
  return FrankfurterCurrencyDto(
    code: code,
    name: '$code remote name',
    numericCode: null,
    symbol: null,
    startDate: DateTime.utc(2000),
    endDate: DateTime.utc(2026, 8, 18),
  );
}

final class _Gateway implements FrankfurterRatesGateway {
  const _Gateway(this.currencies) : fails = false;
  const _Gateway.failure() : currencies = const [], fails = true;

  final List<FrankfurterCurrencyDto> currencies;
  final bool fails;

  @override
  Future<List<FrankfurterCurrencyDto>> getCurrencies() async {
    if (fails) throw Exception('offline');
    return currencies;
  }

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
