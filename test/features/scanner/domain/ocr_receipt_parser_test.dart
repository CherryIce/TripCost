import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/core/platform/generated/platform_apis.g.dart';
import 'package:trip_cost/features/scanner/domain/ocr_amount_parser.dart';
import 'package:trip_cost/features/scanner/domain/ocr_receipt_parser.dart';

void main() {
  const receiptParser = OcrReceiptParser();
  final amountParser = OcrAmountParser();

  test('extracts merchant, total, and date from a receipt', () {
    final observations = <OcrCandidate>[
      _candidate('SAKURA MARKET'),
      _candidate('2026-08-18 19:42:16'),
      _candidate('SUBTOTAL JPY 1,100'),
      _candidate('TAX JPY 110'),
      _candidate('GRAND TOTAL JPY 1,210'),
    ];

    final result = receiptParser.parse(
      observations,
      amountParser.parse(observations),
      now: DateTime(2026, 8, 20, 9, 30),
      languageCode: 'en',
    );

    expect(result.merchantName, 'SAKURA MARKET');
    expect(result.totalAmount?.amount.toString(), '1210');
    expect(result.totalAmount?.inferredCurrency?.code, 'JPY');
    expect(result.occurredAt, DateTime(2026, 8, 18, 19, 42, 16));
    expect(result.merchantNeedsConfirmation, isTrue);
    expect(result.amountNeedsConfirmation, isFalse);
    expect(result.dateNeedsConfirmation, isFalse);
  });

  test('weak receipt fields remain reviewable and never block a draft', () {
    final observations = <OcrCandidate>[
      _candidate('樱花商店', confidence: 0.55),
      _candidate('08/18/2026', confidence: 0.55),
      _candidate('128.00', confidence: 0.55),
    ];

    final result = receiptParser.parse(
      observations,
      amountParser.parse(observations),
      now: DateTime(2026, 8, 20, 9, 30),
      languageCode: 'zh',
    );

    expect(result.merchantName, '樱花商店');
    expect(result.totalAmount?.amount.toString(), '128');
    expect(result.occurredAt, isNotNull);
    expect(result.merchantNeedsConfirmation, isTrue);
    expect(result.amountNeedsConfirmation, isTrue);
    expect(result.dateNeedsConfirmation, isTrue);
  });

  test('prefers a labeled total over tax, tip, and subtotal values', () {
    final observations = <OcrCandidate>[
      _candidate('BISTRO'),
      _candidate(r'SUBTOTAL $40.00'),
      _candidate(r'TAX $4.00'),
      _candidate(r'TIP $8.00'),
      _candidate(r'AMOUNT DUE $52.00'),
    ];

    final result = receiptParser.parse(
      observations,
      amountParser.parse(observations),
      now: DateTime(2026, 8, 20),
      languageCode: 'en',
    );

    expect(result.totalAmount?.amount.toString(), '52');
    expect(result.totalAmount?.inferredCurrency?.code, 'USD');
  });
}

OcrCandidate _candidate(String text, {double confidence = 0.95}) =>
    OcrCandidate(
      text: text,
      confidence: confidence,
      x: 0,
      y: 0,
      width: 1,
      height: 0.1,
    );
