import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/money/currency.dart';
import 'package:trip_cost/core/money/decimal_value.dart';

void main() {
  final now = DateTime.utc(2026, 8, 17, 8);
  final cny = CurrencyCatalog().resolve('CNY');

  test('sync metadata rejects local wall-clock timestamps', () {
    expect(
      () => SyncRecordMetadata(
        recordId: 'record-1',
        syncVersion: 1,
        updatedAt: DateTime(2026, 8, 17, 8),
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('freezing payment rules creates an immutable history snapshot', () {
    final transactionTypes = <TransactionType>{TransactionType.purchase};
    final paymentMethod = PaymentMethodModel(
      metadata: SyncRecordMetadata(
        recordId: 'payment-1',
        syncVersion: 1,
        updatedAt: now,
      ),
      name: 'Travel card',
      type: PaymentMethodType.creditCard,
      network: PaymentNetwork.visa,
      billingCurrency: cny,
      foreignFeePercent: DecimalValue.parse('1.5'),
      crossBorderFeePercent: DecimalValue.zero,
      rateMarkupPercent: DecimalValue.zero,
      fixedFee: DecimalValue.zero,
      cashbackPercent: DecimalValue.parse('0.5'),
      minimumFee: null,
      maximumFee: null,
      supportedTransactionTypes: transactionTypes,
      createdAt: now,
    );
    final snapshot = paymentMethod.freezeRules();
    transactionTypes.add(TransactionType.atm);

    expect(snapshot.foreignFeePercent.toString(), '1.5');
    expect(snapshot.supportedTransactionTypes, <TransactionType>{
      TransactionType.purchase,
    });
    expect(
      () => snapshot.supportedTransactionTypes.add(TransactionType.atm),
      throwsUnsupportedError,
    );
  });
}
