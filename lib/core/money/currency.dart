final class Currency {
  factory Currency({
    required String code,
    required String name,
    required String symbol,
    required int minorUnits,
    String? numericCode,
    List<String> countryCodes = const <String>[],
  }) {
    final normalizedCode = code.trim().toUpperCase();
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(normalizedCode)) {
      throw FormatException('Invalid ISO 4217 code: $code');
    }
    if (minorUnits < 0 || minorUnits > 6) {
      throw RangeError.range(minorUnits, 0, 6, 'minorUnits');
    }
    return Currency._(
      code: normalizedCode,
      numericCode: numericCode,
      name: name,
      symbol: symbol,
      minorUnits: minorUnits,
      countryCodes: List<String>.unmodifiable(countryCodes),
    );
  }

  const Currency._({
    required this.code,
    required this.name,
    required this.symbol,
    required this.minorUnits,
    required this.numericCode,
    required this.countryCodes,
  });

  final String code;
  final String? numericCode;
  final String name;
  final String symbol;
  final int minorUnits;
  final List<String> countryCodes;

  Currency copyWith({
    String? name,
    String? symbol,
    int? minorUnits,
    String? numericCode,
    List<String>? countryCodes,
  }) {
    return Currency(
      code: code,
      numericCode: numericCode ?? this.numericCode,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      minorUnits: minorUnits ?? this.minorUnits,
      countryCodes: countryCodes ?? this.countryCodes,
    );
  }

  @override
  bool operator ==(Object other) => other is Currency && code == other.code;

  @override
  int get hashCode => code.hashCode;
}

final class CurrencyCatalog {
  CurrencyCatalog({Iterable<Currency> overrides = const <Currency>[]})
    : _currencies = <String, Currency>{
        for (final currency in knownCurrencies) currency.code: currency,
        for (final currency in overrides) currency.code: currency,
      };

  final Map<String, Currency> _currencies;

  Currency resolve(String code, {String? remoteName}) {
    final normalizedCode = code.trim().toUpperCase();
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(normalizedCode)) {
      throw FormatException('Invalid ISO 4217 code: $code');
    }
    final known = _currencies[normalizedCode];
    if (known != null) {
      return remoteName == null ? known : known.copyWith(name: remoteName);
    }
    return Currency(
      code: normalizedCode,
      name: remoteName ?? normalizedCode,
      symbol: normalizedCode,
      minorUnits: 2,
    );
  }

  static final List<Currency> knownCurrencies = List<Currency>.unmodifiable(
    <Currency>[
      Currency(
        code: 'CNY',
        numericCode: '156',
        name: 'Chinese Yuan',
        symbol: '¥',
        minorUnits: 2,
        countryCodes: <String>['CN'],
      ),
      Currency(
        code: 'USD',
        numericCode: '840',
        name: 'US Dollar',
        symbol: r'$',
        minorUnits: 2,
        countryCodes: <String>['US'],
      ),
      Currency(
        code: 'EUR',
        numericCode: '978',
        name: 'Euro',
        symbol: '€',
        minorUnits: 2,
        countryCodes: <String>[],
      ),
      Currency(
        code: 'JPY',
        numericCode: '392',
        name: 'Japanese Yen',
        symbol: '¥',
        minorUnits: 0,
        countryCodes: <String>['JP'],
      ),
      Currency(
        code: 'KRW',
        numericCode: '410',
        name: 'South Korean Won',
        symbol: '₩',
        minorUnits: 0,
        countryCodes: <String>['KR'],
      ),
      Currency(
        code: 'GBP',
        numericCode: '826',
        name: 'Pound Sterling',
        symbol: '£',
        minorUnits: 2,
        countryCodes: <String>['GB'],
      ),
      Currency(
        code: 'CHF',
        numericCode: '756',
        name: 'Swiss Franc',
        symbol: 'CHF',
        minorUnits: 2,
        countryCodes: <String>['CH', 'LI'],
      ),
      Currency(
        code: 'KWD',
        numericCode: '414',
        name: 'Kuwaiti Dinar',
        symbol: 'د.ك',
        minorUnits: 3,
        countryCodes: <String>['KW'],
      ),
    ],
  );
}

Currency fallbackTransactionCurrency({CurrencyCatalog? catalog}) {
  return (catalog ?? CurrencyCatalog()).resolve('USD');
}
