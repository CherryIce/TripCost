import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/core/currencies/data/currency_directory_repository.dart';
import 'package:trip_cost/core/infrastructure/app_providers.dart';
import 'package:trip_cost/core/money/currency.dart';
import 'package:trip_cost/core/rates/data/frankfurter_api_client.dart';
import 'package:trip_cost/core/rates/data/frankfurter_dtos.dart';
import 'package:trip_cost/core/storage/database/app_database.dart' as db;
import 'package:trip_cost/shared/widgets/currency_picker_page.dart';

void main() {
  late db.AppDatabase database;

  setUp(() => database = db.AppDatabase.inMemory());
  tearDown(() => database.close());

  testWidgets('shows the network currency directory and returns a selection', (
    tester,
  ) async {
    CurrencyPickerResult? selection;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currencyDirectoryRepositoryProvider.overrideWithValue(
            CurrencyDirectoryRepository(
              database: database,
              gateway: const _AudDirectoryGateway(),
            ),
          ),
        ],
        child: CupertinoApp(
          home: Builder(
            builder: (context) => CupertinoPageScaffold(
              child: Center(
                child: CupertinoButton(
                  onPressed: () async {
                    selection = await showCurrencyPickerPage(
                      context: context,
                      title: 'Currency',
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('currency-option-AUD')), findsOneWidget);
    expect(find.byKey(const Key('currency-option-CNY')), findsNothing);

    await tester.tap(find.byKey(const Key('currency-option-AUD')));
    await tester.pumpAndSettle();
    expect(selection?.currency?.code, 'AUD');
  });

  testWidgets('multi picker keeps current values and returns API selections', (
    tester,
  ) async {
    List<Currency>? selection;
    final cny = CurrencyCatalog().resolve('CNY');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currencyDirectoryRepositoryProvider.overrideWithValue(
            CurrencyDirectoryRepository(
              database: database,
              gateway: const _AudDirectoryGateway(),
            ),
          ),
        ],
        child: CupertinoApp(
          home: Builder(
            builder: (context) => CupertinoPageScaffold(
              child: Center(
                child: CupertinoButton(
                  onPressed: () async {
                    selection = await showCurrencyMultiPickerPage(
                      context: context,
                      title: 'Currencies',
                      doneLabel: 'Done',
                      selected: <Currency>[cny],
                      minimumSelection: 1,
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('currency-option-CNY')), findsOneWidget);
    expect(find.byKey(const Key('currency-option-AUD')), findsOneWidget);

    await tester.tap(find.byKey(const Key('currency-option-AUD')));
    await tester.tap(find.byKey(const Key('currency-option-CNY')));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(
      selection?.map((currency) => currency.code).toList(growable: false),
      <String>['AUD'],
    );
  });

  testWidgets('opens above the nested tab navigator', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currencyDirectoryRepositoryProvider.overrideWithValue(
            CurrencyDirectoryRepository(
              database: database,
              gateway: const _AudDirectoryGateway(),
            ),
          ),
        ],
        child: CupertinoApp(
          home: Column(
            children: <Widget>[
              Expanded(
                child: Navigator(
                  onGenerateRoute: (settings) => CupertinoPageRoute<void>(
                    builder: (nestedContext) => CupertinoPageScaffold(
                      child: Center(
                        child: CupertinoButton(
                          onPressed: () => showCurrencyPickerPage(
                            context: nestedContext,
                            title: 'Currency',
                          ),
                          child: const Text('Open'),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                key: Key('fake-tab-bar'),
                height: 60,
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('fake-tab-bar')), findsOneWidget);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Currency'), findsOneWidget);
    expect(find.byKey(const Key('fake-tab-bar')), findsNothing);

    await tester.tap(find.byKey(const Key('currency-option-AUD')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('fake-tab-bar')), findsOneWidget);
  });
}

final class _AudDirectoryGateway implements FrankfurterRatesGateway {
  const _AudDirectoryGateway();

  @override
  Future<List<FrankfurterCurrencyDto>> getCurrencies() async {
    return <FrankfurterCurrencyDto>[
      FrankfurterCurrencyDto(
        code: 'AUD',
        name: 'Australian Dollar',
        numericCode: '036',
        symbol: r'$',
        startDate: null,
        endDate: null,
      ),
    ];
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
