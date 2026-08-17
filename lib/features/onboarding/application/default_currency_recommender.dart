import 'dart:ui';

import 'package:trip_cost/core/money/currency.dart';

final class DefaultCurrencyRecommender {
  const DefaultCurrencyRecommender();

  Currency recommend(Locale locale) {
    final catalog = CurrencyCatalog();
    final countryCode = locale.countryCode?.toUpperCase();
    if (countryCode != null) {
      for (final currency in CurrencyCatalog.knownCurrencies) {
        if (currency.countryCodes.contains(countryCode)) return currency;
      }
    }
    return catalog.resolve(locale.languageCode == 'zh' ? 'CNY' : 'USD');
  }
}
