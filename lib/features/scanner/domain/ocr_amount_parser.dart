import 'package:trip_cost/core/money/currency.dart';
import 'package:trip_cost/core/money/decimal_value.dart';
import 'package:trip_cost/core/platform/generated/platform_apis.g.dart';

final class ParsedOcrAmount {
  const ParsedOcrAmount({
    required this.amount,
    required this.currencyOptions,
    required this.rawAmount,
    required this.source,
    required this.sourceIndex,
  });

  final DecimalValue amount;
  final List<Currency> currencyOptions;
  final String rawAmount;
  final OcrCandidate source;
  final int sourceIndex;

  bool get isLowConfidence => source.confidence < 0.5;
  Currency? get inferredCurrency =>
      currencyOptions.length == 1 ? currencyOptions.single : null;
}

final class OcrAmountParser {
  OcrAmountParser({CurrencyCatalog? currencyCatalog})
    : _currencyCatalog = currencyCatalog ?? CurrencyCatalog();

  final CurrencyCatalog _currencyCatalog;

  static final RegExp _amountPattern = RegExp(
    r'''(?<![A-Za-z0-9])(?:\(|[-+−]\s*)?(?:\d{1,3}(?:[\s\u00A0'’.,]\d{3})+(?:[.,]\d{1,3})?|\d+(?:[.,]\d{1,3})?)(?:\))?(?![A-Za-z0-9])''',
  );
  static final List<RegExp> _excludedPatterns = <RegExp>[
    RegExp(r'\b(?:19|20)\d{2}[-/.]\d{1,2}[-/.]\d{1,2}\b'),
    RegExp(r'\b\d{1,2}[-/.]\d{1,2}[-/.](?:\d{2}|\d{4})\b'),
    RegExp(r'\b\d{1,2}:\d{2}(?::\d{2})?\b'),
    RegExp(r'(?<![\d.,])\+?\d[\d ()-]{6,}\d(?![\d.,])'),
    RegExp(
      r'(?:#|\bno\.?|\border\s*(?:no\.?)?|\bid)\s*[:#-]?\s*[a-z0-9-]{3,}',
      caseSensitive: false,
    ),
  ];
  static final RegExp _currencyPattern = RegExp(
    r'(?:US\$|CA\$|AU\$|CN[¥￥]|JP[¥￥]|USD|CAD|AUD|CNY|RMB|JPY|EUR|GBP|KRW|CHF|KWD|HKD|SGD|د\.ك|[$€£¥￥₩])',
    caseSensitive: false,
  );

  List<ParsedOcrAmount> parse(List<OcrCandidate> observations) {
    final results = <ParsedOcrAmount>[];
    for (
      var sourceIndex = 0;
      sourceIndex < observations.length;
      sourceIndex++
    ) {
      final source = observations[sourceIndex];
      final exclusions = <_TextSpan>[
        for (final pattern in _excludedPatterns)
          for (final match in pattern.allMatches(source.text))
            _TextSpan(match.start, match.end),
      ];
      final currencyMatches = _currencyPattern.allMatches(source.text).toList();
      for (final match in _amountPattern.allMatches(source.text)) {
        if (exclusions.any((span) => span.overlaps(match.start, match.end))) {
          continue;
        }
        final currencyOptions = _currenciesNear(
          text: source.text,
          amountMatch: match,
          currencyMatches: currencyMatches,
        );
        final raw = match.group(0)!;
        if (_looksLikeLongIdentifier(raw, currencyOptions)) {
          continue;
        }
        final canonical = _canonicalize(
          raw,
          forceNegative: _isNegativeByContext(source.text, match),
          threeDecimalCurrency:
              currencyOptions.length == 1 &&
              currencyOptions.single.minorUnits == 3,
        );
        if (canonical == null) {
          continue;
        }
        try {
          results.add(
            ParsedOcrAmount(
              amount: DecimalValue.parse(canonical),
              currencyOptions: currencyOptions,
              rawAmount: raw,
              source: source,
              sourceIndex: sourceIndex,
            ),
          );
        } on FormatException {
          // OCR fragments that cannot become an exact decimal remain editable
          // as source text, but are not promoted to amount candidates.
        }
      }
    }
    return results;
  }

  List<Currency> _currenciesNear({
    required String text,
    required RegExpMatch amountMatch,
    required List<RegExpMatch> currencyMatches,
  }) {
    RegExpMatch? nearest;
    var nearestDistance = 1 << 30;
    for (final match in currencyMatches) {
      final distance = match.end <= amountMatch.start
          ? amountMatch.start - match.end
          : match.start >= amountMatch.end
          ? match.start - amountMatch.end
          : 0;
      if (distance <= 8 && distance < nearestDistance) {
        nearest = match;
        nearestDistance = distance;
      }
    }
    if (nearest == null) {
      return const <Currency>[];
    }
    return _currenciesForToken(text.substring(nearest.start, nearest.end));
  }

