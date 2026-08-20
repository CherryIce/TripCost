import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/domain/repositories.dart';
import 'package:trip_cost/core/money/currency.dart';
import 'package:trip_cost/core/money/decimal_value.dart';
import 'package:trip_cost/core/rates/data/frankfurter_api_client.dart';
import 'package:trip_cost/core/rates/data/frankfurter_dtos.dart';
import 'package:uuid/uuid.dart';

enum RateAvailability {
  liveMarket,
  cachedMarket,
  staleMarket,
  manual,
  cardNetwork,
  identity,
  unavailable,
}

final class ManualRateOverride {
  ManualRateOverride({
    required this.rate,
    required DateTime observedAt,
    this.sourceName = 'Manual',
  }) : observedAt = requireUtc(observedAt, 'observedAt') {
    if (rate.compareTo(DecimalValue.zero) <= 0) {
      throw const FormatException('Manual exchange rate must be positive.');
    }
  }

  final DecimalValue rate;
  final DateTime observedAt;
  final String sourceName;
}

final class RateResolution {
  const RateResolution({
    required this.availability,
    required this.snapshot,
    this.refreshError,
  });

  final RateAvailability availability;
  final RateSnapshotModel? snapshot;
  final FrankfurterErrorCode? refreshError;

  bool get requiresManualRate => snapshot == null;
}

abstract interface class CardNetworkRateProvider {
  Future<RateSnapshotModel?> findRate({
    required Currency baseCurrency,
    required Currency quoteCurrency,
    DateTime? date,
  });
}

final class ExchangeRateRepository implements CacheRepositoryObserver {
  ExchangeRateRepository({
    required FrankfurterRatesGateway marketGateway,
    required RateSnapshotRepository snapshotRepository,
    CardNetworkRateProvider? cardNetworkRateProvider,
    CurrencyCatalog? currencyCatalog,
    DateTime Function()? clock,
    String Function()? idFactory,
    this.cacheFreshFor = const Duration(hours: 6),
  }) : _marketGateway = marketGateway,
       _snapshotRepository = snapshotRepository,
       _cardNetworkRateProvider = cardNetworkRateProvider,
       _currencyCatalog = currencyCatalog ?? CurrencyCatalog(),
       _clock = clock ?? (() => DateTime.now().toUtc()),
       _idFactory = idFactory ?? const Uuid().v4;

  static const String marketSourceName = 'Frankfurter v2';

  final FrankfurterRatesGateway _marketGateway;
  final RateSnapshotRepository _snapshotRepository;
  final CardNetworkRateProvider? _cardNetworkRateProvider;
  final CurrencyCatalog _currencyCatalog;
  final DateTime Function() _clock;
  final String Function() _idFactory;
  final Duration cacheFreshFor;

  @override
  Stream<void> watchChanges() => _snapshotRepository is CacheRepositoryObserver
      ? (_snapshotRepository as CacheRepositoryObserver).watchChanges()
      : const Stream<void>.empty();

  Future<RateResolution> resolveRate({
    required Currency baseCurrency,
    required Currency quoteCurrency,
    DateTime? date,
    ManualRateOverride? manualRate,
    bool allowNetwork = true,
  }) async {
    final now = _clock().toUtc();
    if (baseCurrency == quoteCurrency) {
      final snapshot = _snapshot(
        baseCurrency: baseCurrency,
        quoteCurrency: quoteCurrency,
        rate: DecimalValue.parse('1'),
        sourceType: RateSourceType.market,
        sourceName: 'Identity',
        sourceTimestamp: _dateOnly(date ?? now),
        fetchedAt: now,
        isCached: false,
      );
      return RateResolution(
        availability: RateAvailability.identity,
        snapshot: snapshot,
      );
    }

    if (manualRate != null) {
      await clearManualRate(
        baseCurrency: baseCurrency,
        quoteCurrency: quoteCurrency,
      );
      final snapshot = _snapshot(
        baseCurrency: baseCurrency,
        quoteCurrency: quoteCurrency,
        rate: manualRate.rate,
        sourceType: RateSourceType.manual,
        sourceName: manualRate.sourceName,
        sourceTimestamp: manualRate.observedAt,
        fetchedAt: now,
        isCached: false,
      );
      await _snapshotRepository.save(snapshot);
      return RateResolution(
        availability: RateAvailability.manual,
        snapshot: snapshot,
      );
    }

    final storedManual = await _storedManualRate(
      baseCurrency: baseCurrency,
      quoteCurrency: quoteCurrency,
      now: now,
    );
    if (storedManual != null) {
      return RateResolution(
        availability: RateAvailability.manual,
        snapshot: storedManual,
      );
    }

    final cardRate = await _cardNetworkRateProvider?.findRate(
      baseCurrency: baseCurrency,
      quoteCurrency: quoteCurrency,
      date: date,
    );
    if (cardRate != null) {
      await _snapshotRepository.save(cardRate);
      return RateResolution(
        availability: RateAvailability.cardNetwork,
        snapshot: cardRate,
      );
    }

    FrankfurterErrorCode? refreshError;
    if (allowNetwork) {
      try {
        final dto = await _marketGateway.getRate(
          baseCurrencyCode: baseCurrency.code,
          quoteCurrencyCode: quoteCurrency.code,
          date: date,
        );
        _validatePair(dto, baseCurrency.code, quoteCurrency.code);
        final snapshot = _marketSnapshot(dto, fetchedAt: now);
        await _snapshotRepository.save(snapshot);
        return RateResolution(
          availability: RateAvailability.liveMarket,
          snapshot: snapshot,
        );
      } on FrankfurterApiException catch (error) {
        refreshError = error.code;
      }
    }

    final cached = await _cachedMarketRate(
      baseCurrency: baseCurrency,
      quoteCurrency: quoteCurrency,
      sourceAtOrBefore: date == null ? null : _endOfUtcDay(date),
      now: now,
    );
    if (cached == null) {
      return RateResolution(
        availability: RateAvailability.unavailable,
        snapshot: null,
        refreshError: refreshError,
      );
    }
    final stale = now.difference(cached.fetchedAt) > cacheFreshFor;
    return RateResolution(
      availability: stale
          ? RateAvailability.staleMarket
          : RateAvailability.cachedMarket,
      snapshot: cached,
      refreshError: refreshError,
    );
  }

