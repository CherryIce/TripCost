import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/infrastructure/app_providers.dart';
import 'package:trip_cost/core/money/currency.dart';
import 'package:trip_cost/core/storage/files/receipt_storage.dart';
import 'package:trip_cost/core/storage/settings/drift_settings_repository.dart';
import 'package:trip_cost/features/expense/application/expenses_controller.dart';
import 'package:trip_cost/features/expense/presentation/ledger_page.dart';
import 'package:trip_cost/features/scanner/application/scanner_gateways.dart';
import 'package:trip_cost/l10n/app_localizations.dart';

import '../../../helpers/isolated_test_database.dart';
import '../../../helpers/m4_fakes.dart';
import '../../../helpers/m5_fixtures.dart';

void main() {
  test('receipt picker imports the image into private storage', () async {
    final root = await Directory.systemTemp.createTemp('receipt-editor-test-');
    addTearDown(() => root.delete(recursive: true));
    final source = File('${root.path}/source.png');
    await source.writeAsBytes(<int>[0, 1, 2, 3]);

    final reference = await importReceiptFromPhotoLibrary(
      picker: _ReceiptPicker(source.path),
      storage: ReceiptStorage(rootDirectory: () async => root),
    );

    expect(reference, startsWith('receipts/'));
    final imported = await Directory('${root.path}/receipts').list().toList();
    expect(imported, hasLength(1));
    expect(imported.single.path, isNot(source.path));
  });

  test('reopening a recent-seven-days filter preserves seven days', () {
    final to = DateTime.utc(2026, 8, 18, 8);
    final filter = LedgerFilter(
      from: to.subtract(const Duration(days: 7)),
      to: to,
    );

    expect(ledgerRecentDaySelection(filter), 7);
  });

  test('category totals exclude voided entries and apply signed refunds', () {
    final totals = ledgerCategoryTotals(<ExpenseModel>[
      fixtureExpense(estimate: '100'),
      fixtureExpense(
        id: 'voided',
        estimate: '80',
        budgetIncluded: false,
        entryType: ExpenseEntryType.voided,
      ),
      fixtureExpense(
        id: 'refund',
        estimate: '-25',
        actual: '-25',
        entryType: ExpenseEntryType.partialRefund,
        relatedExpenseId: 'expense-1',
        status: ExpenseStatus.confirmed,
      ),
    ]);

    expect(totals['food|CNY']!.amount.toString(), '75');
  });

  test('refund policy subtracts all existing refunds from the original', () {
    final original = fixtureExpense(estimate: '100');
    final refunded = refundedAmountFor(original, <ExpenseModel>[
      fixtureExpense(
        id: 'refund-1',
        estimate: '-40',
        actual: '-40',
        entryType: ExpenseEntryType.partialRefund,
        relatedExpenseId: original.metadata.recordId,
        status: ExpenseStatus.confirmed,
      ),
      fixtureExpense(
        id: 'refund-2',
        estimate: '-60',
        actual: '-60',
        entryType: ExpenseEntryType.refund,
        relatedExpenseId: original.metadata.recordId,
        status: ExpenseStatus.confirmed,
      ),
    ]);

    expect(refunded.toString(), '100');
    expect(originalRefundableAmount(original).toString(), '100');
  });

  testWidgets('standalone editor loads persisted currency defaults', (
    tester,
  ) async {
    final database = createIsolatedTestDatabase();
    final catalog = CurrencyCatalog();
    final settings = MemorySettingsRepository(
      UserSettingsModel(
        metadata: SyncRecordMetadata(
          recordId: DriftSettingsRepository.settingsRecordId,
          syncVersion: 2,
          updatedAt: DateTime.utc(2026, 8, 19, 3),
        ),
        defaultCurrency: catalog.resolve('CNY'),
        lastTransactionCurrency: catalog.resolve('USD'),
        favoriteCurrencies: const <Currency>[],
        languageMode: AppLanguageMode.simplifiedChinese,
        refreshInterval: const Duration(hours: 6),
        wifiOnlyRefresh: false,
        syncEnabled: false,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          settingsRepositoryProvider.overrideWithValue(settings),
        ],
        child: CupertinoApp(
          locale: const Locale('zh'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ExpenseEditorPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const Key('expense-transaction-currency')),
        matching: find.text('USD'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('expense-home-currency')),
        matching: find.text('CNY'),
      ),
      findsOneWidget,
    );
  });
}

final class _ReceiptPicker implements ScannerImagePicker {
  const _ReceiptPicker(this.path);

  final String path;

  @override
  Future<String?> pick(ScannerImageSource source) async => path;
}
