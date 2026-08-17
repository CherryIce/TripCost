import 'package:intl/intl.dart';
import 'package:trip_cost/core/money/decimal_value.dart';
import 'package:trip_cost/core/money/money.dart';

final class MoneyFormatter {
  const MoneyFormatter();

  String format(
    Money money, {
    required String locale,
    bool includeSymbol = true,
    bool includeCode = false,
    DecimalRounding rounding = DecimalRounding.halfEven,
  }) {
    final symbols = NumberFormat.decimalPattern(locale).symbols;
    final fixed = money.amount.toFixed(
      money.currency.minorUnits,
      rounding: rounding,
    );
    final negative = fixed.startsWith('-');
    final unsigned = negative ? fixed.substring(1) : fixed;
    final parts = unsigned.split('.');
    final grouped = _group(parts[0], symbols.GROUP_SEP);
    final localizedNumber = parts.length == 1
        ? grouped
        : '$grouped${symbols.DECIMAL_SEP}${parts[1]}';
    final localizedDigits = _localizeDigits(
      localizedNumber,
      symbols.ZERO_DIGIT,
    );
    final sign = negative ? symbols.MINUS_SIGN : '';
    final prefix = includeSymbol ? money.currency.symbol : '';
    final suffix = includeCode ? ' ${money.currency.code}' : '';
    final separator = prefix.isEmpty || prefix.endsWith(r'$') ? '' : ' ';
    return '$sign$prefix$separator$localizedDigits$suffix';
  }

  String _group(String digits, String separator) {
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index += 1) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        buffer.write(separator);
      }
      buffer.write(digits[index]);
    }
    return buffer.toString();
  }

  String _localizeDigits(String value, String zeroDigit) {
    if (zeroDigit == '0') {
      return value;
    }
    final offset = zeroDigit.codeUnitAt(0) - '0'.codeUnitAt(0);
    return value.replaceAllMapped(RegExp(r'\d'), (match) {
      return String.fromCharCode(match.group(0)!.codeUnitAt(0) + offset);
    });
  }
}

final class LocalizedDecimalParser {
  const LocalizedDecimalParser();

  DecimalValue parse(String source, {required String locale}) {
    final symbols = NumberFormat.decimalPattern(locale).symbols;
    var canonical = source.trim();
    canonical = _normalizeDigits(canonical, symbols.ZERO_DIGIT);
    canonical = canonical.replaceAll(symbols.GROUP_SEP, '');
    canonical = canonical.replaceAll(symbols.DECIMAL_SEP, '.');
    if (symbols.MINUS_SIGN != '-') {
      canonical = canonical.replaceFirst(symbols.MINUS_SIGN, '-');
    }
    return DecimalValue.parse(canonical);
  }

  String _normalizeDigits(String value, String zeroDigit) {
    if (zeroDigit == '0') {
      return value;
    }
    final offset = zeroDigit.codeUnitAt(0) - '0'.codeUnitAt(0);
    return value.split('').map((character) {
      final code = character.codeUnitAt(0) - offset;
      return code >= '0'.codeUnitAt(0) && code <= '9'.codeUnitAt(0)
          ? String.fromCharCode(code)
          : character;
    }).join();
  }
}
