import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/core/money/currency.dart';
import 'package:trip_cost/shared/widgets/currency_picker_sheet.dart';

void main() {
  final catalog = CurrencyCatalog();
  final usd = catalog.resolve('USD');
  final eur = catalog.resolve('EUR');
  final jpy = catalog.resolve('JPY');
  final cny = catalog.resolve('CNY');

  testWidgets('puts favorites first in preference order', (tester) async {
    await tester.pumpWidget(
      _app(
        currencies: <Currency>[usd, eur, jpy, cny],
        selected: usd,
        favorites: <Currency>[jpy, usd],
      ),
    );

    final jpyTop = tester.getTopLeft(
      find.byKey(const Key('currency-option-JPY')),
    );
    final usdTop = tester.getTopLeft(
      find.byKey(const Key('currency-option-USD')),
    );
    final eurTop = tester.getTopLeft(
      find.byKey(const Key('currency-option-EUR')),
    );

    expect(jpyTop.dy, lessThan(usdTop.dy));
    expect(usdTop.dy, lessThan(eurTop.dy));
  });

  testWidgets('searches code, English name and localized name', (tester) async {
    await tester.pumpWidget(
      _app(
        currencies: <Currency>[usd, eur, jpy, cny],
        selected: usd,
        favorites: const <Currency>[],
      ),
    );

    await tester.enterText(
      find.byKey(const Key('currency-search-field')),
      '人民币',
    );
    await tester.pump();

    expect(find.byKey(const Key('currency-option-CNY')), findsOneWidget);
    expect(find.byKey(const Key('currency-option-USD')), findsNothing);

    await tester.enterText(
      find.byKey(const Key('currency-search-field')),
      'JPY',
    );
    await tester.pump();
    expect(find.byKey(const Key('currency-option-JPY')), findsOneWidget);
    expect(find.byKey(const Key('currency-option-CNY')), findsNothing);
  });
}

Widget _app({
  required List<Currency> currencies,
  required Currency selected,
  required List<Currency> favorites,
}) {
  return CupertinoApp(
    home: CupertinoPageScaffold(
      child: CurrencyPickerSheet(
        currencies: currencies,
        selected: selected,
        favoriteCurrencies: favorites,
        title: 'Currency',
        cancelLabel: 'Cancel',
        displayName: (currency) =>
            currency.code == 'CNY' ? '人民币' : currency.name,
      ),
    ),
  );
}
