import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trip_cost/core/infrastructure/app_providers.dart';
import 'package:trip_cost/core/money/currency.dart';

enum CurrencyDirectorySource { fallback, cache, network }

final class CurrencyDirectoryState {
  const CurrencyDirectoryState({
    required this.currencies,
    required this.source,
    required this.isRefreshing,
  });

  final List<Currency> currencies;
  final CurrencyDirectorySource source;
  final bool isRefreshing;

  CurrencyDirectoryState copyWith({
    List<Currency>? currencies,
    CurrencyDirectorySource? source,
    bool? isRefreshing,
  }) {
    return CurrencyDirectoryState(
      currencies: currencies ?? this.currencies,
      source: source ?? this.source,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

final currencyDirectoryProvider =
    NotifierProvider<CurrencyDirectoryController, CurrencyDirectoryState>(
      CurrencyDirectoryController.new,
    );

final class CurrencyDirectoryController
    extends Notifier<CurrencyDirectoryState> {
  var _generation = 0;

  @override
  CurrencyDirectoryState build() {
    final fallback = ref
        .watch(currencyDirectoryRepositoryProvider)
        .fallbackCurrencies;
    unawaited(Future<void>(_initialize));
    return CurrencyDirectoryState(
      currencies: fallback,
      source: CurrencyDirectorySource.fallback,
      isRefreshing: true,
    );
  }

  Future<void> refresh() => _refreshFromNetwork(++_generation);

  Future<void> _initialize() async {
    final generation = ++_generation;
    final repository = ref.read(currencyDirectoryRepositoryProvider);
    try {
      final cached = await repository.loadCached();
      if (generation != _generation || !ref.mounted) return;
      if (cached.isNotEmpty) {
        state = CurrencyDirectoryState(
          currencies: cached,
          source: CurrencyDirectorySource.cache,
          isRefreshing: true,
        );
      }
    } on Object {
      // The in-memory fallback remains usable even if local storage is not.
    }
    await _refreshFromNetwork(generation);
  }

  Future<void> _refreshFromNetwork(int generation) async {
    final repository = ref.read(currencyDirectoryRepositoryProvider);
    if (generation == _generation && ref.mounted) {
      state = state.copyWith(isRefreshing: true);
    }
    try {
      final refreshed = await repository.refresh();
      if (generation != _generation || !ref.mounted) return;
      state = CurrencyDirectoryState(
        currencies: refreshed,
        source: CurrencyDirectorySource.network,
        isRefreshing: false,
      );
    } on Object {
      if (generation == _generation && ref.mounted) {
        state = state.copyWith(isRefreshing: false);
      }
    }
  }
}
