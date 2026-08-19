import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/domain/repositories.dart';
import 'package:trip_cost/core/infrastructure/app_providers.dart';
import 'package:trip_cost/core/money/currency.dart';
import 'package:trip_cost/core/money/decimal_value.dart';
import 'package:trip_cost/core/money/expression_parser.dart';
import 'package:trip_cost/core/money/money.dart';
import 'package:trip_cost/core/rates/application/rate_refresh_scheduler.dart';
import 'package:trip_cost/core/rates/domain/exchange_rate_repository.dart';
import 'package:trip_cost/core/storage/settings/drift_settings_repository.dart';

final converterControllerProvider =
    AsyncNotifierProvider<ConverterController, ConverterState>(
      ConverterController.new,
    );

final class ConversionDraft {
  const ConversionDraft({
    required this.transactionAmount,
    required this.rateResolution,
    this.receiptLocalPath,
  });

  final Money transactionAmount;
  final RateResolution rateResolution;
  final String? receiptLocalPath;
}

final class ConverterState {
  const ConverterState({
    required this.expression,
    required this.transactionCurrency,
    required this.homeCurrency,
    required this.evaluatedAmount,
    required this.expressionError,
    required this.rateResolution,
    required this.isResolvingRate,
  });

  final String expression;
  final Currency transactionCurrency;
  final Currency homeCurrency;
  final DecimalValue? evaluatedAmount;
  final ExpressionErrorCode? expressionError;
  final RateResolution? rateResolution;
  final bool isResolvingRate;

  bool get canConvert =>
      evaluatedAmount != null &&
      evaluatedAmount!.compareTo(DecimalValue.zero) > 0 &&
      rateResolution?.snapshot != null;

  Money? get transactionMoney => evaluatedAmount == null
      ? null
      : Money(amount: evaluatedAmount!, currency: transactionCurrency);

  Money? get convertedMoney {
    final snapshot = rateResolution?.snapshot;
    if (snapshot == null || evaluatedAmount == null) {
      return null;
    }
    return Money(
      amount: evaluatedAmount! * snapshot.rate,
      currency: homeCurrency,
    );
  }

  ConversionDraft? get draft {
    if (!canConvert) {
      return null;
    }
    return ConversionDraft(
      transactionAmount: transactionMoney!,
      rateResolution: rateResolution!,
    );
  }

  ConverterState copyWith({
    String? expression,
    Currency? transactionCurrency,
    Currency? homeCurrency,
    Object? evaluatedAmount = _unchanged,
    Object? expressionError = _unchanged,
    Object? rateResolution = _unchanged,
    bool? isResolvingRate,
  }) {
    return ConverterState(
      expression: expression ?? this.expression,
      transactionCurrency: transactionCurrency ?? this.transactionCurrency,
      homeCurrency: homeCurrency ?? this.homeCurrency,
      evaluatedAmount: identical(evaluatedAmount, _unchanged)
          ? this.evaluatedAmount
          : evaluatedAmount as DecimalValue?,
      expressionError: identical(expressionError, _unchanged)
          ? this.expressionError
          : expressionError as ExpressionErrorCode?,
      rateResolution: identical(rateResolution, _unchanged)
          ? this.rateResolution
          : rateResolution as RateResolution?,
      isResolvingRate: isResolvingRate ?? this.isResolvingRate,
    );
  }
}

const Object _unchanged = Object();

final class ConverterController extends AsyncNotifier<ConverterState> {
  static const DecimalExpressionParser _parser = DecimalExpressionParser();

  late SettingsRepository _settingsRepository;
  UserSettingsModel? _settings;
  var _resolutionGeneration = 0;
  final List<StreamSubscription<void>> _cacheSubscriptions =
      <StreamSubscription<void>>[];

  @override
  Future<ConverterState> build() async {
    _settingsRepository = ref.watch(settingsRepositoryProvider);
    _observeCaches(<Object>[
      _settingsRepository,
      ref.watch(rateRepositoryProvider),
    ]);
    _settings = await _settingsRepository.load();
    final catalog = CurrencyCatalog();
    final homeCurrency = _settings?.defaultCurrency ?? catalog.resolve('CNY');
    final transactionCurrency =
        _settings?.lastTransactionCurrency ??
        fallbackTransactionCurrency(
          homeCurrency: homeCurrency,
          catalog: catalog,
        );
    final initial = ConverterState(
      expression: '12800',
      transactionCurrency: transactionCurrency,
      homeCurrency: homeCurrency,
      evaluatedAmount: DecimalValue.parse('12800'),
      expressionError: null,
      rateResolution: null,
      isResolvingRate: true,
    );
    final cached = await _resolve(initial, allowRefresh: false);
    unawaited(
      Future<void>(() => _publishResolved(cached, notifyLocalChange: false)),
    );
    return cached.copyWith(isResolvingRate: true);
  }