  Future<List<RateSnapshotModel>> refreshMarketRates({
    required Currency baseCurrency,
    required Iterable<Currency> quoteCurrencies,
    DateTime? date,
  }) async {
    final quotes = <String, Currency>{
      for (final currency in quoteCurrencies)
        if (currency != baseCurrency) currency.code: currency,
    };
    if (quotes.isEmpty) {
      return const <RateSnapshotModel>[];
    }
    final dtos = await _marketGateway.getRates(
      baseCurrencyCode: baseCurrency.code,
      quoteCurrencyCodes: quotes.keys,
      date: date,
    );
    final byQuote = <String, FrankfurterRateDto>{
      for (final dto in dtos)
        if (dto.baseCurrencyCode == baseCurrency.code &&
            quotes.containsKey(dto.quoteCurrencyCode))
          dto.quoteCurrencyCode: dto,
    };
    if (byQuote.length != quotes.length) {
      throw const FrankfurterApiException(
        FrankfurterErrorCode.malformedResponse,
      );
    }
    final fetchedAt = _clock().toUtc();
    final snapshots = <RateSnapshotModel>[
      for (final quote in quotes.keys)
        _marketSnapshot(byQuote[quote]!, fetchedAt: fetchedAt),
    ];
    for (final snapshot in snapshots) {
      await _snapshotRepository.save(snapshot);
    }
    return snapshots;
  }

  Future<void> clearManualRate({
    required Currency baseCurrency,
    required Currency quoteCurrency,
  }) async {
    final now = _clock().toUtc();
    await _snapshotRepository.softDeleteForPairAndSource(
      baseCurrencyCode: baseCurrency.code,
      quoteCurrencyCode: quoteCurrency.code,
      sourceType: RateSourceType.manual,
      deletedAtUtc: now,
    );
    if (baseCurrency != quoteCurrency) {
      await _snapshotRepository.softDeleteForPairAndSource(
        baseCurrencyCode: quoteCurrency.code,
        quoteCurrencyCode: baseCurrency.code,
        sourceType: RateSourceType.manual,
        deletedAtUtc: now,
      );
    }
  }

  Future<RateSnapshotModel?> latestCachedMarketRate({
    required Currency baseCurrency,
    required Currency quoteCurrency,
    DateTime? sourceAtOrBefore,
  }) {
    return _cachedMarketRate(
      baseCurrency: baseCurrency,
      quoteCurrency: quoteCurrency,
      sourceAtOrBefore: sourceAtOrBefore,
      now: _clock().toUtc(),
    );
  }

