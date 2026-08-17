import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/money/currency.dart';
import 'package:trip_cost/core/rates/application/rate_refresh_scheduler.dart';
import 'package:trip_cost/core/rates/domain/exchange_rate_repository.dart';
import 'package:trip_cost/core/storage/database/app_database.dart'
    show AppDatabase;

abstract interface class OfflinePackStatusStore {
  Future<void> recordUpdatedAt(String tripId, DateTime updatedAt);
}

final class DriftOfflinePackStatusStore implements OfflinePackStatusStore {
  DriftOfflinePackStatusStore(this._database);

  final AppDatabase _database;

  @override
  Future<void> recordUpdatedAt(String tripId, DateTime updatedAt) async {
    final count = await _database.coreDao.updateTripOfflinePackTimestamp(
      tripId,
      updatedAt.toUtc(),
    );
    if (count != 1) {
      throw StateError('Trip not found while recording offline pack status.');
    }
  }
}

final class OfflineRatePackStatus {
  const OfflineRatePackStatus({
    required this.isComplete,
    required this.snapshots,
    required this.cachedAt,
  });

  final bool isComplete;
  final List<RateSnapshotModel> snapshots;
  final DateTime? cachedAt;
}

final class OfflineRatePackDownload {
  const OfflineRatePackDownload({required this.refresh, required this.pack});

  final RateRefreshResult refresh;
  final OfflineRatePackStatus pack;
}

final class OfflineRatePackService {
  OfflineRatePackService({
    required RateRefreshScheduler refreshScheduler,
    required ExchangeRateRepository rateRepository,
    OfflinePackStatusStore? statusStore,
    DateTime Function()? clock,
  }) : _refreshScheduler = refreshScheduler,
       _rateRepository = rateRepository,
       _statusStore = statusStore,
       _clock = clock ?? (() => DateTime.now().toUtc());

  final RateRefreshScheduler _refreshScheduler;
  final ExchangeRateRepository _rateRepository;
  final OfflinePackStatusStore? _statusStore;
  final DateTime Function() _clock;

  Future<OfflineRatePackDownload> download({
    required String tripId,
    required Currency homeCurrency,
    required Iterable<Currency> localCurrencies,
    required bool wifiOnly,
  }) async {
    final locals = _uniqueLocals(homeCurrency, localCurrencies);
    final refresh = await _refreshScheduler.refreshIfNeeded(
      baseCurrency: homeCurrency,
      quoteCurrencies: locals,
      refreshInterval: const Duration(microseconds: 1),
      wifiOnly: wifiOnly,
      force: true,
    );
    final pack = await inspect(
      homeCurrency: homeCurrency,
      localCurrencies: locals,
    );
    if (refresh.status == RateRefreshStatus.refreshed && pack.isComplete) {
      await _statusStore?.recordUpdatedAt(tripId, _clock().toUtc());
    }
    return OfflineRatePackDownload(refresh: refresh, pack: pack);
  }

  Future<OfflineRatePackStatus> inspect({
    required Currency homeCurrency,
    required Iterable<Currency> localCurrencies,
  }) async {
    final locals = _uniqueLocals(homeCurrency, localCurrencies);
    final snapshots = <RateSnapshotModel>[];
    for (final local in locals) {
      final snapshot = await _rateRepository.latestCachedMarketRate(
        baseCurrency: homeCurrency,
        quoteCurrency: local,
      );
      if (snapshot != null) {
        snapshots.add(snapshot);
      }
    }
    DateTime? cachedAt;
    for (final snapshot in snapshots) {
      if (cachedAt == null || snapshot.fetchedAt.isBefore(cachedAt)) {
        cachedAt = snapshot.fetchedAt;
      }
    }
    return OfflineRatePackStatus(
      isComplete: locals.isNotEmpty && snapshots.length == locals.length,
      snapshots: List<RateSnapshotModel>.unmodifiable(snapshots),
      cachedAt: cachedAt,
    );
  }

  List<Currency> _uniqueLocals(
    Currency homeCurrency,
    Iterable<Currency> localCurrencies,
  ) {
    final byCode = <String, Currency>{
      for (final currency in localCurrencies)
        if (currency != homeCurrency) currency.code: currency,
    };
    final codes = byCode.keys.toList(growable: false)..sort();
    return <Currency>[for (final code in codes) byCode[code]!];
  }
}