  void _observeCaches(List<Object> sources) {
    for (final subscription in _cacheSubscriptions) {
      unawaited(subscription.cancel());
    }
    _cacheSubscriptions.clear();
    for (final source in sources.whereType<CacheRepositoryObserver>()) {
      _cacheSubscriptions.add(
        source.watchChanges().listen((_) {
          if (ref.mounted) unawaited(_revalidateFromCache());
        }),
      );
    }
    ref.onDispose(() {
      for (final subscription in _cacheSubscriptions) {
        unawaited(subscription.cancel());
      }
    });
  }

  Future<void> _revalidateFromCache() async {
    final current = _current;
    if (current == null) return;
    _settings = await _settingsRepository.load();
    if (!ref.mounted) return;
    final homeCurrency = _settings?.defaultCurrency ?? current.homeCurrency;
    final storedTransactionCurrency =
        _settings?.lastTransactionCurrency ?? current.transactionCurrency;
    final transactionCurrency = storedTransactionCurrency == homeCurrency
        ? fallbackTransactionCurrency(homeCurrency: homeCurrency)
        : storedTransactionCurrency;
    final cached = await _resolve(
      current.copyWith(
        homeCurrency: homeCurrency,
        transactionCurrency: transactionCurrency,
        rateResolution: null,
      ),
      allowRefresh: false,
    );
    if (ref.mounted) state = AsyncData(cached);
  }

  void updateExpression(String expression) {
    final current = _current;
    if (current == null) {
      return;
    }
    try {
      final value = _parser.evaluate(expression);
      state = AsyncData(
        current.copyWith(
          expression: expression,
          evaluatedAmount: value,
          expressionError: null,
        ),
      );
    } on ExpressionException catch (error) {
      state = AsyncData(
        current.copyWith(
          expression: expression,
          evaluatedAmount: null,
          expressionError: error.code,
        ),
      );
    }
  }

  Future<void> changeTransactionCurrency(Currency currency) async {
    final current = _current;
    if (current == null || currency == current.homeCurrency) {
      return;
    }
    final resolution = _publishResolved(
      current.copyWith(transactionCurrency: currency, rateResolution: null),
      notifyLocalChange: false,
    );
    await _persistSettings(lastTransactionCurrency: currency);
    await resolution;
    if (ref.mounted) {
      await ref.read(localDataChangeCoordinatorProvider).notify();
    }
  }

  Future<void> changeHomeCurrency(Currency currency) async {
    final current = _current;
    if (current == null || currency == current.transactionCurrency) {
      return;
    }
    final resolution = _publishResolved(
      current.copyWith(homeCurrency: currency, rateResolution: null),
      notifyLocalChange: false,
    );
    await _persistSettings(
      defaultCurrency: currency,
      lastTransactionCurrency: current.transactionCurrency,
    );
    await resolution;
    if (ref.mounted) {
      await ref.read(localDataChangeCoordinatorProvider).notify();
    }
  }

  Future<void> swapCurrencies() async {
    final current = _current;
    if (current == null) {
      return;
    }
    final resolution = _publishResolved(
      current.copyWith(
        transactionCurrency: current.homeCurrency,
        homeCurrency: current.transactionCurrency,
        rateResolution: null,
      ),
      notifyLocalChange: false,
    );
    await _persistSettings(
      defaultCurrency: current.transactionCurrency,
      lastTransactionCurrency: current.homeCurrency,
    );
    await resolution;
    if (ref.mounted) {
      await ref.read(localDataChangeCoordinatorProvider).notify();
    }
  }

  Future<void> refresh() async {
    final current = _current;
    if (current != null) {
      await _publishResolved(
        current.copyWith(rateResolution: null),
        forceRefresh: true,
      );
    }
  }

  Future<void> setManualRate(DecimalValue rate) async {
    final current = _current;
    if (current == null) {
      return;
    }
    final generation = ++_resolutionGeneration;
    state = AsyncData(current.copyWith(isResolvingRate: true));
    final resolved = await ref
        .read(rateRepositoryProvider)
        .resolveRate(
          baseCurrency: current.transactionCurrency,
          quoteCurrency: current.homeCurrency,
          manualRate: ManualRateOverride(
            rate: rate,
            observedAt: DateTime.now().toUtc(),
          ),
        );
    if (generation == _resolutionGeneration) {
      state = AsyncData(
        current.copyWith(rateResolution: resolved, isResolvingRate: false),
      );
      await ref.read(localDataChangeCoordinatorProvider).notify();
    }
  }

  Future<RateSnapshotModel?> loadMarketReference({
    bool forceRefresh = false,
  }) async {
    final current = _current;
    if (current == null ||
        current.transactionCurrency == current.homeCurrency) {
      return null;
    }
    final refresh = await ref
        .read(rateRefreshSchedulerProvider)
        .refreshIfNeeded(
          baseCurrency: current.transactionCurrency,
          quoteCurrencies: <Currency>[current.homeCurrency],
          refreshInterval:
              _settings?.refreshInterval ?? const Duration(hours: 6),
          wifiOnly: _settings?.wifiOnlyRefresh ?? false,
          force: forceRefresh,
        );
    if (refresh.snapshots.isNotEmpty) {
      return refresh.snapshots.single;
    }
    return ref
        .read(rateRepositoryProvider)
        .latestCachedMarketRate(
          baseCurrency: current.transactionCurrency,
          quoteCurrency: current.homeCurrency,
        );
  }

