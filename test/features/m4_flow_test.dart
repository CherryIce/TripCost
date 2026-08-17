import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/app/app.dart';
import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/infrastructure/app_providers.dart';
import 'package:trip_cost/core/money/currency.dart';
import 'package:trip_cost/core/money/decimal_value.dart';
import 'package:trip_cost/features/startup/application/startup_controller.dart';
import 'package:trip_cost/features/startup/data/startup_state_store.dart';

import '../helpers/m4_fakes.dart';

void main() {
  testWidgets('home corrects an expression in place and opens comparison', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    final field = find.byKey(const Key('converter-expression'));
    expect(field, findsOneWidget);
    await tester.enterText(field, '12 / 0');
    await tester.pump();
    expect(
      find.text('Check the expression and edit it in place.'),
      findsOneWidget,
    );

    await tester.enterText(field, '1200 * 3 + 500');
    await tester.pump();
    final result = tester.widget<Text>(
      find.byKey(const Key('converter-result')),
    );
    expect(result.data, contains('196.15'));
    expect(result.data, contains('CNY'));
    expect(find.textContaining('Latest reference rate'), findsOneWidget);

    await tester.ensureVisible(find.text('Compare payment methods'));
    await tester.tap(find.text('Compare payment methods'));
    await tester.pumpAndSettle();
    expect(find.text('Lowest estimated cost'), findsOneWidget);
    expect(find.text('No-fee card'), findsOneWidget);
    expect(find.text('2% card'), findsOneWidget);
    expect(find.textContaining('All figures are estimates'), findsOneWidget);
  });

  testWidgets('DCC page matches the product example', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Check DCC'));
    await tester.tap(find.text('Check DCC'));
    await tester.pumpAndSettle();
    final fields = find.byType(CupertinoTextField);
    expect(fields, findsNWidgets(2));
    await tester.enterText(fields.at(1), '648');
    await tester.pump();

    expect(find.textContaining('35.64'), findsOneWidget);
    expect(find.text('5.82%'), findsOneWidget);
    expect(find.textContaining('usually more transparent'), findsOneWidget);
  });

  testWidgets(
    'payment settings create cash and a custom credit card, then edit',
    (tester) async {
      await tester.pumpWidget(_testApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Payment methods').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('No-fee card'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(CupertinoTextField).first,
        'Edited card',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Edited card'), findsOneWidget);

      await tester.tap(find.byIcon(CupertinoIcons.add));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fully custom'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cash exchange'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Cash exchange'), findsOneWidget);

      await tester.tap(find.byIcon(CupertinoIcons.add));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(CupertinoTextField).first,
        'Custom credit',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Custom credit'), findsOneWidget);
      expect(find.textContaining('Credit card · CNY'), findsWidgets);
    },
  );
}

Widget _testApp() {
  return ProviderScope(
    overrides: [
      startupStateStoreProvider.overrideWithValue(_CompleteStartupStore()),
      rateRepositoryProvider.overrideWithValue(createFakeRateRepository()),
      settingsRepositoryProvider.overrideWithValue(MemorySettingsRepository()),
      tripRepositoryProvider.overrideWithValue(MemoryTripRepository()),
      expenseRepositoryProvider.overrideWithValue(MemoryExpenseRepository()),
      feeCalibrationRepositoryProvider.overrideWithValue(
        MemoryFeeCalibrationRepository(),
      ),
      networkStatusProvider.overrideWithValue(
        const FakeNetworkStatusProvider(),
      ),
      paymentMethodRepositoryProvider.overrideWithValue(
        MemoryPaymentMethodRepository(<PaymentMethodModel>[
          _paymentMethod(id: 'no-fee', name: 'No-fee card', fee: '0'),
          _paymentMethod(id: 'two-percent', name: '2% card', fee: '2'),
        ]),
      ),
    ],
    child: const TripCostApp(),
  );
}

PaymentMethodModel _paymentMethod({
  required String id,
  required String name,
  required String fee,
}) {
  final now = DateTime.utc(2026, 8, 17, 8);
  return PaymentMethodModel(
    metadata: SyncRecordMetadata(recordId: id, syncVersion: 1, updatedAt: now),
    name: name,
    type: PaymentMethodType.creditCard,
    network: PaymentNetwork.unknown,
    billingCurrency: CurrencyCatalog().resolve('CNY'),
    foreignFeePercent: DecimalValue.parse(fee),
    crossBorderFeePercent: DecimalValue.zero,
    rateMarkupPercent: DecimalValue.zero,
    fixedFee: DecimalValue.zero,
    cashbackPercent: DecimalValue.zero,
    minimumFee: null,
    maximumFee: null,
    supportedTransactionTypes: <TransactionType>{TransactionType.purchase},
    createdAt: now,
  );
}

final class _CompleteStartupStore implements StartupStateStore {
  @override
  Future<bool> isOnboardingComplete() async => true;

  @override
  Future<void> markOnboardingComplete() async {}
}
