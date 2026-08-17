import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/money/currency.dart' as money;
import 'package:trip_cost/core/money/decimal_value.dart';
import 'package:trip_cost/core/rates/application/offline_rate_pack_service.dart';
import 'package:trip_cost/core/rates/application/rate_refresh_scheduler.dart';
import 'package:trip_cost/core/rates/data/drift_rate_snapshot_repository.dart';
import 'package:trip_cost/core/rates/data/frankfurter_api_client.dart';
import 'package:trip_cost/core/rates/data/frankfurter_dtos.dart';
import 'package:trip_cost/core/rates/domain/exchange_rate_repository.dart';
import 'package:trip_cost/core/storage/database/app_database.dart';

void main() {
  late AppDatabase database;
  late DriftRateSnapshotRepository snapshots;
  late SchedulerGateway gateway;
  late MutableClock clock;
  late FakeNetwork network;
  late ExchangeRateRepository repository;
  late RateRefreshScheduler scheduler;
  final catalog = money.CurrencyCatalog();

  setUp(() {
    database = AppDatabase.inMemory();
    clock = MutableClock(DateTime.utc(2026, 8, 17, 10));
    snapshots = DriftRateSnapshotRepository(database, clock: clock.call);
    gateway = SchedulerGateway();
    network = FakeNetwork(NetworkConnectionType.wifi);
    repository = ExchangeRateRepository(
      marketGateway: gateway,
      snapshotRepository: snapshots,
      clock: clock.call,
      idFactory: Ids().next,
    );
    scheduler = RateRefreshScheduler(
      rateRepository: repository,
      networkStatusProvider: network,
      clock: clock.call,
      initialBackoff: const Duration(minutes: 1),
      maximumBackoff: const Duration(minutes: 8),
    );
  });

  tearDown(() => database.close());

  test('cold start without network or cache requires a manual rate', () async {
    network.value = NetworkConnectionType.offline;

    final result = await scheduler.refreshIfNeeded(
      baseCurrency: catalog.resolve('USD'),
      quoteCurrencies: <money.Currency>[catalog.resolve('CNY')],
      refreshInterval: const Duration(hours: 6),
      wifiOnly: false,
    );

    expect(result.status, RateRefreshStatus.manualRequired);
    expect(result.requiresManualRate, isTrue);
    expect(gateway.batchCalls, 0);
  });

  test(
    'offline mode keeps cached rates and their original cache time',
    () async {
      final fetchedAt = clock.now.subtract(const Duration(days: 1));
      await snapshots.save(
        _snapshot(
          id: 'cached',
          base: catalog.resolve('USD'),
          quote: catalog.resolve('CNY'),
          fetchedAt: fetchedAt,
        ),
      );
      network.value = NetworkConnectionType.offline;

      final result = await scheduler.refreshIfNeeded(
        baseCurrency: catalog.resolve('USD'),
        quoteCurrencies: <money.Currency>[catalog.resolve('CNY')],
        refreshInterval: const Duration(hours: 6),
        wifiOnly: false,
      );

      expect(result.status, RateRefreshStatus.cacheAvailableOffline);
      expect(result.snapshots.single.fetchedAt, fetchedAt);
      expect(gateway.batchCalls, 0);
    },
  );

  test('fresh cache skips network during cold-start expiry check', () async {
    await snapshots.save(
      _snapshot(
        id: 'fresh',
        base: catalog.resolve('USD'),
        quote: catalog.resolve('JPY'),
        fetchedAt: clock.now.subtract(const Duration(hours: 1)),
      ),
    );

    final result = await scheduler.refreshIfNeeded(
      baseCurrency: catalog.resolve('USD'),
      quoteCurrencies: <money.Currency>[catalog.resolve('JPY')],
      refreshInterval: const Duration(hours: 6),
      wifiOnly: false,
    );

    expect(result.status, RateRefreshStatus.freshCache);
    expect(gateway.batchCalls, 0);
    expect(network.calls, 0);
  });

  test(
    'wifi-only policy blocks cellular refresh without losing cache',
    () async {
      await snapshots.save(
        _snapshot(
          id: 'old',
          base: catalog.resolve('USD'),
          quote: catalog.resolve('CNY'),
          fetchedAt: clock.now.subtract(const Duration(days: 1)),
        ),
      );
      network.value = NetworkConnectionType.cellular;

      final result = await scheduler.refreshIfNeeded(
        baseCurrency: catalog.resolve('USD'),
        quoteCurrencies: <money.Currency>[catalog.resolve('CNY')],
        refreshInterval: const Duration(hours: 6),
        wifiOnly: true,
      );

      expect(result.status, RateRefreshStatus.wifiRequired);
      expect(result.snapshots, hasLength(1));
      expect(gateway.batchCalls, 0);
    },
  );

  test('merges concurrent refreshes into one network request', () async {
    final completer = Completer<List<FrankfurterRateDto>>();
    gateway.deferredBatch = completer.future;

    final first = scheduler.refreshIfNeeded(
      baseCurrency: catalog.resolve('USD'),
      quoteCurrencies: <money.Currency>[
        catalog.resolve('JPY'),
        catalog.resolve('CNY'),
      ],
      refreshInterval: const Duration(hours: 6),
      wifiOnly: false,
    );
    final second = scheduler.refreshIfNeeded(
      baseCurrency: catalog.resolve('USD'),
      quoteCurrencies: <money.Currency>[
        catalog.resolve('CNY'),
        catalog.resolve('JPY'),
      ],
      refreshInterval: const Duration(hours: 6),
      wifiOnly: false,
    );
    await Future<void>.delayed(Duration.zero);
    completer.complete(<FrankfurterRateDto>[
      _dto('USD', 'CNY', '7.18'),
      _dto('USD', 'JPY', '147.2'),
    ]);

    final results = await Future.wait(<Future<RateRefreshResult>>[
      first,
      second,
    ]);
    expect(
      results.every((item) => item.status == RateRefreshStatus.refreshed),
      isTrue,
    );
    expect(gateway.batchCalls, 1);
  });

  test('applies exponential backoff after a failed refresh', () async {
    gateway.batchError = const FrankfurterApiException(
      FrankfurterErrorCode.unavailable,
    );

    final first = await scheduler.refreshIfNeeded(
      baseCurrency: catalog.resolve('USD'),
      quoteCurrencies: <money.Currency>[catalog.resolve('CNY')],
      refreshInterval: const Duration(hours: 6),
      wifiOnly: false,
    );
    final blocked = await scheduler.refreshIfNeeded(
      baseCurrency: catalog.resolve('USD'),
      quoteCurrencies: <money.Currency>[catalog.resolve('CNY')],
      refreshInterval: const Duration(hours: 6),
      wifiOnly: false,
    );
    clock.advance(const Duration(minutes: 1));
    final secondFailure = await scheduler.refreshIfNeeded(
      baseCurrency: catalog.resolve('USD'),
      quoteCurrencies: <money.Currency>[catalog.resolve('CNY')],
      refreshInterval: const Duration(hours: 6),
      wifiOnly: false,
    );

    expect(first.status, RateRefreshStatus.manualRequired);
    expect(first.nextRetryAt, DateTime.utc(2026, 8, 17, 10, 1));
    expect(blocked.status, RateRefreshStatus.backoff);
    expect(secondFailure.nextRetryAt, DateTime.utc(2026, 8, 17, 10, 3));
    expect(gateway.batchCalls, 2);
  });

  test(
    'offline pack downloads all pairs in one batch and records status',
    () async {
      gateway.batchResult = <FrankfurterRateDto>[
        _dto('CNY', 'EUR', '0.119'),
        _dto('CNY', 'JPY', '20.48'),
      ];
      final statusStore = FakeOfflinePackStatusStore();
      final service = OfflineRatePackService(
        refreshScheduler: scheduler,
        rateRepository: repository,
        statusStore: statusStore,
        clock: clock.call,
      );

      final download = await service.download(
        tripId: 'trip-1',
        homeCurrency: catalog.resolve('CNY'),
        localCurrencies: <money.Currency>[
          catalog.resolve('JPY'),
          catalog.resolve('EUR'),
          catalog.resolve('JPY'),
        ],
        wifiOnly: false,
      );

      expect(download.refresh.status, RateRefreshStatus.refreshed);
      expect(download.pack.isComplete, isTrue);
      expect(download.pack.cachedAt, clock.now);
      expect(gateway.batchCalls, 1);
      expect(statusStore.records, <String, DateTime>{'trip-1': clock.now});
    },
  );
}

