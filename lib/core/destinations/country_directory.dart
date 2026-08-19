import 'dart:math' as math;

import 'package:sealed_countries/sealed_countries.dart' as iso;
import 'package:trip_cost/core/money/currency.dart' as money;

/// Offline ISO 3166 country/region directory with localized names and the
/// currencies that are normally used in each destination.
final class CountryDirectory {
  CountryDirectory({
    Iterable<iso.WorldCountry> countries = iso.WorldCountry.list,
  }) : countries = List<iso.WorldCountry>.unmodifiable(countries) {
    for (final country in this.countries) {
      _byCode[country.codeShort] = country;
      for (final currency in country.currencies ?? const <iso.FiatCurrency>[]) {
        (_countryCodesByCurrency[currency.code] ??= <String>{}).add(
          country.codeShort,
        );
      }
    }
  }

  final List<iso.WorldCountry> countries;
  final Map<String, iso.WorldCountry> _byCode = <String, iso.WorldCountry>{};
  final Map<String, Set<String>> _countryCodesByCurrency =
      <String, Set<String>>{};
  final Map<String, String> _localizedNames = <String, String>{};

  iso.WorldCountry? findByCode(String code) =>
      _byCode[code.trim().toUpperCase()];

  String localizedName(iso.WorldCountry country, String languageCode) {
    final language = languageCode.toLowerCase() == 'zh' ? 'zh' : 'en';
    final cacheKey = '$language:${country.codeShort}';
    final cached = _localizedNames[cacheKey];
    if (cached != null) return cached;
    final locale = language == 'zh'
        ? const iso.BasicTypedLocale(iso.LangZho())
        : const iso.BasicTypedLocale(iso.LangEng());
    final localized = country.commonNameFor(
      locale,
      fallbackLocale: const iso.BasicTypedLocale(iso.LangEng()),
      orElse: country.name.common,
    );
    _localizedNames[cacheKey] = localized;
    return localized;
  }

  String displayNameForCode(String code, String languageCode) {
    final normalized = code.trim().toUpperCase();
    final country = findByCode(normalized);
    return country == null ? normalized : localizedName(country, languageCode);
  }

  List<iso.WorldCountry> search(String query, String languageCode) {
    final normalizedQuery = query.trim().toLowerCase();
    final filtered = countries
        .where((country) {
          if (normalizedQuery.isEmpty) return true;
          final terms = <String>{
            country.codeShort,
            country.code,
            country.name.common,
            localizedName(country, languageCode),
            ...country.altSpellings,
          };
          return terms.any(
            (term) => term.toLowerCase().contains(normalizedQuery),
          );
        })
        .toList(growable: false);
    return filtered.toList()..sort((left, right) {
      final byName = localizedName(
        left,
        languageCode,
      ).compareTo(localizedName(right, languageCode));
      return byName != 0 ? byName : left.codeShort.compareTo(right.codeShort);
    });
  }

  List<money.Currency> recommendedCurrencies(
    Iterable<String> destinationCodes,
  ) {
    final currencies = <String, iso.FiatCurrency>{};
    for (final code in destinationCodes) {
      final country = findByCode(code);
      for (final currency
          in country?.currencies ?? const <iso.FiatCurrency>[]) {
        currencies[currency.code] = currency;
      }
    }
    final sortedCodes = currencies.keys.toList()..sort();
    return List<money.Currency>.unmodifiable(<money.Currency>[
      for (final code in sortedCodes) _toMoneyCurrency(currencies[code]!),
    ]);
  }

  money.Currency _toMoneyCurrency(iso.FiatCurrency currency) {
    final countryCodes =
        (_countryCodesByCurrency[currency.code] ?? const <String>{}).toList()
          ..sort();
    return money.Currency(
      code: currency.code,
      numericCode: currency.codeNumeric,
      name: currency.name,
      symbol: currency.symbol ?? currency.code,
      minorUnits: _minorUnits(currency.subunitToUnit),
      countryCodes: countryCodes,
    );
  }

  int _minorUnits(int subunitToUnit) {
    if (subunitToUnit <= 1) return 0;
    final exponent = math.log(subunitToUnit) / math.ln10;
    final rounded = exponent.round();
    if (math.pow(10, rounded).toInt() == subunitToUnit) return rounded;
    return 2;
  }
}
