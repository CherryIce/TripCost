import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/core/destinations/country_directory.dart';

void main() {
  final directory = CountryDirectory();

  test('searches localized, English, and ISO country names offline', () {
    expect(directory.countries.length, greaterThanOrEqualTo(249));
    expect(directory.displayNameForCode('jp', 'zh'), '日本');
    expect(
      directory.search('日本', 'zh').map((country) => country.codeShort),
      contains('JP'),
    );
    expect(
      directory.search('Japan', 'zh').map((country) => country.codeShort),
      contains('JP'),
    );
    expect(
      directory.search('JP', 'en').map((country) => country.codeShort),
      contains('JP'),
    );
  });

  test('recommends, deduplicates, and fully describes local currencies', () {
    expect(
      directory
          .recommendedCurrencies(const <String>['JP', 'KR'])
          .map((currency) => currency.code),
      <String>['JPY', 'KRW'],
    );

    final euro = directory.recommendedCurrencies(const <String>['FR', 'DE']);
    expect(euro.map((currency) => currency.code), <String>['EUR']);
    expect(euro.single.countryCodes, containsAll(<String>['FR', 'DE']));

    final dinar = directory.recommendedCurrencies(const <String>['KW']);
    expect(dinar.single.code, 'KWD');
    expect(dinar.single.minorUnits, 3);
  });

  test('returns no recommendation for unknown saved destination codes', () {
    expect(directory.recommendedCurrencies(const <String>['UNKNOWN']), isEmpty);
    expect(directory.displayNameForCode('unknown', 'en'), 'UNKNOWN');
  });
}
