import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/money/currency.dart' as money;
import 'package:trip_cost/core/money/decimal_value.dart';
import 'package:trip_cost/core/rates/data/drift_rate_snapshot_repository.dart';
import 'package:trip_cost/core/storage/database/app_database.dart';

void main() {
  late AppDatabase database;
  late DriftRateSnapshotRepository repository;
  final now = DateTime.utc(2026, 8, 17, 10);
  final catalog = money.CurrencyCatalog();

  setUp(() {
    database = AppDatabase.inMemory();
    repository = DriftRateSnapshotRepository(database, clock: () => now);
  });

  tearDown(() => database.close());

  test('persists and restores an exact decimal rate snapshot', () async {
    final snapshot = _snapshot(
      id: 'rate-1',
      base: catalog.resolve('JPY'),
      quote: catalog.resolve('CNY'),
      rate: '0.04784123',
      fetchedAt: now,
    );

    await repository.save(snapshot);
    final restored = await repository.findById('rate-1');

    expect(restored, isNotNull);
    expect(restored!.rate, DecimalValue.parse('0.04784123'));
    expect(restored.baseCurrency.code, 'JPY');
    expect(restored.quoteCurrency.code, 'CNY');
    expect(restored.sourceTimestamp, DateTime.utc(2026, 8, 14));
  });

  test('findLatest filters source and historical observation date', () async {
    await repository.save(
      _snapshot(
        id: 'older-market',
        base: catalog.resolve('USD'),
        quote: catalog.resolve('CNY'),
        rate: '7.1',
        fetchedAt: now.subtract(const Duration(days: 3)),
        sourceTimestamp: DateTime.utc(2026, 8, 13),
      ),
    );
    await repository.save(
      _snapshot(
        id: 'newer-market',
        base: catalog.resolve('USD'),
        quote: catalog.resolve('CNY'),
        rate: '7.2',
        fetchedAt: now,
        sourceTimestamp: DateTime.utc(2026, 8, 14),
      ),
    );
    await repository.save(
      _snapshot(
        id: 'manual',
        base: catalog.resolve('USD'),
        quote: catalog.resolve('CNY'),
        rate: '7.3',
        fetchedAt: now,
        sourceTimestamp: DateTime.utc(2026, 8, 12),
        sourceType: RateSourceType.manual,
      ),
    );

    final historical = await repository.findLatest(
      baseCurrencyCode: 'usd',
      quoteCurrencyCode: 'cny',
      sourceType: RateSourceType.market,
      sourceAtOrBefore: DateTime.utc(2026, 8, 13, 23, 59),
    );

    expect(historical!.metadata.recordId, 'older-market');
  });
}

RateSnapshotModel _snapshot({
  required String id,
  required money.Currency base,
  required money.Currency quote,
  required String rate,
  required DateTime fetchedAt,
  DateTime? sourceTimestamp,
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
    sourceName: sourceType == RateSourceType.manual
        ? 'Manual'
        : 'Frankfurter v2',
    sourceTimestamp: sourceTimestamp ?? DateTime.utc(2026, 8, 14),
    fetchedAt: fetchedAt,
    isCached: false,
  );
}
