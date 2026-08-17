import 'package:trip_cost/core/money/currency.dart';
import 'package:trip_cost/core/money/decimal_value.dart';

final class FrankfurterCurrencyDto {
  FrankfurterCurrencyDto({
    required this.code,
    required this.name,
    required this.numericCode,
    required this.symbol,
    required this.startDate,
    required this.endDate,
  });

  factory FrankfurterCurrencyDto.fromJson(Map<String, Object?> json) {
    final code = _requiredString(json, 'iso_code').toUpperCase();
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(code)) {
      throw const FormatException('Invalid currency code.');
    }
    return FrankfurterCurrencyDto(
      code: code,
      name: _requiredString(json, 'name'),
      numericCode: _optionalString(json, 'iso_numeric'),
      symbol: _optionalString(json, 'symbol'),
      startDate: _optionalDate(json, 'start_date'),
      endDate: _optionalDate(json, 'end_date'),
    );
  }

  final String code;
  final String name;
  final String? numericCode;
  final String? symbol;
  final DateTime? startDate;
  final DateTime? endDate;

  Currency toDomain({CurrencyCatalog? catalog}) {
    final resolved = (catalog ?? CurrencyCatalog()).resolve(
      code,
      remoteName: name,
    );
    return resolved.copyWith(
      name: name,
      symbol: symbol ?? resolved.symbol,
      numericCode: numericCode,
    );
  }
}

final class FrankfurterRateDto {
  FrankfurterRateDto({
    required this.date,
    required this.baseCurrencyCode,
    required this.quoteCurrencyCode,
    required this.rate,
  });

  factory FrankfurterRateDto.fromJson(Map<String, Object?> json) {
    final base = _requiredString(json, 'base').toUpperCase();
    final quote = _requiredString(json, 'quote').toUpperCase();
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(base) ||
        !RegExp(r'^[A-Z]{3}$').hasMatch(quote)) {
      throw const FormatException('Invalid rate currency code.');
    }
    final rawRate = json['rate'];
    if (rawRate is! num && rawRate is! String) {
      throw const FormatException('Rate must be numeric.');
    }
    final rate = DecimalValue.parse(rawRate.toString());
    if (rate.compareTo(DecimalValue.zero) <= 0) {
      throw const FormatException('Rate must be positive.');
    }
    return FrankfurterRateDto(
      date: _requiredDate(json, 'date'),
      baseCurrencyCode: base,
      quoteCurrencyCode: quote,
      rate: rate,
    );
  }

  final DateTime date;
  final String baseCurrencyCode;
  final String quoteCurrencyCode;
  final DecimalValue rate;
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$key must be a non-empty string.');
  }
  return value.trim();
}

String? _optionalString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is! String) {
    throw FormatException('$key must be a string or null.');
  }
  return value;
}

DateTime _requiredDate(Map<String, Object?> json, String key) {
  final value = _requiredString(json, key);
  final parsed = DateTime.tryParse(value);
  if (parsed == null || value.length != 10) {
    throw FormatException('$key must use YYYY-MM-DD.');
  }
  return DateTime.utc(parsed.year, parsed.month, parsed.day);
}

DateTime? _optionalDate(Map<String, Object?> json, String key) {
  if (json[key] == null) {
    return null;
  }
  return _requiredDate(json, key);
}
