import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/core/currencies/data/currency_directory_repository.dart';
import 'package:trip_cost/core/infrastructure/app_providers.dart';
import 'package:trip_cost/core/rates/data/frankfurter_api_client.dart';
import 'package:trip_cost/core/rates/data/frankfurter_dtos.dart';
import 'package:trip_cost/features/trip/presentation/trips_page.dart';
import 'package:trip_cost/l10n/app_localizations.dart';

import '../../../helpers/isolated_test_database.dart';
import '../../../helpers/m4_fakes.dart';

void main() {
  testWidgets('choice values wrap and stay aligned to the trailing edge', (
    tester,
  ) async {
    await _pumpEditor(tester);

    final destinationLabel = find.text('国家或地区');
    final destinationButton = find.ancestor(
      of: destinationLabel,
      matching: find.byType(CupertinoButton),
    );
    final destinationChevron = find.descendant(
      of: destinationButton,
      matching: find.byIcon(CupertinoIcons.chevron_forward),
    );
    final destinationValue = find.descendant(
      of: destinationButton,
      matching: find.text('请选择'),
    );

    final buttonRect = tester.getRect(destinationButton);
    final chevronRect = tester.getRect(destinationChevron);
    final valueRect = tester.getRect(destinationValue);
    final valueParagraph = tester.renderObject<RenderParagraph>(
      destinationValue,
    );

    expect(chevronRect.right, closeTo(buttonRect.right, 0.01));
    expect(valueRect.right, closeTo(chevronRect.left, 0.01));
    expect(valueParagraph.textAlign, TextAlign.end);
    expect(valueParagraph.softWrap, isTrue);
    expect(valueParagraph.maxLines, 2);
  });

  testWidgets(
    'new trip starts empty and recomputes currencies from destinations',
    (tester) async {
      await _pumpEditor(tester);

      expect(find.text('选择目的地后推荐'), findsOneWidget);
      expect(find.textContaining('JPY'), findsNothing);

      await tester.tap(find.text('国家或地区'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('country-search-field')),
        '日本',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('country-option-JP')));
      await tester.pumpAndSettle();
      await _tapDone(tester);
      await tester.pumpAndSettle();

      expect(find.text('日本'), findsOneWidget);
      expect(find.text('JPY · 已推荐'), findsOneWidget);

      await tester.tap(find.text('国家或地区'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('country-search-field')),
        '韩国',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('country-option-KR')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('country-search-field')),
        '日本',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('country-option-JP')));
      await tester.pumpAndSettle();
      await _tapDone(tester);
      await tester.pumpAndSettle();

      expect(find.text('韩国'), findsOneWidget);
      expect(find.text('KRW · 已推荐'), findsOneWidget);
      expect(find.textContaining('JPY'), findsNothing);
    },
  );

  testWidgets('manual currency survives a destination change when kept', (
    tester,
  ) async {
    await _pumpEditor(tester);

    await tester.tap(find.text('国家或地区'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('country-search-field')), '韩国');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('country-option-KR')));
    await tester.pumpAndSettle();
    await _tapDone(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('当地货币'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('currency-search-field')),
      'USD',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('currency-option-USD')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('currency-search-field')),
      'KRW',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('currency-option-KRW')));
    await tester.pumpAndSettle();
    await _tapDone(tester);
    await tester.pumpAndSettle();
    expect(find.text('USD'), findsOneWidget);

    await tester.tap(find.text('国家或地区'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('country-search-field')), '日本');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('country-option-JP')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('country-search-field')), '韩国');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('country-option-KR')));
    await tester.pumpAndSettle();
    await _tapDone(tester);
    await tester.pumpAndSettle();

    expect(find.text('更新当地货币？'), findsOneWidget);
    expect(find.textContaining('JPY'), findsOneWidget);
    await tester.tap(find.text('保留当前'));
    await tester.pumpAndSettle();

    expect(find.text('日本'), findsOneWidget);
    expect(find.text('USD'), findsOneWidget);
    expect(find.textContaining('JPY'), findsNothing);
  });
}

Future<void> _pumpEditor(WidgetTester tester) async {
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
      child: const CupertinoApp(
        locale: Locale('zh'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: TripEditorPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapDone(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(CupertinoButton, '完成'));
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