  Future<RateSnapshotModel?> _cachedMarketRate({
    required Currency baseCurrency,
    required Currency quoteCurrency,
    required DateTime? sourceAtOrBefore,
    required DateTime now,
  }) async {
    final direct = await _snapshotRepository.findLatest(
      baseCurrencyCode: baseCurrency.code,
      quoteCurrencyCode: quoteCurrency.code,
      sourceType: RateSourceType.market,
      sourceAtOrBefore: sourceAtOrBefore,
    );
    if (direct != null) {
      return _copyAsCached(direct);
    }
    final inverse = await _snapshotRepository.findLatest(
      baseCurrencyCode: quoteCurrency.code,
      quoteCurrencyCode: baseCurrency.code,
      sourceType: RateSourceType.market,
      sourceAtOrBefore: sourceAtOrBefore,
    );
    if (inverse == null) {
      return null;
    }
    final inverted = _snapshot(
      baseCurrency: baseCurrency,
      quoteCurrency: quoteCurrency,
      rate: DecimalValue.parse('1').divide(inverse.rate),
      sourceType: inverse.sourceType,
      sourceName: inverse.sourceName,
      sourceTimestamp: inverse.sourceTimestamp,
      fetchedAt: inverse.fetchedAt,
      isCached: true,
      updatedAt: now,
    );
    await _snapshotRepository.save(inverted);
    return inverted;
  }

  Future<RateSnapshotModel?> _storedManualRate({
    required Currency baseCurrency,
    required Currency quoteCurrency,
    required DateTime now,
  }) async {
    final direct = await _snapshotRepository.findLatest(
      baseCurrencyCode: baseCurrency.code,
      quoteCurrencyCode: quoteCurrency.code,
      sourceType: RateSourceType.manual,
    );
    if (direct != null) {
      return direct;
    }
    final inverse = await _snapshotRepository.findLatest(
      baseCurrencyCode: quoteCurrency.code,
      quoteCurrencyCode: baseCurrency.code,
      sourceType: RateSourceType.manual,
    );
    if (inverse == null) {
      return null;
    }
    final inverted = _snapshot(
      baseCurrency: baseCurrency,
      quoteCurrency: quoteCurrency,
      rate: DecimalValue.parse('1').divide(inverse.rate),
      sourceType: RateSourceType.manual,
      sourceName: inverse.sourceName,
      sourceTimestamp: inverse.sourceTimestamp,
      fetchedAt: inverse.fetchedAt,
      isCached: false,
      updatedAt: now,
    );
    await _snapshotRepository.save(inverted);
    return inverted;
  }

  RateSnapshotModel _marketSnapshot(
    FrankfurterRateDto dto, {
    required DateTime fetchedAt,
  }) {
    return _snapshot(
      baseCurrency: _currencyCatalog.resolve(dto.baseCurrencyCode),
      quoteCurrency: _currencyCatalog.resolve(dto.quoteCurrencyCode),
      rate: dto.rate,
      sourceType: RateSourceType.market,
      sourceName: marketSourceName,
      sourceTimestamp: dto.date,
      fetchedAt: fetchedAt,
      isCached: false,
    );
  }

  RateSnapshotModel _copyAsCached(RateSnapshotModel snapshot) {
    return RateSnapshotModel(
      metadata: snapshot.metadata,
      baseCurrency: snapshot.baseCurrency,
      quoteCurrency: snapshot.quoteCurrency,
      rate: snapshot.rate,
      sourceType: snapshot.sourceType,
      sourceName: snapshot.sourceName,
      sourceTimestamp: snapshot.sourceTimestamp,
      fetchedAt: snapshot.fetchedAt,
      isCached: true,
    );
  }

  RateSnapshotModel _snapshot({
    required Currency baseCurrency,
    required Currency quoteCurrency,
    required DecimalValue rate,
    required RateSourceType sourceType,
    required String sourceName,
    required DateTime sourceTimestamp,
    required DateTime fetchedAt,
    required bool isCached,
    DateTime? updatedAt,
  }) {
    final now = (updatedAt ?? _clock()).toUtc();
    return RateSnapshotModel(
      metadata: SyncRecordMetadata(
        recordId: _idFactory(),
        syncVersion: 1,
        updatedAt: now,
      ),
      baseCurrency: baseCurrency,
      quoteCurrency: quoteCurrency,
      rate: rate,
      sourceType: sourceType,
      sourceName: sourceName,
      sourceTimestamp: sourceTimestamp.toUtc(),
      fetchedAt: fetchedAt.toUtc(),
      isCached: isCached,
    );
  }
}

void _validatePair(FrankfurterRateDto dto, String base, String quote) {
  if (dto.baseCurrencyCode != base || dto.quoteCurrencyCode != quote) {
    throw const FrankfurterApiException(FrankfurterErrorCode.malformedResponse);
  }
}

DateTime _dateOnly(DateTime value) {
  return DateTime.utc(value.year, value.month, value.day);
}

DateTime _endOfUtcDay(DateTime value) {
  return DateTime.utc(value.year, value.month, value.day, 23, 59, 59, 999, 999);
}
