import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/money/currency.dart' as money;
import 'package:trip_cost/core/money/decimal_value.dart';
import 'package:trip_cost/core/rates/data/drift_rate_snapshot_repository.dart';
import 'package:trip_cost/core/rates/data/frankfurter_api_client.dart';
import 'package:trip_cost/core/rates/data/frankfurter_dtos.dart';
import 'package:trip_cost/core/rates/domain/exchange_rate_repository.dart';
import 'package:trip_cost/core/storage/database/app_database.dart';

void main() {
  late AppDatabase database;
  late DriftRateSnapshotRepository snapshots;
  late FakeGateway gateway;
  late Ids ids;
  final catalog = money.CurrencyCatalog();
  final now = DateTime.utc(2026, 8, 17, 10);

  setUp(() {
    database = AppDatabase.inMemory();
    snapshots = DriftRateSnapshotRepository(database, clock: () => now);
    gateway = FakeGateway();
    ids = Ids();
  });

  tearDown(() => database.close());

  ExchangeRateRepository createRepository({
    DateTime Function()? clock,
    CardNetworkRateProvider? cardNetworkRateProvider,
  }) {
    return ExchangeRateRepository(
      marketGateway: gateway,
      snapshotRepository: snapshots,
      cardNetworkRateProvider: cardNetworkRateProvider,
      clock: clock ?? () => now,
      idFactory: ids.next,
      cacheFreshFor: const Duration(hours: 6),
    );
  }

  test(
    'manual override wins without a market request and is snapshotted',
    () async {
      final repository = createRepository();

      final result = await repository.resolveRate(
        baseCurrency: catalog.resolve('JPY'),
        quoteCurrency: catalog.resolve('CNY'),
        manualRate: ManualRateOverride(
          rate: DecimalValue.parse('0.05'),
          observedAt: DateTime.utc(2026, 8, 17, 9),
        ),
      );

      expect(result.availability, RateAvailability.manual);
      expect(result.snapshot!.rate, DecimalValue.parse('0.05'));
      expect(gateway.singleCalls, 0);
      expect(
        await snapshots.findById(result.snapshot!.metadata.recordId),
        isNotNull,
      );
    },
  );

  test(
    'available card-network placeholder precedes the market source',
    () async {
      final cardSnapshot = _snapshot(
        id: 'card-rate',
        base: catalog.resolve('USD'),
        quote: catalog.resolve('CNY'),
        rate: '7.22',
        fetchedAt: now,
        sourceType: RateSourceType.visa,
      );
      final repository = createRepository(
        cardNetworkRateProvider: FakeCardNetworkRateProvider(cardSnapshot),
      );

      final result = await repository.resolveRate(
        baseCurrency: catalog.resolve('USD'),
        quoteCurrency: catalog.resolve('CNY'),
      );

      expect(result.availability, RateAvailability.cardNetwork);
      expect(result.snapshot!.metadata.recordId, 'card-rate');
      expect(gateway.singleCalls, 0);
    },
  );

  test(
    'stored manual rate stays highest priority until explicitly cleared',
    () async {
      final repository = createRepository();
      await repository.resolveRate(
        baseCurrency: catalog.resolve('JPY'),
        quoteCurrency: catalog.resolve('CNY'),
        manualRate: ManualRateOverride(
          rate: DecimalValue.parse('0.05'),
          observedAt: DateTime.utc(2026, 8, 17, 9),
        ),
      );

      final stored = await repository.resolveRate(
        baseCurrency: catalog.resolve('JPY'),
        quoteCurrency: catalog.resolve('CNY'),
      );
      await repository.clearManualRate(
        baseCurrency: catalog.resolve('JPY'),
        quoteCurrency: catalog.resolve('CNY'),
      );
      gateway.singleResult = _dto(base: 'JPY', quote: 'CNY', rate: '0.048');
      final market = await repository.resolveRate(
        baseCurrency: catalog.resolve('JPY'),
        quoteCurrency: catalog.resolve('CNY'),
      );

      expect(stored.availability, RateAvailability.manual);
      expect(stored.snapshot!.rate, DecimalValue.parse('0.05'));
      expect(market.availability, RateAvailability.liveMarket);
      expect(market.snapshot!.rate, DecimalValue.parse('0.048'));
      expect(gateway.singleCalls, 1);
    },
  );

  test(
    'live market result separates fetched time from weekend source date',
    () async {
      gateway.singleResult = _dto(
        base: 'USD',
        quote: 'CNY',
        rate: '7.1842',
        date: DateTime.utc(2026, 8, 14),
      );
      final repository = createRepository();

      final result = await repository.resolveRate(
        baseCurrency: catalog.resolve('USD'),
        quoteCurrency: catalog.resolve('CNY'),
        date: DateTime.utc(2026, 8, 16),
      );

      expect(result.availability, RateAvailability.liveMarket);
      expect(result.snapshot!.sourceTimestamp, DateTime.utc(2026, 8, 14));
      expect(result.snapshot!.fetchedAt, now);
      expect(result.snapshot!.isCached, isFalse);
    },
  );

  test(
    'network failure falls back to fresh cache without overwriting it',
    () async {
      await snapshots.save(
        _snapshot(
          id: 'existing',
          base: catalog.resolve('USD'),
          quote: catalog.resolve('CNY'),
          rate: '7.1',
          fetchedAt: now.subtract(const Duration(hours: 1)),
        ),
      );
      gateway.singleError = const FrankfurterApiException(
        FrankfurterErrorCode.unavailable,
      );
      final repository = createRepository();

      final result = await repository.resolveRate(
        baseCurrency: catalog.resolve('USD'),
        quoteCurrency: catalog.resolve('CNY'),
      );

      expect(result.availability, RateAvailability.cachedMarket);
      expect(result.snapshot!.metadata.recordId, 'existing');
      expect(result.snapshot!.isCached, isTrue);
      expect(result.refreshError, FrankfurterErrorCode.unavailable);
      expect(await snapshots.findById('existing'), isNotNull);
    },
  );

  test('distinguishes stale cache and inverts the stored direction', () async {
    await snapshots.save(
      _snapshot(
        id: 'cny-usd',
        base: catalog.resolve('CNY'),
        quote: catalog.resolve('USD'),
        rate: '0.14',
        fetchedAt: now.subtract(const Duration(days: 2)),
      ),
    );
    final repository = createRepository();

    final result = await repository.resolveRate(
      baseCurrency: catalog.resolve('USD'),
      quoteCurrency: catalog.resolve('CNY'),
      allowNetwork: false,
    );

    expect(result.availability, RateAvailability.staleMarket);
    expect(result.snapshot!.rate.toFixed(8), '7.14285714');
    expect(result.snapshot!.baseCurrency.code, 'USD');
    expect(result.snapshot!.quoteCurrency.code, 'CNY');
    expect(result.snapshot!.isCached, isTrue);
  });

  test(
    'returns an explicit unavailable state when no source can resolve',
    () async {
      final result = await createRepository().resolveRate(
        baseCurrency: catalog.resolve('JPY'),
        quoteCurrency: catalog.resolve('CNY'),
        allowNetwork: false,
      );

      expect(result.availability, RateAvailability.unavailable);
      expect(result.snapshot, isNull);
      expect(result.requiresManualRate, isTrue);
    },
  );

  test('incomplete batch response is rejected before changing cache', () async {
    gateway.batchResult = <FrankfurterRateDto>[
      _dto(base: 'USD', quote: 'CNY', rate: '7.1'),
    ];
    final repository = createRepository();

    await expectLater(
      repository.refreshMarketRates(
        baseCurrency: catalog.resolve('USD'),
        quoteCurrencies: <money.Currency>[
          catalog.resolve('CNY'),
          catalog.resolve('JPY'),
        ],
      ),
      throwsA(isA<FrankfurterApiException>()),
    );
    final rows = await database
        .customSelect('SELECT * FROM rate_snapshots')
        .get();
    expect(rows, isEmpty);
  });
}

