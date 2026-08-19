import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/infrastructure/app_providers.dart';
import 'package:trip_cost/core/money/currency.dart';
import 'package:trip_cost/core/money/decimal_value.dart';
import 'package:trip_cost/core/rates/application/rate_refresh_scheduler.dart';
import 'package:trip_cost/core/rates/domain/exchange_rate_repository.dart';
import 'package:trip_cost/core/sync/application/local_data_change_coordinator.dart';
import 'package:trip_cost/features/converter/application/converter_controller.dart';

import '../../../helpers/m4_fakes.dart';

void main() {
  late ProviderContainer container;
  late MemorySettingsRepository settings;

  setUp(() {
    settings = MemorySettingsRepository();
    container = ProviderContainer(
      overrides: [
        rateRepositoryProvider.overrideWithValue(createFakeRateRepository()),
        settingsRepositoryProvider.overrideWithValue(settings),
        networkStatusProvider.overrideWithValue(
          const FakeNetworkStatusProvider(),
        ),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('evaluates expressions and converts with the resolved rate', () async {
    final initial = await container.read(converterControllerProvider.future);
    expect(initial.rateResolution!.availability, RateAvailability.unavailable);
    expect(initial.isResolvingRate, isTrue);
    final refreshed = await _waitForAvailability(
      container,
      RateAvailability.liveMarket,
    );
    expect(refreshed.convertedMoney!.amount.toFixed(2), '612.36');

    container
        .read(converterControllerProvider.notifier)
        .updateExpression('1200 * 3 + 500');
    final updated = container.read(converterControllerProvider).requireValue;
    expect(updated.evaluatedAmount, DecimalValue.parse('4100'));
    expect(updated.convertedMoney!.amount.toFixed(4), '196.1466');
  });

  test('keeps invalid input editable and recovers in place', () async {
    await container.read(converterControllerProvider.future);
    final notifier = container.read(converterControllerProvider.notifier);

    notifier.updateExpression('12 / 0');
    expect(
      container.read(converterControllerProvider).requireValue.expressionError,
      isNotNull,
    );
    notifier.updateExpression('12 / 3');
    expect(
      container.read(converterControllerProvider).requireValue.evaluatedAmount,
      DecimalValue.parse('4'),
    );
  });

  test(
    'swaps currencies, applies manual rate and persists home currency',
    () async {
      final initial = await container.read(converterControllerProvider.future);
      final notifier = container.read(converterControllerProvider.notifier);
      await notifier.swapCurrencies();
      var updated = container.read(converterControllerProvider).requireValue;
      expect(updated.transactionCurrency.code, initial.homeCurrency.code);
      expect(updated.homeCurrency.code, initial.transactionCurrency.code);

      await notifier.setManualRate(DecimalValue.parse('20'));
      updated = container.read(converterControllerProvider).requireValue;
      expect(updated.rateResolution!.availability, RateAvailability.manual);

      final marketReference = await notifier.loadMarketReference();
      expect(marketReference, isNotNull);
      expect(marketReference!.sourceType, RateSourceType.market);

      await notifier.useMarketRate();
      updated = container.read(converterControllerProvider).requireValue;
      expect(
        updated.rateResolution!.availability,
        isNot(RateAvailability.manual),
      );
      expect(
        updated.rateResolution!.snapshot!.sourceType,
        RateSourceType.market,
      );

      expect(settings.value, isNotNull);
      expect(
        settings.value!.defaultCurrency.code,
        initial.transactionCurrency.code,
      );
    },
  );

  test('honors wifi-only policy on a cellular connection', () async {
    container.dispose();
    final catalog = CurrencyCatalog();
    settings = MemorySettingsRepository(
      UserSettingsModel(
        metadata: SyncRecordMetadata(
          recordId: 'app',
          syncVersion: 1,
          updatedAt: DateTime.utc(2026, 8, 17, 8),
        ),
        defaultCurrency: catalog.resolve('CNY'),
        lastTransactionCurrency: catalog.resolve('JPY'),
        favoriteCurrencies: <Currency>[catalog.resolve('JPY')],
        languageMode: AppLanguageMode.system,
        refreshInterval: const Duration(hours: 6),
        wifiOnlyRefresh: true,
        syncEnabled: false,
      ),
    );
    container = ProviderContainer(
      overrides: [
        rateRepositoryProvider.overrideWithValue(createFakeRateRepository()),
        settingsRepositoryProvider.overrideWithValue(settings),
        networkStatusProvider.overrideWithValue(
          const FakeNetworkStatusProvider(NetworkConnectionType.cellular),
        ),
      ],
    );

    final state = await container.read(converterControllerProvider.future);
    expect(state.rateResolution!.availability, RateAvailability.unavailable);
  });

  test('late rate results cannot overwrite the latest selection', () async {
    container.dispose();
    container = ProviderContainer(
      overrides: [
        rateRepositoryProvider.overrideWithValue(
          createFakeRateRepository(
            delays: <String, Duration>{
              'USD:CNY': const Duration(milliseconds: 50),
              'EUR:CNY': const Duration(milliseconds: 5),
            },
          ),
        ),
        settingsRepositoryProvider.overrideWithValue(settings),
        networkStatusProvider.overrideWithValue(
          const FakeNetworkStatusProvider(),
        ),
      ],
    );
    await container.read(converterControllerProvider.future);
    final notifier = container.read(converterControllerProvider.notifier);
    final catalog = CurrencyCatalog();
    final first = notifier.changeTransactionCurrency(catalog.resolve('USD'));
    await Future<void>.delayed(const Duration(milliseconds: 1));
    final second = notifier.changeTransactionCurrency(catalog.resolve('EUR'));
    await Future.wait(<Future<void>>[first, second]);

    final state = container.read(converterControllerProvider).requireValue;
    expect(state.transactionCurrency.code, 'EUR');
    expect(state.rateResolution!.snapshot!.baseCurrency.code, 'EUR');
  });

  test('persists selection before a slow rate refresh completes', () async {
    container.dispose();
    container = ProviderContainer(
      overrides: [
        rateRepositoryProvider.overrideWithValue(
          createFakeRateRepository(
            delays: <String, Duration>{
              'USD:CNY': const Duration(milliseconds: 50),
            },
          ),
        ),
        settingsRepositoryProvider.overrideWithValue(settings),
        networkStatusProvider.overrideWithValue(
          const FakeNetworkStatusProvider(),
        ),
      ],
    );
    await container.read(converterControllerProvider.future);
    final change = container
        .read(converterControllerProvider.notifier)
        .changeTransactionCurrency(CurrencyCatalog().resolve('USD'));

    expect(settings.value!.lastTransactionCurrency.code, 'USD');
    expect(
      container
          .read(converterControllerProvider)
          .requireValue
          .transactionCurrency
          .code,
      'USD',
    );
    await change;
  });

  test(
    'refreshes the widget after each currency pair change resolves',
    () async {
      container.dispose();
      final changes = _RecordingLocalDataChangeNotifier();
      container = ProviderContainer(
        overrides: [
          rateRepositoryProvider.overrideWithValue(
            createFakeRateRepository(
              delays: <String, Duration>{
                'USD:CNY': const Duration(milliseconds: 20),
              },
            ),
          ),
          settingsRepositoryProvider.overrideWithValue(settings),
          networkStatusProvider.overrideWithValue(
            const FakeNetworkStatusProvider(),
          ),
          localDataChangeCoordinatorProvider.overrideWithValue(changes),
        ],
      );
      await container.read(converterControllerProvider.future);
      final notifier = container.read(converterControllerProvider.notifier);
      final catalog = CurrencyCatalog();

      final transactionChange = notifier.changeTransactionCurrency(
        catalog.resolve('USD'),
      );
      expect(changes.count, 0);
      await transactionChange;
      expect(changes.count, 1);

      await notifier.changeHomeCurrency(catalog.resolve('EUR'));
      expect(changes.count, 2);

      await notifier.swapCurrencies();
      expect(changes.count, 3);
    },
  );

  test(
    'restores the last transaction currency after controller rebuild',
    () async {
      await container.read(converterControllerProvider.future);
      await container
          .read(converterControllerProvider.notifier)
          .changeTransactionCurrency(CurrencyCatalog().resolve('USD'));

      expect(settings.value!.lastTransactionCurrency.code, 'USD');
      container.dispose();
      container = ProviderContainer(
        overrides: [
          rateRepositoryProvider.overrideWithValue(createFakeRateRepository()),
          settingsRepositoryProvider.overrideWithValue(settings),
          networkStatusProvider.overrideWithValue(
            const FakeNetworkStatusProvider(),
          ),
        ],
      );

      final restored = await container.read(converterControllerProvider.future);
      expect(restored.transactionCurrency.code, 'USD');
      expect(restored.homeCurrency.code, 'CNY');
    },
  );
}

final class _RecordingLocalDataChangeNotifier
    implements LocalDataChangeNotifier {
  int count = 0;

  @override
  Future<void> notify() async {
    count += 1;
  }
}

Future<ConverterState> _waitForAvailability(
  ProviderContainer container,
  RateAvailability availability,
) async {
  for (var attempt = 0; attempt < 20; attempt += 1) {
    await Future<void>.delayed(Duration.zero);
    final value = container.read(converterControllerProvider).value;
    if (value?.rateResolution?.availability == availability) return value!;
  }
  return container.read(converterControllerProvider).requireValue;
}
