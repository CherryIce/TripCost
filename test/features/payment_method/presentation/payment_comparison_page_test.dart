import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/infrastructure/app_providers.dart';
import 'package:trip_cost/core/money/currency.dart';
import 'package:trip_cost/core/money/decimal_value.dart';
import 'package:trip_cost/core/money/money.dart';
import 'package:trip_cost/core/rates/domain/exchange_rate_repository.dart';
import 'package:trip_cost/features/converter/application/converter_controller.dart';
import 'package:trip_cost/features/payment_method/presentation/payment_comparison_page.dart';
import 'package:trip_cost/l10n/app_localizations.dart';

import '../../../helpers/m4_fakes.dart';

void main() {
  testWidgets('shows saved methods when they apply to the billing currency', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(<PaymentMethodModel>[
        _paymentMethod(id: 'one', name: '1% card', currencyCode: 'CNY'),
        _paymentMethod(id: 'two', name: '1.5% card', currencyCode: 'CNY'),
      ], quoteCurrencyCode: 'CNY'),
    );
    await tester.pumpAndSettle();

    expect(find.text('1% card'), findsOneWidget);
    expect(find.text('1.5% card'), findsOneWidget);
    expect(
      find.text('Add cash or a card to compare estimated costs.'),
      findsNothing,
    );
  });

  testWidgets('does not ask to add when saved methods are not applicable', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(<PaymentMethodModel>[
        _paymentMethod(id: 'one', name: 'CNY card', currencyCode: 'CNY'),
      ], quoteCurrencyCode: 'USD'),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('none apply to purchases billed in USD'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Your payment methods are still saved; they just cannot be used for this conversion.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Add cash or a card to compare estimated costs.'),
      findsNothing,
    );
    expect(find.text('Add'), findsNothing);
    expect(find.text('Manage'), findsNWidgets(2));
  });
}

Widget _testApp(
  List<PaymentMethodModel> methods, {
  required String quoteCurrencyCode,
}) {
  final catalog = CurrencyCatalog();
  final transactionCurrency = catalog.resolve('AED');
  final quoteCurrency = catalog.resolve(quoteCurrencyCode);
  final now = DateTime.utc(2026, 8, 18, 8);
  final draft = ConversionDraft(
    transactionAmount: Money(
      amount: DecimalValue.parse('1000'),
      currency: transactionCurrency,
    ),
    rateResolution: RateResolution(
      availability: RateAvailability.liveMarket,
      snapshot: RateSnapshotModel(
        metadata: SyncRecordMetadata(
          recordId: 'rate',
          syncVersion: 1,
          updatedAt: now,
        ),
        baseCurrency: transactionCurrency,
        quoteCurrency: quoteCurrency,
        rate: DecimalValue.parse('1.9'),
        sourceType: RateSourceType.market,
        sourceName: 'test',
        sourceTimestamp: now,
        fetchedAt: now,
        isCached: false,
      ),
    ),
  );
  return ProviderScope(
    overrides: [
      paymentMethodRepositoryProvider.overrideWithValue(
        MemoryPaymentMethodRepository(methods),
      ),
    ],
    child: CupertinoApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: PaymentComparisonPage(draft: draft),
    ),
  );
}

PaymentMethodModel _paymentMethod({
  required String id,
  required String name,
  required String currencyCode,
}) {
  final now = DateTime.utc(2026, 8, 18, 8);
  return PaymentMethodModel(
    metadata: SyncRecordMetadata(recordId: id, syncVersion: 1, updatedAt: now),
    name: name,
    type: PaymentMethodType.creditCard,
    network: PaymentNetwork.unknown,
    billingCurrency: CurrencyCatalog().resolve(currencyCode),
    foreignFeePercent: DecimalValue.parse('1'),
    crossBorderFeePercent: DecimalValue.zero,
    rateMarkupPercent: DecimalValue.zero,
    fixedFee: DecimalValue.zero,
    cashbackPercent: DecimalValue.zero,
    minimumFee: null,
    maximumFee: null,
    supportedTransactionTypes: const <TransactionType>{
      TransactionType.purchase,
    },
    createdAt: now,
  );
}
