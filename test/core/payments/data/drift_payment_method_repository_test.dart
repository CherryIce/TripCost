import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/money/currency.dart';
import 'package:trip_cost/core/money/decimal_value.dart';
import 'package:trip_cost/core/payments/data/drift_payment_method_repository.dart';
import 'package:trip_cost/core/storage/database/app_database.dart';

void main() {
  late AppDatabase database;
  late DriftPaymentMethodRepository repository;
  final catalog = CurrencyCatalog();
  final now = DateTime.utc(2026, 8, 17, 8);

  setUp(() {
    database = AppDatabase.inMemory();
    repository = DriftPaymentMethodRepository(database, clock: () => now);
  });

  tearDown(() => database.close());

  test('round-trips card rules, transaction types and cash rate', () async {
    final method = _method(catalog: catalog, now: now);
    await repository.save(method);

    final restored = (await repository.listActive()).single;
    expect(restored.name, 'Travel card');
    expect(restored.foreignFeePercent, DecimalValue.parse('1.5'));
    expect(restored.minimumFee, DecimalValue.parse('2'));
    expect(restored.maximumFee, DecimalValue.parse('30'));
    expect(restored.cashExchangeRate, DecimalValue.parse('0.05'));
    expect(restored.supportedTransactionTypes, <TransactionType>{
      TransactionType.purchase,
      TransactionType.atm,
    });
  });

  test('soft deletion hides configuration without deleting its row', () async {
    await repository.save(_method(catalog: catalog, now: now));
    await repository.softDelete('payment-1', now.add(const Duration(hours: 1)));

    expect(await repository.listActive(), isEmpty);
    final rows = await database
        .customSelect('SELECT * FROM payment_methods')
        .get();
    expect(rows, hasLength(1));
    expect(rows.single.data['deleted_at'], isNotNull);
  });
}

PaymentMethodModel _method({
  required CurrencyCatalog catalog,
  required DateTime now,
}) {
  return PaymentMethodModel(
    metadata: SyncRecordMetadata(
      recordId: 'payment-1',
      syncVersion: 1,
      updatedAt: now,
    ),
    name: 'Travel card',
    type: PaymentMethodType.creditCard,
    network: PaymentNetwork.visa,
    billingCurrency: catalog.resolve('CNY'),
    foreignFeePercent: DecimalValue.parse('1.5'),
    crossBorderFeePercent: DecimalValue.parse('1'),
    rateMarkupPercent: DecimalValue.parse('0.2'),
    fixedFee: DecimalValue.parse('3'),
    cashbackPercent: DecimalValue.parse('0.5'),
    minimumFee: DecimalValue.parse('2'),
    maximumFee: DecimalValue.parse('30'),
    cashExchangeRate: DecimalValue.parse('0.05'),
    supportedTransactionTypes: <TransactionType>{
      TransactionType.purchase,
      TransactionType.atm,
    },
    notes: 'No sensitive card data',
    createdAt: now,
  );
}
