import 'dart:math' as math;

import 'package:sealed_countries/sealed_countries.dart' as iso;
import 'package:trip_cost/core/money/currency.dart' as money;

/// Offline ISO 3166 country/region directory with localized names and the
/// currencies that are normally used in each destination.
final class CountryDirectory {
  CountryDirectory({Iterable<iso.WorldCountry>? countries})
    : _usesSharedCache = countries == null,
      countries = List<iso.WorldCountry>.unmodifiable(
        countries ?? iso.WorldCountry.list,
      ) {
    for (final country in this.countries) {
      _byCode[country.codeShort] = country;
      for (final currency in country.currencies ?? const <iso.FiatCurrency>[]) {
        (_countryCodesByCurrency[currency.code] ??= <String>{}).add(
          country.codeShort,
        );
      }
    }
  }

  static final Map<String, Map<String, String>> _sharedLocalizedNames =
      <String, Map<String, String>>{};
  static final Map<String, List<iso.WorldCountry>> _sharedSortedCountries =
      <String, List<iso.WorldCountry>>{};

  final List<iso.WorldCountry> countries;
  final bool _usesSharedCache;
  final Map<String, iso.WorldCountry> _byCode = <String, iso.WorldCountry>{};
  final Map<String, Set<String>> _countryCodesByCurrency =
      <String, Set<String>>{};
  final Map<String, Map<String, String>> _localizedNames =
      <String, Map<String, String>>{};
  final Map<String, List<iso.WorldCountry>> _sortedCountries =
      <String, List<iso.WorldCountry>>{};

  /// Builds the two supported localized directories before a picker needs
  /// them. The default directory caches are shared by every instance.
  static void prewarm() {
    final directory = CountryDirectory();
    for (final language in const <String>['zh', 'en']) {
      directory._localizedNamesFor(language);
      directory._sortedCountriesFor(language);
    }
  }

  iso.WorldCountry? findByCode(String code) =>
      _byCode[code.trim().toUpperCase()];

  String localizedName(iso.WorldCountry country, String languageCode) {
    final names = _localizedNamesFor(_supportedLanguage(languageCode));
    return names[country.codeShort] ?? country.name.common;
  }

  String displayNameForCode(String code, String languageCode) {
    final normalized = code.trim().toUpperCase();
    final country = findByCode(normalized);
    return country == null ? normalized : localizedName(country, languageCode);
  }

  List<iso.WorldCountry> search(String query, String languageCode) {
    final language = _supportedLanguage(languageCode);
    final normalizedQuery = query.trim().toLowerCase();
    final sortedCountries = _sortedCountriesFor(language);
    if (normalizedQuery.isEmpty) return sortedCountries;
    final localizedNames = _localizedNamesFor(language);
    return List<iso.WorldCountry>.unmodifiable(
      sortedCountries.where((country) {
        final terms = <String>{
          country.codeShort,
          country.code,
          country.name.common,
          localizedNames[country.codeShort] ?? country.name.common,
          ...country.altSpellings,
        };
        return terms.any(
          (term) => term.toLowerCase().contains(normalizedQuery),
        );
      }),
    );
  }

  String _supportedLanguage(String languageCode) =>
      languageCode.toLowerCase() == 'zh' ? 'zh' : 'en';

  Map<String, String> _localizedNamesFor(String language) {
    final cache = _usesSharedCache ? _sharedLocalizedNames : _localizedNames;
    return cache.putIfAbsent(language, () {
      final locale = language == 'zh'
          ? const iso.BasicTypedLocale(iso.LangZho())
          : const iso.BasicTypedLocale(iso.LangEng());
      final localized = countries.commonNamesMap(
        options: iso.LocaleMappingOptions<iso.BasicTypedLocale>(
          mainLocale: locale,
          fallbackLocale: const iso.BasicTypedLocale(iso.LangEng()),
          localizeFullNames: false,
        ),
      );
      return Map<String, String>.unmodifiable(<String, String>{
        for (final country in countries)
          country.codeShort: localized[country] ?? country.name.common,
      });
    });
  }

  List<iso.WorldCountry> _sortedCountriesFor(String language) {
    final cache = _usesSharedCache ? _sharedSortedCountries : _sortedCountries;
    return cache.putIfAbsent(language, () {
      final localizedNames = _localizedNamesFor(language);
      final sorted = countries.toList()
        ..sort((left, right) {
          final byName = (localizedNames[left.codeShort] ?? left.name.common)
              .compareTo(localizedNames[right.codeShort] ?? right.name.common);
          return byName != 0
              ? byName
              : left.codeShort.compareTo(right.codeShort);
        });
      return List<iso.WorldCountry>.unmodifiable(sorted);
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
