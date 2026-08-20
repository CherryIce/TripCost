import 'package:trip_cost/core/money/decimal_value.dart';
import 'package:trip_cost/core/platform/generated/platform_apis.g.dart';
import 'package:trip_cost/features/scanner/domain/ocr_amount_parser.dart';

final class ParsedReceiptDraft {
  const ParsedReceiptDraft({
    this.merchantName,
    this.totalAmount,
    this.occurredAt,
    this.merchantNeedsConfirmation = false,
    this.amountNeedsConfirmation = false,
    this.dateNeedsConfirmation = false,
  });

  final String? merchantName;
  final ParsedOcrAmount? totalAmount;
  final DateTime? occurredAt;
  final bool merchantNeedsConfirmation;
  final bool amountNeedsConfirmation;
  final bool dateNeedsConfirmation;
}

final class OcrReceiptParser {
  const OcrReceiptParser();

  static final RegExp _strongTotal = RegExp(
    r'grand\s*total|amount\s*due|total\s*due|应付|实付|应收|总计',
    caseSensitive: false,
  );
  static final RegExp _total = RegExp(
    r'(^|\s)(total|amount)(\s|:|$)|合计|金额',
    caseSensitive: false,
  );
  static final RegExp _subtotal = RegExp(
    r'sub\s*total|小计|tax|税额?|tip|小费|discount|优惠|change|找零',
    caseSensitive: false,
  );
  static final RegExp _merchantExcluded = RegExp(
    r'receipt|invoice|order|welcome|thank|address|phone|tel\.?|date|time|'
    r'total|amount|tax|subtotal|cash|change|票据|发票|订单|欢迎|谢谢|地址|'
    r'电话|日期|时间|合计|总计|金额|税|现金|找零',
    caseSensitive: false,
  );
  static final RegExp _yearFirstDate = RegExp(
    r'\b((?:19|20)\d{2})[-/.年](\d{1,2})[-/.月](\d{1,2})(?:日)?'
    r'(?:[^\d]{0,5}(\d{1,2}):(\d{2})(?::(\d{2}))?)?',
  );
  static final RegExp _yearLastDate = RegExp(
    r'\b(\d{1,2})[-/.](\d{1,2})[-/.]((?:19|20)?\d{2})'
    r'(?:[^\d]{0,5}(\d{1,2}):(\d{2})(?::(\d{2}))?)?',
  );

  ParsedReceiptDraft parse(
    List<OcrCandidate> observations,
    List<ParsedOcrAmount> amounts, {
    required DateTime now,
    required String languageCode,
  }) {
    final merchant = _parseMerchant(observations);
    final total = _parseTotal(amounts);
    final date = _parseDate(observations, now: now, languageCode: languageCode);
    return ParsedReceiptDraft(
      merchantName: merchant,
      totalAmount: total?.amount,
      occurredAt: date?.value,
      // Merchant headers are especially prone to OCR noise and should always
      // remain visibly reviewable in the editor.
      merchantNeedsConfirmation: merchant != null,
      amountNeedsConfirmation: total?.needsConfirmation ?? false,
      dateNeedsConfirmation: date?.needsConfirmation ?? false,
    );
  }

  String? _parseMerchant(List<OcrCandidate> observations) {
    for (final observation in observations.take(12)) {
      final text = observation.text.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (text.length < 2 || text.length > 64) continue;
      if (_merchantExcluded.hasMatch(text)) continue;
      if (text.contains('@') || text.contains(RegExp(r'https?://|www\.'))) {
        continue;
      }
      final letters = RegExp(r'[A-Za-z\u3400-\u9fff]').allMatches(text).length;
      final digits = RegExp(r'\d').allMatches(text).length;
      if (letters < 2 || digits > letters * 2) continue;
      return text;
    }
    return null;
  }

  _ScoredAmount? _parseTotal(List<ParsedOcrAmount> amounts) {
    final positive = amounts
        .where((item) => item.amount.compareTo(DecimalValue.zero) > 0)
        .toList(growable: false);
    if (positive.isEmpty) return null;

    _ScoredAmount? best;
    for (final amount in positive) {
      final source = amount.source.text;
      var score = amount.source.confidence * 12 + amount.sourceIndex * 0.2;
      if (_strongTotal.hasMatch(source)) {
        score += 120;
      } else if (_total.hasMatch(source)) {
        score += 75;
      }
      if (_subtotal.hasMatch(source)) score -= 110;
      if (amount.inferredCurrency != null) score += 6;
      final candidate = _ScoredAmount(
        amount: amount,
        score: score,
        needsConfirmation:
            score < 70 ||
            amount.source.confidence < 0.65 ||
            amount.inferredCurrency == null,
      );
      if (best == null || candidate.score >= best.score) best = candidate;
    }
    return best;
  }

  _ParsedDate? _parseDate(
    List<OcrCandidate> observations, {
    required DateTime now,
    required String languageCode,
  }) {
    for (final observation in observations) {
      final first = _yearFirstDate.firstMatch(observation.text);
      if (first != null) {
        final parsed = _dateFromParts(
          year: int.parse(first.group(1)!),
          month: int.parse(first.group(2)!),
          day: int.parse(first.group(3)!),
          hour: int.tryParse(first.group(4) ?? '') ?? now.hour,
          minute: int.tryParse(first.group(5) ?? '') ?? now.minute,
          second: int.tryParse(first.group(6) ?? '') ?? 0,
          now: now,
        );
        if (parsed != null) {
          return _ParsedDate(
            value: parsed,
            needsConfirmation: observation.confidence < 0.65,
          );
        }
      }

      final last = _yearLastDate.firstMatch(observation.text);
      if (last == null) continue;
      final firstPart = int.parse(last.group(1)!);
      final secondPart = int.parse(last.group(2)!);
      final ambiguous = firstPart <= 12 && secondPart <= 12;
      final month = firstPart > 12 ? secondPart : firstPart;
      final day = firstPart > 12 ? firstPart : secondPart;
      var year = int.parse(last.group(3)!);
      if (year < 100) year += year >= 70 ? 1900 : 2000;
      final parsed = _dateFromParts(
        year: year,
        month: month,
        day: day,
        hour: int.tryParse(last.group(4) ?? '') ?? now.hour,
        minute: int.tryParse(last.group(5) ?? '') ?? now.minute,
        second: int.tryParse(last.group(6) ?? '') ?? 0,
        now: now,
      );
      if (parsed != null) {
        return _ParsedDate(
          value: parsed,
          needsConfirmation:
              ambiguous ||
              observation.confidence < 0.65 ||
              languageCode == 'zh',
        );
      }
    }
    return null;
  }

  DateTime? _dateFromParts({
    required int year,
    required int month,
    required int day,
    required int hour,
    required int minute,
    required int second,
    required DateTime now,
  }) {
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    if (hour > 23 || minute > 59 || second > 59) return null;
    final value = DateTime(year, month, day, hour, minute, second);
    if (value.year != year || value.month != month || value.day != day) {
      return null;
    }
    if (value.isAfter(now.add(const Duration(days: 2))) || year < 2000) {
      return null;
    }
    return value;
  }
}

final class _ScoredAmount {
  const _ScoredAmount({
    required this.amount,
    required this.score,
    required this.needsConfirmation,
  });

  final ParsedOcrAmount amount;
  final double score;
  final bool needsConfirmation;
}

final class _ParsedDate {
  const _ParsedDate({required this.value, required this.needsConfirmation});

  final DateTime value;
  final bool needsConfirmation;
}
