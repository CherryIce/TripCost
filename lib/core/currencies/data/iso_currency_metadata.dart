import 'dart:math' as math;

import 'package:sealed_currencies/sealed_currencies.dart' as iso;
import 'package:trip_cost/core/money/currency.dart';
import 'package:trip_cost/core/rates/data/frankfurter_dtos.dart';

/// Enriches Frankfurter's supported-currency directory with ISO 4217 metadata.
///
/// Frankfurter remains the source of truth for availability. The ISO directory
/// only supplies metadata and removes non-travel entries such as metals,
/// accounting units, non-ISO offshore codes, and withdrawn cash currencies.
final class IsoCurrencyMetadata {
  IsoCurrencyMetadata()
    : _regularByCode = <String, iso.FiatCurrency>{
        for (final currency in iso.FiatCurrency.list) currency.code: currency,
      },
      _fallbackByCode = <String, Currency>{
        for (final currency in CurrencyCatalog.knownCurrencies)
          currency.code: currency,
      };

  static const Set<String> _nonTravelCodes = <String>{
    'ANG', // Replaced by XCG in 2025.
    'CLF', // Chilean inflation-indexed unit of account.
    'SVC', // No longer circulates in El Salvador.
  };

  final Map<String, iso.FiatCurrency> _regularByCode;
  final Map<String, Currency> _fallbackByCode;
  final Map<String, String> _localizedNames = <String, String>{};

  Currency? enrich(FrankfurterCurrencyDto remote) {
    final metadata = _regularByCode[remote.code];
    if (metadata == null || _nonTravelCodes.contains(remote.code)) {
      return null;
    }
    final fallback = _fallbackByCode[remote.code];
    return Currency(
      code: remote.code,
      numericCode: remote.numericCode ?? metadata.codeNumeric,
      name: metadata.name,
      symbol: _preferredSymbol(remote.symbol, metadata.symbol, remote.code),
      minorUnits: _minorUnits(metadata.subunitToUnit),
      countryCodes: fallback?.countryCodes ?? const <String>[],
    );
  }

  String localizedName(Currency currency, String languageCode) {
    final normalizedLanguage = languageCode.toLowerCase();
    final cacheKey = '$normalizedLanguage:${currency.code}';
    final cached = _localizedNames[cacheKey];
    if (cached != null) return cached;
    final metadata = _regularByCode[currency.code];
    if (metadata == null) return currency.name;
    final locale = normalizedLanguage == 'zh'
        ? const iso.BasicLocale(iso.LangZho())
        : const iso.BasicLocale(iso.LangEng());
    final fallback = const iso.BasicLocale(iso.LangEng());
    final localized = metadata.commonNameFor(
      locale,
      fallbackLocale: fallback,
      orElse: currency.name,
    );
    _localizedNames[cacheKey] = localized;
    return localized;
  }

  String _preferredSymbol(String? remote, String? local, String code) {
    final remoteValue = remote?.trim();
    if (remoteValue != null && remoteValue.isNotEmpty) return remoteValue;
    final localValue = local?.trim();
    if (localValue != null && localValue.isNotEmpty) return localValue;
    return code;
  }

  int _minorUnits(int subunitToUnit) {
    if (subunitToUnit <= 1) return 0;
    final exponent = math.log(subunitToUnit) / math.ln10;
    final rounded = exponent.round();
    if (math.pow(10, rounded).toInt() == subunitToUnit) return rounded;
    // ISO minor units are decimal digits. Non-decimal cash subunits such as
    // 1/5 still need two accounting digits rather than a fractional exponent.
    return 2;
  }
}