  List<Currency> _currenciesForToken(String token) {
    final normalized = token.replaceAll('￥', '¥').toUpperCase();
    final codes = switch (normalized) {
      'US\$' || '\$' || 'USD' => const <String>['USD'],
      'CA\$' || 'CAD' => const <String>['CAD'],
      'AU\$' || 'AUD' => const <String>['AUD'],
      'CN¥' || 'CNY' || 'RMB' => const <String>['CNY'],
      'JP¥' || 'JPY' => const <String>['JPY'],
      '¥' => const <String>['CNY', 'JPY'],
      '€' || 'EUR' => const <String>['EUR'],
      '£' || 'GBP' => const <String>['GBP'],
      '₩' || 'KRW' => const <String>['KRW'],
      'CHF' => const <String>['CHF'],
      'د.ك' || 'KWD' => const <String>['KWD'],
      'HKD' => const <String>['HKD'],
      'SGD' => const <String>['SGD'],
      _ => const <String>[],
    };
    return <Currency>[for (final code in codes) _currencyCatalog.resolve(code)];
  }

  bool _looksLikeLongIdentifier(String raw, List<Currency> currencies) {
    if (currencies.isNotEmpty || raw.contains(RegExp(r'''[.,\s'’]'''))) {
      return false;
    }
    return raw.replaceAll(RegExp(r'\D'), '').length >= 7;
  }

  bool _isNegativeByContext(String text, RegExpMatch amountMatch) {
    final opening = text.lastIndexOf('(', amountMatch.start);
    final priorClosing = text.lastIndexOf(')', amountMatch.start);
    final wrapped =
        opening > priorClosing &&
        (amountMatch.group(0)!.endsWith(')') ||
            text.indexOf(')', amountMatch.end) >= 0);
    final prefix = text.substring(
      amountMatch.start > 8 ? amountMatch.start - 8 : 0,
      amountMatch.start,
    );
    return wrapped || RegExp(r'[-−]\s*[^0-9]{0,5}$').hasMatch(prefix);
  }

  String? _canonicalize(
    String raw, {
    required bool forceNegative,
    required bool threeDecimalCurrency,
  }) {
    var text = raw.trim().replaceAll('\u2212', '-');
    final negative =
        forceNegative ||
        text.startsWith('-') ||
        (text.startsWith('(') && text.endsWith(')'));
    text = text
        .replaceAll(RegExp(r'''[+\-()\s\u00A0'’]'''), '')
        .replaceAll(RegExp(r'[^\d.,]'), '');
    if (text.isEmpty || !text.contains(RegExp(r'\d'))) {
      return null;
    }

    final commaCount = ','.allMatches(text).length;
    final dotCount = '.'.allMatches(text).length;
    String digits;
    if (commaCount > 0 && dotCount > 0) {
      final decimalSeparator = text.lastIndexOf(',') > text.lastIndexOf('.')
          ? ','
          : '.';
      digits = _withLastSeparatorAsDecimal(text, decimalSeparator);
    } else if (commaCount > 0 || dotCount > 0) {
      final separator = commaCount > 0 ? ',' : '.';
      final parts = text.split(separator);
      final groupedThousands =
          parts.length > 2 && parts.skip(1).every((part) => part.length == 3);
      if (groupedThousands) {
        digits = parts.join();
      } else {
        final fractionLength = parts.last.length;
        final isDecimal =
            fractionLength == 1 ||
            fractionLength == 2 ||
            (fractionLength == 3 && threeDecimalCurrency);
        digits = isDecimal
            ? _withLastSeparatorAsDecimal(text, separator)
            : parts.join();
      }
    } else {
      digits = text;
    }

    if (!RegExp(r'^\d+(?:\.\d+)?$').hasMatch(digits)) {
      return null;
    }
    return negative ? '-$digits' : digits;
  }

  String _withLastSeparatorAsDecimal(String text, String separator) {
    final split = text.lastIndexOf(separator);
    final integer = text.substring(0, split).replaceAll(RegExp(r'[.,]'), '');
    final fraction = text.substring(split + 1).replaceAll(RegExp(r'[.,]'), '');
    return '$integer.$fraction';
  }
}

final class _TextSpan {
  const _TextSpan(this.start, this.end);

  final int start;
  final int end;

  bool overlaps(int otherStart, int otherEnd) =>
      start < otherEnd && otherStart < end;
}
