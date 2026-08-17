import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/core/money/currency.dart';
import 'package:trip_cost/core/money/decimal_value.dart';
import 'package:trip_cost/core/money/money.dart';
import 'package:trip_cost/core/money/money_formatter.dart';

void main() {
  final catalog = CurrencyCatalog();

  test('Currency validates ISO code and minor units', () {
    expect(
      () => Currency(code: 'US', name: 'Bad', symbol: '?', minorUnits: 2),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => Currency(code: 'USD', name: 'Bad', symbol: r'$', minorUnits: 7),
      throwsRangeError,
    );
  });

  group('DecimalValue', () {
    test('keeps large and negative values exact', () {
      final value = DecimalValue.parse('999999999999999999999999.9999');

      expect(value.toString(), '999999999999999999999999.9999');
      expect((-value).toString(), '-999999999999999999999999.9999');
    });

    test('performs exact arithmetic without double', () {
      final left = DecimalValue.parse('0.1');
      final right = DecimalValue.parse('0.2');

      expect((left + right).toString(), '0.3');
      expect((DecimalValue.parse('12.50') * right).toString(), '2.5');
      expect(
        DecimalValue.parse(
          '1',
        ).divide(DecimalValue.parse('3'), precision: 6).toString(),
        '0.333333',
      );
    });

    test('supports boundary rounding modes', () {
      expect(DecimalValue.parse('1.2').toFixed(2), '1.20');
      expect(DecimalValue.parse('2.5').toFixed(0), '2');
      expect(DecimalValue.parse('3.5').toFixed(0), '4');
      expect(
        DecimalValue.parse('2.5').toFixed(0, rounding: DecimalRounding.halfUp),
        '3',
      );
      expect(
        DecimalValue.parse('-1.21').toFixed(1, rounding: DecimalRounding.floor),
        '-1.3',
      );
    });
  });

  group('Money', () {
    test('uses ISO minor units only at presentation boundary', () {
      final jpy = Money.parse('12800.5', catalog.resolve('JPY'));
      final krw = Money.parse('1234.6', catalog.resolve('KRW'));
      final cny = Money.parse('612.365', catalog.resolve('CNY'));

      expect(jpy.rounded().amount.toString(), '12800');
      expect(krw.rounded().amount.toString(), '1235');
      expect(cny.rounded().amount.toString(), '612.36');
    });

    test('rejects arithmetic across currencies', () {
      final cny = Money.parse('1', catalog.resolve('CNY'));
      final usd = Money.parse('1', catalog.resolve('USD'));

      expect(() => cny + usd, throwsA(isA<CurrencyMismatchException>()));
    });
  });

  group('format and parse boundaries', () {
    test('formats without converting the accounting value to double', () {
      const formatter = MoneyFormatter();
      final value = Money.parse(
        '12345678901234567890.125',
        catalog.resolve('USD'),
      );

      expect(
        formatter.format(value, locale: 'en_US', includeCode: true),
        r'$12,345,678,901,234,567,890.12 USD',
      );
      expect(
        formatter.format(value, locale: 'de_DE', includeSymbol: false),
        '12.345.678.901.234.567.890,12',
      );
    });

    test('localized parsing is separate from canonical storage parsing', () {
      const parser = LocalizedDecimalParser();

      expect(parser.parse('1.234,56', locale: 'de_DE').toString(), '1234.56');
      expect(parser.parse('1,234.56', locale: 'en_US').toString(), '1234.56');
    });
  });
}
