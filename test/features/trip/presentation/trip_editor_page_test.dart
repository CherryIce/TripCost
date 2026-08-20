import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/core/currencies/data/currency_directory_repository.dart';
import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/infrastructure/app_providers.dart';
import 'package:trip_cost/core/rates/data/frankfurter_api_client.dart';
import 'package:trip_cost/core/rates/data/frankfurter_dtos.dart';
import 'package:trip_cost/features/trip/presentation/trips_page.dart';
import 'package:trip_cost/l10n/app_localizations.dart';

import '../../../helpers/isolated_test_database.dart';
import '../../../helpers/m4_fakes.dart';
import '../../../helpers/m5_fixtures.dart';

void main() {
  testWidgets('shows the multi-country route planner structure', (
    tester,
  ) async {
    await _pumpEditor(tester);

    expect(find.text('规划多国路线'), findsOneWidget);
    expect(find.text('目的地与停留'), findsOneWidget);
    expect(find.text('至少添加一个目的地。'), findsOneWidget);
    expect(find.text('整段行程'), findsOneWidget);
    expect(find.text('整趟预算'), findsOneWidget);
    expect(find.text('更多设置'), findsOneWidget);
    expect(find.byKey(const Key('trip-editor-submit-button')), findsOneWidget);
  });

  testWidgets('adds destinations in route order with recommended currencies', (
    tester,
  ) async {
    await _pumpEditor(tester);

    await _addDestination(tester, query: '日本', code: 'JP');
    await _addDestination(tester, query: '韩国', code: 'KR');

    expect(find.byKey(const Key('trip-stop-list')), findsOneWidget);
    expect(find.text('日本'), findsOneWidget);
    expect(find.text('韩国'), findsOneWidget);
    expect(find.textContaining('JPY'), findsWidgets);
    expect(find.textContaining('KRW'), findsWidgets);
    final japanTop = tester.getTopLeft(find.text('日本')).dy;
    final koreaTop = tester.getTopLeft(find.text('韩国')).dy;
    expect(japanTop, lessThan(koreaTop));
  });

  testWidgets('a stop can override its recommended local currency', (
    tester,
  ) async {
    await _pumpEditor(tester);
    await _addDestination(tester, query: '韩国', code: 'KR');

    await tester.tap(find.text('韩国'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('修改当地货币'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('currency-search-field')),
      'USD',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('currency-option-USD')));
    await tester.pumpAndSettle();

    expect(find.text('韩国'), findsOneWidget);
    expect(find.textContaining('USD'), findsWidgets);
  });

  testWidgets('whole trip range uses one calendar range page', (tester) async {
    await _pumpEditor(tester, initial: fixtureTrip());

    await tester.tap(find.text('整段行程'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('trip-date-range-picker-page')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('trip-date-range-start-field')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('trip-date-range-end-field')), findsOneWidget);
    expect(find.byKey(const Key('trip-calendar-month-2026-8')), findsOneWidget);

    await tester.tap(find.byKey(const Key('trip-range-day-2026-08-18')));
    await tester.pump();
    expect(
      tester
          .widget<CupertinoButton>(
            find.byKey(const Key('trip-date-range-done')),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.byKey(const Key('trip-range-day-2026-08-23')));
    await tester.pump();
    expect(
      tester
          .widget<CupertinoButton>(
            find.byKey(const Key('trip-date-range-done')),
          )
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.byKey(const Key('trip-date-range-done')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('trip-date-range-picker-page')), findsNothing);
    expect(find.textContaining('8月18日'), findsWidgets);
    expect(find.textContaining('8月23日'), findsWidgets);
  });
}

Future<void> _pumpEditor(WidgetTester tester, {TripModel? initial}) async {
  final database = createIsolatedTestDatabase();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        paymentMethodRepositoryProvider.overrideWithValue(
          MemoryPaymentMethodRepository(),
        ),
        currencyDirectoryRepositoryProvider.overrideWithValue(
          CurrencyDirectoryRepository(
            database: database,
            gateway: const _CurrencyGateway(),
          ),
        ),
      ],
      child: CupertinoApp(
        locale: const Locale('zh'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: TripEditorPage(initial: initial),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapDone(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(CupertinoButton, '完成'));
  await tester.pumpAndSettle();
}

Future<void> _addDestination(
  WidgetTester tester, {
  required String query,
  required String code,
}) async {
  await tester.tap(find.text('添加下一站'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('country-search-field')), query);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(Key('country-option-$code')));
  await tester.pumpAndSettle();
  await _tapDone(tester);
  await tester.pumpAndSettle();
}

final class _CurrencyGateway implements FrankfurterRatesGateway {
  const _CurrencyGateway();

  @override
  Future<List<FrankfurterCurrencyDto>> getCurrencies() async =>
      <FrankfurterCurrencyDto>[
        _currency('JPY'),
        _currency('KRW'),
        _currency('USD'),
      ];

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

FrankfurterCurrencyDto _currency(String code) => FrankfurterCurrencyDto(
  code: code,
  name: code,
  numericCode: null,
  symbol: null,
  startDate: DateTime.utc(2000),
  endDate: DateTime.utc(2026, 8, 19),
);
