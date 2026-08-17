import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/core/platform/generated/platform_apis.g.dart';
import 'package:trip_cost/features/scanner/domain/ocr_amount_parser.dart';

void main() {
  OcrCandidate observation(String text, {double confidence = 0.9}) =>
      OcrCandidate(
        text: text,
        confidence: confidence,
        x: 0.1,
        y: 0.2,
        width: 0.3,
        height: 0.1,
      );

  test('parses multi-locale fixture without binary floating point', () {
    final fixture =
        jsonDecode(
              File('test/fixtures/ocr_amount_samples.json').readAsStringSync(),
            )
            as List<Object?>;
    final parser = OcrAmountParser();

    for (final value in fixture.cast<Map<String, Object?>>()) {
      final parsed = parser.parse(<OcrCandidate>[
        observation(
          value['text']! as String,
          confidence: (value['confidence']! as num).toDouble(),
        ),
      ]);
      expect(parsed, hasLength(1), reason: value['text']! as String);
      expect(parsed.single.amount.toString(), value['amount']);
      expect(parsed.single.inferredCurrency?.code, value['currency']);
      expect(
        parsed.single.isLowConfidence,
        (value['confidence']! as num).toDouble() < 0.5,
      );
    }
  });

  test('filters dates, times, phone numbers and prefixed identifiers', () {
    final parser = OcrAmountParser();
    final parsed = parser.parse(<OcrCandidate>[
      observation('2026-08-17 18:30'),
      observation('Tel +86 138 0013 8000'),
      observation('Order No. 20260817001'),
      observation('Date 2026-08-17 · Total EUR 18,90'),
    ]);

    expect(parsed, hasLength(1));
    expect(parsed.single.amount.toString(), '18.9');
    expect(parsed.single.inferredCurrency?.code, 'EUR');
  });

  test(
    'keeps multiple prices and preserves ambiguous yen for confirmation',
    () {
      final parsed = OcrAmountParser().parse(<OcrCandidate>[
        observation('Lunch ￥1,200  Dinner ￥2,400'),
      ]);

      expect(parsed.map((item) => item.amount.toString()), <String>[
        '1200',
        '2400',
      ]);
      expect(
        parsed.map(
          (item) => item.currencyOptions.map((currency) => currency.code),
        ),
        everyElement(<String>['CNY', 'JPY']),
      );
      expect(parsed.every((item) => item.inferredCurrency == null), isTrue);
    },
  );

  test(
    'retains negative and low-confidence candidates for user correction',
    () {
      final parsed = OcrAmountParser().parse(<OcrCandidate>[
        observation('-€12,50', confidence: 0.2),
      ]);

      expect(parsed.single.amount.toString(), '-12.5');
      expect(parsed.single.inferredCurrency?.code, 'EUR');
      expect(parsed.single.isLowConfidence, isTrue);
    },
  );
}
