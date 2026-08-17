import 'dart:async';

import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/money/currency.dart';
import 'package:trip_cost/core/rates/data/frankfurter_api_client.dart';
import 'package:trip_cost/core/rates/domain/exchange_rate_repository.dart';

enum NetworkConnectionType { offline, wifi, cellular, other }

abstract interface class NetworkStatusProvider {
  Future<NetworkConnectionType> current();
}

enum RateRefreshStatus {
  refreshed,
  freshCache,
  cacheAvailableOffline,
  wifiRequired,
  backoff,
  refreshFailedUsingCache,
  manualRequired,
}

final class RateRefreshResult {
  const RateRefreshResult({
    required this.status,
    required this.snapshots,
    this.error,
    this.nextRetryAt,
  });

  final RateRefreshStatus status;
  final List<RateSnapshotModel> snapshots;
  final FrankfurterErrorCode? error;
  final DateTime? nextRetryAt;

  bool get hasCachedRates => snapshots.isNotEmpty;
  bool get requiresManualRate =>
      snapshots.isEmpty &&
      status != RateRefreshStatus.refreshed &&
      status != RateRefreshStatus.freshCache;
}

final class RateRefreshScheduler {
  RateRefreshScheduler({
    required ExchangeRateRepository rateRepository,
    required NetworkStatusProvider networkStatusProvider,
    DateTime Function()? clock,
    this.initialBackoff = const Duration(seconds: 30),
    this.maximumBackoff = const Duration(minutes: 30),
  }) : _rateRepository = rateRepository,
       _networkStatusProvider = networkStatusProvider,
       _clock = clock ?? (() => DateTime.now().toUtc()) {
    if (initialBackoff <= Duration.zero || maximumBackoff < initialBackoff) {
      throw const FormatException('Invalid refresh backoff configuration.');
    }
  }

  final ExchangeRateRepository _rateRepository;
  final NetworkStatusProvider _networkStatusProvider;
  final DateTime Function() _clock;
  final Duration initialBackoff;
  final Duration maximumBackoff;
  final Map<String, Future<RateRefreshResult>> _inFlight =
      <String, Future<RateRefreshResult>>{};
  final Map<String, _BackoffState> _backoffs = <String, _BackoffState>{};

  Future<RateRefreshResult> refreshIfNeeded({
    required Currency baseCurrency,
    required Iterable<Currency> quoteCurrencies,
    required Duration refreshInterval,
    required bool wifiOnly,
    bool force = false,
  }) {
    if (refreshInterval <= Duration.zero) {
      throw const FormatException('Refresh interval must be positive.');
    }
    final quotes = <String, Currency>{
      for (final currency in quoteCurrencies)
        if (currency != baseCurrency) currency.code: currency,
    };
    final quoteCodes = quotes.keys.toList(growable: false)..sort();
    final rateSetKey = '${baseCurrency.code}:${quoteCodes.join(',')}';
    final operationKey =
        '$rateSetKey:${refreshInterval.inMicroseconds}:'
        '$wifiOnly:$force';
    final existing = _inFlight[operationKey];
    if (existing != null) {
      return existing;
    }
    final future = _refresh(
      key: rateSetKey,
      baseCurrency: baseCurrency,
      quotes: <Currency>[for (final code in quoteCodes) quotes[code]!],
      refreshInterval: refreshInterval,
      wifiOnly: wifiOnly,
      force: force,
    );
    _inFlight[operationKey] = future;
    return future.whenComplete(() {
      if (identical(_inFlight[operationKey], future)) {
        _inFlight.remove(operationKey);
      }
    });
  }

  Future<RateRefreshResult> _refresh({
    required String key,
    required Currency baseCurrency,
    required List<Currency> quotes,
    required Duration refreshInterval,
    required bool wifiOnly,
    required bool force,
  }) async {
    if (quotes.isEmpty) {
      return const RateRefreshResult(
        status: RateRefreshStatus.freshCache,
        snapshots: <RateSnapshotModel>[],
      );
    }
    final now = _clock().toUtc();
    final cached = await _loadCache(baseCurrency, quotes);
    final complete = cached.length == quotes.length;
    final fresh =
        complete &&
        cached.every(
          (snapshot) => now.difference(snapshot.fetchedAt) <= refreshInterval,
        );
    if (fresh && !force) {
      return RateRefreshResult(
        status: RateRefreshStatus.freshCache,
        snapshots: cached,
      );
    }

    final network = await _networkStatusProvider.current();
    if (network == NetworkConnectionType.offline) {
      return RateRefreshResult(
        status: complete
            ? RateRefreshStatus.cacheAvailableOffline
            : RateRefreshStatus.manualRequired,
        snapshots: cached,
      );
    }
    if (wifiOnly && network != NetworkConnectionType.wifi) {
      return RateRefreshResult(
        status: RateRefreshStatus.wifiRequired,
        snapshots: cached,
      );
    }

    final backoff = _backoffs[key];
    if (backoff != null && now.isBefore(backoff.nextRetryAt)) {
      return RateRefreshResult(
        status: RateRefreshStatus.backoff,
        snapshots: cached,
        nextRetryAt: backoff.nextRetryAt,
      );
    }

    try {
      final refreshed = await _rateRepository.refreshMarketRates(
        baseCurrency: baseCurrency,
        quoteCurrencies: quotes,
      );
      _backoffs.remove(key);
      return RateRefreshResult(
        status: RateRefreshStatus.refreshed,
        snapshots: refreshed,
      );
    } on FrankfurterApiException catch (error) {
      final failures = (backoff?.failures ?? 0) + 1;
      final delay = _backoffDelay(failures);
      final nextRetryAt = now.add(delay);
      _backoffs[key] = _BackoffState(
        failures: failures,
        nextRetryAt: nextRetryAt,
      );
      return RateRefreshResult(
        status: complete
            ? RateRefreshStatus.refreshFailedUsingCache
            : RateRefreshStatus.manualRequired,
        snapshots: cached,
        error: error.code,
        nextRetryAt: nextRetryAt,
      );
    }
  }

  Future<List<RateSnapshotModel>> _loadCache(
    Currency base,
    List<Currency> quotes,
  ) async {
    final snapshots = <RateSnapshotModel>[];
    for (final quote in quotes) {
      final snapshot = await _rateRepository.latestCachedMarketRate(
        baseCurrency: base,
        quoteCurrency: quote,
      );
      if (snapshot != null) {
        snapshots.add(snapshot);
      }
    }
    return snapshots;
  }

  Duration _backoffDelay(int failures) {
    final exponent = failures > 20 ? 20 : failures - 1;
    final candidate = initialBackoff * (1 << exponent);
    return candidate > maximumBackoff ? maximumBackoff : candidate;
  }
}

final class _BackoffState {
  const _BackoffState({required this.failures, required this.nextRetryAt});

  final int failures;
  final DateTime nextRetryAt;
}