  Future<void> useMarketRate() async {
    final current = _current;
    if (current == null) {
      return;
    }
    final repository = ref.read(rateRepositoryProvider);
    await repository.clearManualRate(
      baseCurrency: current.transactionCurrency,
      quoteCurrency: current.homeCurrency,
    );
    await _publishResolved(
      current.copyWith(rateResolution: null),
      forceRefresh: true,
    );
  }

  ConverterState? get _current {
    final currentState = state;
    return currentState is AsyncData<ConverterState>
        ? currentState.value
        : null;
  }

  Future<ConverterState> _resolve(
    ConverterState value, {
    bool forceRefresh = false,
    bool allowRefresh = true,
  }) async {
    final repository = ref.read(rateRepositoryProvider);
    final localResolution = await repository.resolveRate(
      baseCurrency: value.transactionCurrency,
      quoteCurrency: value.homeCurrency,
      allowNetwork: false,
    );
    if (!ref.mounted) {
      return value.copyWith(
        rateResolution: localResolution,
        isResolvingRate: false,
      );
    }
    if (localResolution.availability == RateAvailability.manual ||
        localResolution.availability == RateAvailability.cardNetwork ||
        localResolution.availability == RateAvailability.identity) {
      return value.copyWith(
        rateResolution: localResolution,
        isResolvingRate: false,
      );
    }

    if (!allowRefresh) {
      return value.copyWith(
        rateResolution: localResolution,
        isResolvingRate: false,
      );
    }

    final refresh = await ref
        .read(rateRefreshSchedulerProvider)
        .refreshIfNeeded(
          baseCurrency: value.transactionCurrency,
          quoteCurrencies: <Currency>[value.homeCurrency],
          refreshInterval:
              _settings?.refreshInterval ?? const Duration(hours: 6),
          wifiOnly: _settings?.wifiOnlyRefresh ?? false,
          force: forceRefresh,
        );
    if (refresh.status == RateRefreshStatus.refreshed &&
        refresh.snapshots.isNotEmpty) {
      return value.copyWith(
        rateResolution: RateResolution(
          availability: RateAvailability.liveMarket,
          snapshot: refresh.snapshots.single,
        ),
        isResolvingRate: false,
      );
    }
    final fallback = localResolution.snapshot == null
        ? RateResolution(
            availability: RateAvailability.unavailable,
            snapshot: null,
            refreshError: refresh.error,
          )
        : localResolution;
    return value.copyWith(rateResolution: fallback, isResolvingRate: false);
  }

  Future<void> _publishResolved(
    ConverterState value, {
    bool forceRefresh = false,
    bool allowRefresh = true,
    bool notifyLocalChange = true,
  }) async {
    if (!ref.mounted) return;
    final generation = ++_resolutionGeneration;
    state = AsyncData(value.copyWith(isResolvingRate: true));
    try {
      final resolved = await _resolve(
        value,
        forceRefresh: forceRefresh,
        allowRefresh: allowRefresh,
      );
      if (ref.mounted && generation == _resolutionGeneration) {
        state = AsyncData(resolved);
        if (notifyLocalChange) {
          await ref.read(localDataChangeCoordinatorProvider).notify();
        }
      }
    } on Exception {
      if (ref.mounted && generation == _resolutionGeneration) {
        state = AsyncData(
          value.copyWith(
            rateResolution: const RateResolution(
              availability: RateAvailability.unavailable,
              snapshot: null,
            ),
            isResolvingRate: false,
          ),
        );
      }
    }
  }

  Future<void> _persistSettings({
    Currency? defaultCurrency,
    Currency? lastTransactionCurrency,
  }) async {
    final current = _current;
    if (current == null) {
      return;
    }
    final now = DateTime.now().toUtc();
    final previous = _settings;
    final next = UserSettingsModel(
      metadata: SyncRecordMetadata(
        recordId: DriftSettingsRepository.settingsRecordId,
        syncVersion: (previous?.metadata.syncVersion ?? 0) + 1,
        updatedAt: now,
      ),
      defaultCurrency:
          defaultCurrency ?? previous?.defaultCurrency ?? current.homeCurrency,
      lastTransactionCurrency:
          lastTransactionCurrency ??
          previous?.lastTransactionCurrency ??
          current.transactionCurrency,
      // The legacy field remains round-tripped for storage compatibility only.
      favoriteCurrencies: previous?.favoriteCurrencies ?? const <Currency>[],
      languageMode: previous?.languageMode ?? AppLanguageMode.system,
      refreshInterval: previous?.refreshInterval ?? const Duration(hours: 6),
      wifiOnlyRefresh: previous?.wifiOnlyRefresh ?? false,
      syncEnabled: previous?.syncEnabled ?? false,
    );
    await _settingsRepository.save(next);
    _settings = next;
  }
}