final class FakeGateway implements FrankfurterRatesGateway {
  FrankfurterRateDto? singleResult;
  List<FrankfurterRateDto> batchResult = <FrankfurterRateDto>[];
  FrankfurterApiException? singleError;
  int singleCalls = 0;
  int batchCalls = 0;

  @override
  Future<List<FrankfurterCurrencyDto>> getCurrencies() async =>
      <FrankfurterCurrencyDto>[];

  @override
  Future<FrankfurterRateDto> getRate({
    required String baseCurrencyCode,
    required String quoteCurrencyCode,
    DateTime? date,
  }) async {
    singleCalls += 1;
    if (singleError case final error?) {
      throw error;
    }
    return singleResult ??
        _dto(base: baseCurrencyCode, quote: quoteCurrencyCode, rate: '1');
  }

  @override
  Future<List<FrankfurterRateDto>> getRates({
    required String baseCurrencyCode,
    required Iterable<String> quoteCurrencyCodes,
    DateTime? date,
  }) async {
    batchCalls += 1;
    return batchResult;
  }
}

final class FakeCardNetworkRateProvider implements CardNetworkRateProvider {
  FakeCardNetworkRateProvider(this.snapshot);

  final RateSnapshotModel snapshot;

  @override
  Future<RateSnapshotModel?> findRate({
    required money.Currency baseCurrency,
    required money.Currency quoteCurrency,
    DateTime? date,
  }) async => snapshot;
}

final class Ids {
  int _value = 0;

  String next() => 'generated-${_value++}';
}

FrankfurterRateDto _dto({
  required String base,
  required String quote,
  required String rate,
  DateTime? date,
}) {
  return FrankfurterRateDto(
    date: date ?? DateTime.utc(2026, 8, 14),
    baseCurrencyCode: base,
    quoteCurrencyCode: quote,
    rate: DecimalValue.parse(rate),
  );
}

RateSnapshotModel _snapshot({
  required String id,
  required money.Currency base,
  required money.Currency quote,
  required String rate,
  required DateTime fetchedAt,
  RateSourceType sourceType = RateSourceType.market,
}) {
  return RateSnapshotModel(
    metadata: SyncRecordMetadata(
      recordId: id,
      syncVersion: 1,
      updatedAt: fetchedAt,
    ),
    baseCurrency: base,
    quoteCurrency: quote,
    rate: DecimalValue.parse(rate),
    sourceType: sourceType,
    sourceName: sourceType == RateSourceType.market
        ? ExchangeRateRepository.marketSourceName
        : sourceType.name,
    sourceTimestamp: DateTime.utc(2026, 8, 14),
    fetchedAt: fetchedAt,
    isCached: false,
  );
}
