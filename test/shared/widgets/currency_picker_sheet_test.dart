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

  testWidgets('puts names left, favorites right, and safe area in the list', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    tester.view.padding = const FakeViewPadding(bottom: 102);

    await tester.pumpWidget(
      _app(
        currencies: <Currency>[usd, eur, jpy, cny],
        selected: usd,
        favorites: <Currency>[eur],
      ),
    );

    final nameRect = tester.getRect(find.byKey(const Key('currency-name-EUR')));
    final favoriteRect = tester.getRect(
      find.byKey(const Key('currency-favorite-EUR')),
    );
    final optionRect = tester.getRect(
      find.byKey(const Key('currency-option-EUR')),
    );
    expect(nameRect.left, lessThan(favoriteRect.left));
    expect(favoriteRect.right, closeTo(optionRect.right - 16, 0.1));

    final list = tester.widget<ListView>(find.byType(ListView));
    expect(list.padding, const EdgeInsets.only(bottom: 50));
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