final class SchedulerGateway implements FrankfurterRatesGateway {
  List<FrankfurterRateDto> batchResult = <FrankfurterRateDto>[];
  Future<List<FrankfurterRateDto>>? deferredBatch;
  FrankfurterApiException? batchError;
  int batchCalls = 0;

  @override
  Future<List<FrankfurterCurrencyDto>> getCurrencies() async =>
      <FrankfurterCurrencyDto>[];

  @override
  Future<FrankfurterRateDto> getRate({
    required String baseCurrencyCode,
    required String quoteCurrencyCode,
    DateTime? date,
  }) async => _dto(baseCurrencyCode, quoteCurrencyCode, '1');

  @override
  Future<List<FrankfurterRateDto>> getRates({
    required String baseCurrencyCode,
    required Iterable<String> quoteCurrencyCodes,
    DateTime? date,
  }) {
    batchCalls += 1;
    if (batchError case final error?) {
      throw error;
    }
    return deferredBatch ?? Future<List<FrankfurterRateDto>>.value(batchResult);
  }
}

final class FakeNetwork implements NetworkStatusProvider {
  FakeNetwork(this.value);

  NetworkConnectionType value;
  int calls = 0;

  @override
  Future<NetworkConnectionType> current() async {
    calls += 1;
    return value;
  }
}

final class MutableClock {
  MutableClock(this.now);

  DateTime now;

  DateTime call() => now;

  void advance(Duration duration) {
    now = now.add(duration);
  }
}

final class Ids {
  int value = 0;

  String next() => 'rate-${value++}';
}

final class FakeOfflinePackStatusStore implements OfflinePackStatusStore {
  final Map<String, DateTime> records = <String, DateTime>{};

  @override
  Future<void> recordUpdatedAt(String tripId, DateTime updatedAt) async {
    records[tripId] = updatedAt;
  }
}

FrankfurterRateDto _dto(String base, String quote, String rate) {
  return FrankfurterRateDto(
    date: DateTime.utc(2026, 8, 14),
    baseCurrencyCode: base,
    quoteCurrencyCode: quote,
    rate: DecimalValue.parse(rate),
  );
}

RateSnapshotModel _snapshot({
  required String id,
  required money.Currency base,
  required money.Currency quote,
  required DateTime fetchedAt,
}) {
  return RateSnapshotModel(
    metadata: SyncRecordMetadata(
      recordId: id,
      syncVersion: 1,
      updatedAt: fetchedAt,
    ),
    baseCurrency: base,
    quoteCurrency: quote,
    rate: DecimalValue.parse('7.1'),
    sourceType: RateSourceType.market,
    sourceName: ExchangeRateRepository.marketSourceName,
    sourceTimestamp: DateTime.utc(2026, 8, 14),
    fetchedAt: fetchedAt,
    isCached: false,
  );
}
