import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/domain/repositories.dart';
import 'package:trip_cost/core/infrastructure/app_providers.dart';
import 'package:trip_cost/core/money/currency.dart';
import 'package:trip_cost/core/money/decimal_value.dart';
import 'package:trip_cost/core/money/money.dart';
import 'package:trip_cost/core/storage/files/receipt_storage.dart';
import 'package:trip_cost/core/storage/settings/drift_settings_repository.dart';
import 'package:trip_cost/features/expense/application/expense_draft.dart';
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
      dateRange: LedgerDateRange.recent7Days,
      from: to.subtract(const Duration(days: 7)),
      to: to,
    );

    expect(filter.dateRange, LedgerDateRange.recent7Days);
  });

  test('custom seven-day range does not collapse into a quick range', () {
    final filter = LedgerFilter(
      dateRange: LedgerDateRange.custom,
      from: DateTime.utc(2026, 8, 1),
      to: DateTime.utc(2026, 8, 8),
    );

    expect(filter.dateRange, LedgerDateRange.custom);
  });

  test('ledger filter supports selecting multiple categories', () {
    const filter = LedgerFilter(categories: <String>{'food', 'shopping'});

    expect(filter.matches(fixtureExpense(category: 'food')), isTrue);
    expect(filter.matches(fixtureExpense(category: 'shopping')), isTrue);
    expect(filter.matches(fixtureExpense(category: 'hotel')), isFalse);
  });

  test('ledger period separates this month from last month', () {
    final now = DateTime(2026, 8, 19);

    expect(
      ledgerPeriodMatches(
        LedgerPeriod.thisMonth,
        fixtureExpense(occurredAt: DateTime.utc(2026, 8, 2)),
        now,
      ),
      isTrue,
    );
    expect(
      ledgerPeriodMatches(
        LedgerPeriod.lastMonth,
        fixtureExpense(occurredAt: DateTime.utc(2026, 7, 31)),
        now,
      ),
      isTrue,
    );
  });

  test(
    'saving an already-posted card expense also saves calibration',
    () async {
      final repository = _CapturingExpenseRepository();
      final container = ProviderContainer(
        overrides: [expenseRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      await container.read(expensesControllerProvider.future);

      await container
          .read(expensesControllerProvider.notifier)
          .saveConfirmed(
            fixtureExpense(actual: '105', status: ExpenseStatus.confirmed),
          );

      expect(repository.calibration, isNotNull);
      expect(repository.calibration!.effectiveMarkupPercent.toString(), '5');
    },
  );

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

  testWidgets('pending detail offers posting or voiding but not refunding', (
    tester,
  ) async {
    final expense = fixtureExpense();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          expenseRepositoryProvider.overrideWithValue(
            MemoryExpenseRepository(<ExpenseModel>[expense]),
          ),
          feeCalibrationRepositoryProvider.overrideWithValue(
            MemoryFeeCalibrationRepository(),
          ),
        ],
        child: _localizedApp(
          home: ExpenseDetailPage(
            expenseId: expense.metadata.recordId,
            initial: expense,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('补录实际入账'), findsOneWidget);
    expect(find.text('撤销记录'), findsOneWidget);
    expect(find.text('记录退款'), findsNothing);
  });

  testWidgets(
    'fully refunded detail shows net state and controlled correction',
    (tester) async {
      final original = fixtureExpense(
        actual: '100',
        status: ExpenseStatus.confirmed,
      );
      final refund = fixtureExpense(
        id: 'refund-1',
        estimate: '-100',
        actual: '-100',
        status: ExpenseStatus.confirmed,
        entryType: ExpenseEntryType.refund,
        relatedExpenseId: original.metadata.recordId,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expenseRepositoryProvider.overrideWithValue(
              MemoryExpenseRepository(<ExpenseModel>[original, refund]),
            ),
            feeCalibrationRepositoryProvider.overrideWithValue(
              MemoryFeeCalibrationRepository(),
            ),
          ],
          child: _localizedApp(
            home: ExpenseDetailPage(
              expenseId: original.metadata.recordId,
              initial: original,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('已全部退款'), findsOneWidget);
      expect(find.text('累计退款'), findsOneWidget);
      expect(find.text('净支出'), findsOneWidget);
      expect(find.text('更正原交易金额'), findsOneWidget);
      expect(find.text('修改实际入账'), findsNothing);
      expect(find.text('继续退款'), findsNothing);
      expect(find.text('退款记录'), findsOneWidget);
    },
  );

  testWidgets('refund detail links back and exposes refund correction', (
    tester,
  ) async {
    final original = fixtureExpense(
      actual: '100',
      status: ExpenseStatus.confirmed,
    );
    final refund = fixtureExpense(
      id: 'refund-1',
      estimate: '-40',
      actual: '-40',
      status: ExpenseStatus.confirmed,
      entryType: ExpenseEntryType.partialRefund,
      relatedExpenseId: original.metadata.recordId,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          expenseRepositoryProvider.overrideWithValue(
            MemoryExpenseRepository(<ExpenseModel>[original, refund]),
          ),
          feeCalibrationRepositoryProvider.overrideWithValue(
            MemoryFeeCalibrationRepository(),
          ),
        ],
        child: _localizedApp(
          home: ExpenseDetailPage(
            expenseId: refund.metadata.recordId,
            initial: refund,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('关联原交易'), findsOneWidget);
    expect(find.text('更正退款金额'), findsOneWidget);
    expect(find.text('查看原交易'), findsOneWidget);
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
        matching: find.textContaining('CNY'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('receipt OCR prefill populates the reviewable expense editor', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    final root = Directory.systemTemp.createTempSync('ocr-prefill-test-');
    addTearDown(() => root.deleteSync(recursive: true));
    final receipts = Directory('${root.path}/receipts')..createSync();
    File(
      '${Directory.current.path}/assets/branding/launch_mark.png',
    ).copySync('${receipts.path}/receipt.png');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tripRepositoryProvider.overrideWithValue(MemoryTripRepository()),
          paymentMethodRepositoryProvider.overrideWithValue(
            MemoryPaymentMethodRepository(),
          ),
          rateRepositoryProvider.overrideWithValue(createFakeRateRepository()),
          settingsRepositoryProvider.overrideWithValue(
            MemorySettingsRepository(),
          ),
          receiptStorageProvider.overrideWithValue(
            ReceiptStorage(rootDirectory: () async => root),
          ),
        ],
        child: _localizedApp(
          home: ExpenseEditorPage(
            arguments: ExpenseEditorArguments(
              receiptPrefill: ReceiptExpensePrefill(
                title: '樱花商店',
                transactionAmount: Money(
                  amount: DecimalValue.parse('1280'),
                  currency: CurrencyCatalog().resolve('JPY'),
                ),
                occurredAt: DateTime.utc(2026, 8, 18, 11, 42, 16),
                receiptLocalPath: 'receipts/receipt.png',
                titleNeedsConfirmation: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    for (
      var attempt = 0;
      attempt < 20 && find.text('已从票据填入 4 项，请核对').evaluate().isEmpty;
      attempt += 1
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 25)),
      );
      await tester.pump();
    }

    expect(find.text('已从票据填入 4 项，请核对'), findsOneWidget);
    expect(find.text('待确认'), findsOneWidget);
    expect(
      tester
          .widget<CupertinoTextField>(_field('expense-title-field'))
          .controller
          ?.text,
      '樱花商店',
    );
    expect(
      tester
          .widget<CupertinoTextField>(
            _field('expense-transaction-amount-field'),
          )
          .controller
          ?.text,
      '1280',
    );
    expect(find.byKey(const Key('expense-date-row')), findsOneWidget);

    for (
      var attempt = 0;
      attempt < 8 &&
          find.byKey(const Key('expense-receipt-section')).evaluate().isEmpty;
      attempt += 1
    ) {
      await tester.drag(
        find.byKey(const Key('expense-editor-list')),
        const Offset(0, -300),
      );
      await tester.pump();
    }
    for (
      var attempt = 0;
      attempt < 20 &&
          find.byKey(const Key('expense-receipt-thumbnail')).evaluate().isEmpty;
      attempt += 1
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 25)),
      );
      await tester.pump();
    }
    expect(find.byKey(const Key('expense-receipt-thumbnail')), findsOneWidget);
  });

  testWidgets('manual entry date picker exposes year through second', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tripRepositoryProvider.overrideWithValue(MemoryTripRepository()),
          paymentMethodRepositoryProvider.overrideWithValue(
            MemoryPaymentMethodRepository(),
          ),
          rateRepositoryProvider.overrideWithValue(createFakeRateRepository()),
          settingsRepositoryProvider.overrideWithValue(
            MemorySettingsRepository(),
          ),
        ],
        child: _localizedApp(home: const ExpenseEditorPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('expense-editor-adjustments-group')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.byKey(const Key('expense-date-row')),
      find.byKey(const Key('expense-editor-list')),
      const Offset(0, -280),
    );
    await tester.tap(find.byKey(const Key('expense-date-row')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('precise-date-time-picker-sheet')),
      findsOneWidget,
    );
    for (final part in <String>[
      'year',
      'month',
      'day',
      'hour',
      'minute',
      'second',
    ]) {
      expect(find.byKey(Key('precise-picker-$part')), findsOneWidget);
    }
    final band = find.byKey(
      const Key('precise-date-time-picker-selection-band'),
    );
    expect(band, findsOneWidget);
    expect(tester.getSize(band).height, 44);

    tester
        .widget<CupertinoPicker>(find.byKey(const Key('precise-picker-second')))
        .onSelectedItemChanged
        ?.call(37);
    await tester.pump();
    expect(
      tester
          .widget<Text>(
            find.byKey(const Key('precise-date-time-picker-summary')),
          )
          .data,
      contains(':37'),
    );

    await tester.tap(find.byKey(const Key('precise-date-time-picker-done')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('expense-date-row')),
        matching: find.textContaining(':37'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('ledger shows the overview and opens filters in a bottom sheet', (
    tester,
  ) async {
    final expense = fixtureExpense(
      occurredAt: DateTime.now().toUtc(),
      actual: '105',
      status: ExpenseStatus.confirmed,
    );
    final hotelExpense = fixtureExpense(
      id: 'expense-2',
      title: 'Hotel',
      category: 'hotel',
      occurredAt: DateTime.now().toUtc(),
      actual: '200',
      status: ExpenseStatus.confirmed,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          expenseRepositoryProvider.overrideWithValue(
            MemoryExpenseRepository(<ExpenseModel>[expense, hotelExpense]),
          ),
          tripRepositoryProvider.overrideWithValue(
            MemoryTripRepository(<TripModel>[fixtureTrip()]),
          ),
          paymentMethodRepositoryProvider.overrideWithValue(
            MemoryPaymentMethodRepository(<PaymentMethodModel>[
              fixturePaymentMethod(),
            ]),
          ),
          feeCalibrationRepositoryProvider.overrideWithValue(
            MemoryFeeCalibrationRepository(),
          ),
        ],
        child: _localizedApp(home: const LedgerPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('本月支出'), findsOneWidget);
    expect(find.text('明细'), findsOneWidget);
    expect(find.text('已入账'), findsNWidgets(2));
    expect(find.byKey(const Key('ledger-summary-total')), findsOneWidget);
    expect(find.byIcon(Icons.restaurant_rounded), findsOneWidget);
    expect(find.byIcon(Icons.bed_rounded), findsOneWidget);

    await tester.tap(find.byIcon(CupertinoIcons.slider_horizontal_3));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ledger-filter-sheet')), findsOneWidget);
    expect(find.text('30天'), findsOneWidget);
    expect(find.text('查看 2 笔记录'), findsOneWidget);

    final sheetWidth = tester
        .getSize(find.byKey(const Key('ledger-filter-sheet')))
        .width;
    final tripRowWidth = tester
        .getSize(find.byKey(const Key('ledger-filter-trip-row')))
        .width;
    expect(sheetWidth - tripRowWidth, lessThan(40));
    final tripValue = find.descendant(
      of: find.byKey(const Key('ledger-filter-trip-row')),
      matching: find.text('全部'),
    );
    final sheetRight = tester
        .getRect(find.byKey(const Key('ledger-filter-sheet')))
        .right;
    final valueRight = tester.getRect(tripValue).right;
    expect(sheetRight - valueRight, lessThan(56));

    final categoryRow = find.byKey(const Key('ledger-filter-category-row'));
    final categoryTitle = find.descendant(
      of: categoryRow,
      matching: find.text('分类'),
    );
    expect(
      (tester.getRect(categoryRow).center.dy -
              tester.getRect(categoryTitle).center.dy)
          .abs(),
      lessThan(1),
    );

    await tester.tap(find.byKey(const Key('ledger-filter-currency-row')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('JPY'));
    await tester.pumpAndSettle();

    expect(find.byIcon(CupertinoIcons.money_yen_circle), findsOneWidget);

    await tester.tap(find.text('自定义'));
    await tester.pumpAndSettle();

    final datePickerSheet = find.byKey(const Key('ledger-date-picker-sheet'));
    expect(datePickerSheet, findsOneWidget);
    expect(tester.getSize(datePickerSheet).height, greaterThanOrEqualTo(430));
    expect(find.text('选择日期范围'), findsOneWidget);
    expect(
      find.byKey(const Key('ledger-date-range-start-field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('ledger-date-range-end-field')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('ledger-date-picker-cancel')), findsOneWidget);
    expect(find.byKey(const Key('ledger-date-picker-done')), findsOneWidget);
    final wheel = find.descendant(
      of: find.byKey(const Key('ledger-date-picker-wheel')),
      matching: find.byType(CupertinoDatePicker),
    );
    expect(wheel, findsOneWidget);
    expect(find.byType(CupertinoDatePicker), findsOneWidget);
    var picker = tester.widget<CupertinoDatePicker>(wheel);
    expect(picker.itemExtent, 44);
    expect(picker.selectionOverlayBuilder, isNotNull);
    expect(
      find.byKey(const Key('ledger-date-picker-selection-band')),
      findsOneWidget,
    );
    final selectionBandWidth = tester
        .getSize(find.byKey(const Key('ledger-date-picker-selection-band')))
        .width;
    expect(
      tester.getSize(datePickerSheet).width - selectionBandWidth,
      lessThanOrEqualTo(28),
    );
    picker.onDateTimeChanged(DateTime(2020, 1, 2));
    await tester.pump();
    expect(
      find.descendant(
        of: find.byKey(const Key('ledger-date-range-start-field')),
        matching: find.textContaining('2020'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('ledger-date-range-end-field')));
    await tester.pump();
    picker = tester.widget<CupertinoDatePicker>(wheel);
    expect(picker.minimumDate, DateTime(2020, 1, 2));
    picker.onDateTimeChanged(DateTime(2020, 1, 3));
    await tester.pump();
    expect(
      find.descendant(
        of: find.byKey(const Key('ledger-date-range-end-field')),
        matching: find.textContaining('2020'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('ledger-date-picker-done')));
    await tester.pumpAndSettle();
    expect(datePickerSheet, findsNothing);
    expect(find.byKey(const Key('ledger-filter-sheet')), findsOneWidget);
    final customDateSummary = find.byKey(
      const Key('ledger-custom-date-summary'),
    );
    expect(customDateSummary, findsOneWidget);
    expect(
      find.descendant(
        of: customDateSummary,
        matching: find.textContaining('2020'),
      ),
      findsOneWidget,
    );

    await tester.tap(customDateSummary);
    await tester.pumpAndSettle();
    expect(find.text('选择日期范围'), findsOneWidget);
    expect(find.byType(CupertinoDatePicker), findsOneWidget);
    await tester.tap(find.byKey(const Key('ledger-date-picker-cancel')));
    await tester.pumpAndSettle();
    expect(customDateSummary, findsOneWidget);

    await tester.tap(find.text('清除'));
    await tester.pumpAndSettle();
    expect(customDateSummary, findsNothing);

    await tester.tap(find.byIcon(CupertinoIcons.xmark));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ledger-filter-sheet')), findsNothing);
  });

  testWidgets('manual entry can be saved as already posted', (tester) async {
    final repository = MemoryExpenseRepository();
    final settings = MemorySettingsRepository(
      UserSettingsModel(
        metadata: SyncRecordMetadata(
          recordId: DriftSettingsRepository.settingsRecordId,
          syncVersion: 1,
          updatedAt: DateTime.utc(2026, 8, 19),
        ),
        defaultCurrency: fixtureCny,
        lastTransactionCurrency: fixtureJpy,
        favoriteCurrencies: const <Currency>[],
        languageMode: AppLanguageMode.simplifiedChinese,
        refreshInterval: const Duration(hours: 6),
        wifiOnlyRefresh: false,
        syncEnabled: false,
      ),
    );
    late final GoRouter router;
    router = GoRouter(
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (context, state) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: '/editor',
          builder: (context, state) => const ExpenseEditorPage(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          expenseRepositoryProvider.overrideWithValue(repository),
          tripRepositoryProvider.overrideWithValue(MemoryTripRepository()),
          paymentMethodRepositoryProvider.overrideWithValue(
            MemoryPaymentMethodRepository(),
          ),
          feeCalibrationRepositoryProvider.overrideWithValue(
            MemoryFeeCalibrationRepository(),
          ),
          settingsRepositoryProvider.overrideWithValue(settings),
          rateRepositoryProvider.overrideWithValue(
            createFakeRateRepository(rate: '0.05'),
          ),
        ],
        child: _localizedRouterApp(router),
      ),
    );
    final editorResult = router.push<void>('/editor');
    await tester.pumpAndSettle();

    await tester.enterText(_field('expense-title-field'), '午餐');
    await tester.enterText(_field('expense-transaction-amount-field'), '2000');
    await tester.pump(const Duration(milliseconds: 251));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('expense-home-currency')),
        matching: find.text('CNY 100.00'),
      ),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('已入账'));
    await tester.tap(find.text('已入账'));
    await tester.pump();
    await tester.enterText(_field('expense-actual-amount-field'), '105');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    await editorResult;

    expect(repository.values, hasLength(1));
    expect(repository.values.single.status, ExpenseStatus.confirmed);
    expect(
      repository.values.single.actualFinalAmount?.amount.toString(),
      '105',
    );
  });

  testWidgets('trip and category picker stages cascade changes until done', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    final trip = fixtureTrip();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tripRepositoryProvider.overrideWithValue(
            MemoryTripRepository(<TripModel>[trip]),
          ),
          paymentMethodRepositoryProvider.overrideWithValue(
            MemoryPaymentMethodRepository(<PaymentMethodModel>[
              fixturePaymentMethod(),
            ]),
          ),
          rateRepositoryProvider.overrideWithValue(createFakeRateRepository()),
          settingsRepositoryProvider.overrideWithValue(
            MemorySettingsRepository(),
          ),
        ],
        child: _localizedApp(home: const ExpenseEditorPage()),
      ),
    );
    await tester.pumpAndSettle();

    final editorRow = find.byKey(const Key('expense-trip-category-row'));
    expect(
      find.descendant(of: editorRow, matching: find.text('无 · 购物')),
      findsOneWidget,
    );

    await tester.tap(editorRow);
    await tester.pumpAndSettle();

    final sheet = find.byKey(const Key('expense-context-picker-sheet'));
    expect(sheet, findsOneWidget);
    expect(tester.getSize(sheet).width, 390);
    expect(tester.getSize(sheet).height, closeTo(481, 1));
    expect(
      find.byKey(const Key('expense-context-picker-category-list')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.restaurant_rounded), findsOneWidget);
    expect(find.byIcon(Icons.bed_rounded), findsOneWidget);
    expect(
      tester
          .getSize(
            find.byKey(const Key('expense-context-picker-category-shopping')),
          )
          .height,
      greaterThanOrEqualTo(50),
    );

    await tester.tap(
      find.byKey(const Key('expense-context-picker-category-food')),
    );
    await tester.pump();
    expect(
      find.descendant(of: sheet, matching: find.text('无 · 餐饮')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: editorRow, matching: find.text('无 · 购物')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('expense-context-picker-trip-tab')));
    await tester.pump();
    expect(
      find.byKey(const Key('expense-context-picker-trip-list')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('expense-context-picker-trip-none')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('expense-context-picker-trip-trip-1')),
    );
    await tester.pump();
    expect(
      find.descendant(of: sheet, matching: find.text('Tokyo week · 餐饮')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('expense-context-picker-close')));
    await tester.pumpAndSettle();
    expect(sheet, findsNothing);
    expect(
      find.descendant(of: editorRow, matching: find.text('无 · 购物')),
      findsOneWidget,
    );

    await tester.tap(editorRow);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('expense-context-picker-category-food')),
    );
    await tester.tap(find.byKey(const Key('expense-context-picker-trip-tab')));
    await tester.pump();
    await tester.tap(
      find.byKey(const Key('expense-context-picker-trip-trip-1')),
    );
    await tester.tap(find.byKey(const Key('expense-context-picker-done')));
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: editorRow, matching: find.text('Tokyo week · 餐饮')),
      findsOneWidget,
    );
  });

  testWidgets(
    'manual entry links transaction amount to reference and estimated costs',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tripRepositoryProvider.overrideWithValue(
              MemoryTripRepository(<TripModel>[fixtureTrip()]),
            ),
            paymentMethodRepositoryProvider.overrideWithValue(
              MemoryPaymentMethodRepository(<PaymentMethodModel>[
                fixturePaymentMethod(),
              ]),
            ),
            rateRepositoryProvider.overrideWithValue(
              createFakeRateRepository(rate: '0.05'),
            ),
          ],
          child: _localizedApp(
            home: ExpenseEditorPage(
              arguments: ExpenseEditorArguments(trip: fixtureTrip()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        _field('expense-transaction-amount-field'),
        '2000',
      );
      await tester.pump(const Duration(milliseconds: 251));
      await tester.pumpAndSettle();

      expect(find.text('CNY 100.00'), findsOneWidget);
      expect(find.text('CNY 101.00'), findsOneWidget);
      expect(find.textContaining('Tokyo week'), findsOneWidget);
      expect(find.text('Travel card'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('expense-editor-adjustments-group')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      await tester.enterText(_field('expense-tax-field'), '2');
      await tester.pump(const Duration(milliseconds: 251));
      await tester.pumpAndSettle();

      expect(find.text('CNY 103.00'), findsOneWidget);
    },
  );

  testWidgets('save validation uses a compact toast below navigation', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tripRepositoryProvider.overrideWithValue(MemoryTripRepository()),
          paymentMethodRepositoryProvider.overrideWithValue(
            MemoryPaymentMethodRepository(),
          ),
          rateRepositoryProvider.overrideWithValue(createFakeRateRepository()),
          settingsRepositoryProvider.overrideWithValue(
            MemorySettingsRepository(),
          ),
        ],
        child: _localizedApp(home: const ExpenseEditorPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<CupertinoTextField>(_field('expense-title-field'))
          .placeholder,
      '请输入商户或项目',
    );
    expect(
      tester
          .widget<CupertinoTextField>(
            _field('expense-transaction-amount-field'),
          )
          .placeholder,
      '请输入交易金额',
    );

    await tester.tap(find.text('保存'));
    await tester.pump(const Duration(milliseconds: 200));

    final toast = find.byKey(const Key('expense-validation-toast'));
    final basics = find.byKey(const Key('expense-editor-basics-section'));
    expect(toast, findsOneWidget);
    expect(tester.getSize(toast).width, lessThan(330));
    expect(tester.getRect(toast).top, lessThan(tester.getRect(basics).top));
    expect(find.text('还需填写商户名称和交易金额'), findsOneWidget);
  });

  testWidgets('numeric input shows the shared keyboard accessory', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tripRepositoryProvider.overrideWithValue(MemoryTripRepository()),
          paymentMethodRepositoryProvider.overrideWithValue(
            MemoryPaymentMethodRepository(),
          ),
          rateRepositoryProvider.overrideWithValue(createFakeRateRepository()),
          settingsRepositoryProvider.overrideWithValue(
            MemorySettingsRepository(),
          ),
        ],
        child: _localizedApp(home: const ExpenseEditorPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(_field('expense-transaction-amount-field'));
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pump();

    final accessory = find.byKey(const Key('expense-keyboard-accessory'));
    expect(accessory, findsOneWidget);
    expect(
      find.descendant(of: accessory, matching: find.text('完成')),
      findsOneWidget,
    );

    await tester.tap(find.descendant(of: accessory, matching: find.text('完成')));
    await tester.pump();
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('receipt attachment renders an image without exposing its path', (
    tester,
  ) async {
    final root = Directory.systemTemp.createTempSync(
      'receipt-editor-preview-test-',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final source = File(
      '${Directory.current.path}/assets/branding/launch_mark.png',
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tripRepositoryProvider.overrideWithValue(MemoryTripRepository()),
          paymentMethodRepositoryProvider.overrideWithValue(
            MemoryPaymentMethodRepository(),
          ),
          rateRepositoryProvider.overrideWithValue(createFakeRateRepository()),
          settingsRepositoryProvider.overrideWithValue(
            MemorySettingsRepository(),
          ),
          receiptStorageProvider.overrideWithValue(
            ReceiptStorage(rootDirectory: () async => root),
          ),
        ],
        child: _localizedApp(
          home: ExpenseEditorPage(
            receiptImagePicker: _ReceiptPicker(source.path),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('expense-receipt-picker')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.byKey(const Key('expense-receipt-picker')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('expense-receipt-picker')));
    await tester.pump();
    for (
      var attempt = 0;
      attempt < 20 &&
          find.byKey(const Key('expense-receipt-thumbnail')).evaluate().isEmpty;
      attempt += 1
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }

    expect(find.byKey(const Key('expense-receipt-thumbnail')), findsOneWidget);
    expect(find.textContaining('receipts/'), findsNothing);
  });
}

Finder _field(String key) => find.byKey(Key(key));

CupertinoApp _localizedApp({required Widget home}) => CupertinoApp(
  locale: const Locale('zh'),
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

CupertinoApp _localizedRouterApp(GoRouter router) => CupertinoApp.router(
  locale: const Locale('zh'),
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  routerConfig: router,
);

final class _ReceiptPicker implements ScannerImagePicker {
  const _ReceiptPicker(this.path);

  final String path;

  @override
  Future<String?> pick(ScannerImageSource source) async => path;
}

final class _CapturingExpenseRepository implements ExpenseRepository {
  final List<ExpenseModel> values = <ExpenseModel>[];
  FeeCalibrationModel? calibration;

  @override
  Future<ExpenseModel?> findById(String id) async =>
      values.where((item) => item.metadata.recordId == id).firstOrNull;

  @override
  Future<List<ExpenseModel>> listActive() async =>
      List<ExpenseModel>.unmodifiable(values);

  @override
  Future<List<ExpenseModel>> listForTrip(String tripId) async =>
      List<ExpenseModel>.unmodifiable(
        values.where((item) => item.tripId == tripId),
      );

  @override
  Future<void> save(ExpenseModel expense) async {
    values.removeWhere(
      (item) => item.metadata.recordId == expense.metadata.recordId,
    );
    values.add(expense);
  }

  @override
  Future<void> saveWithCalibration(
    ExpenseModel expense,
    FeeCalibrationModel calibration,
  ) async {
    await save(expense);
    this.calibration = calibration;
  }

  @override
  Future<void> softDelete(String id, DateTime deletedAtUtc) async {
    values.removeWhere((item) => item.metadata.recordId == id);
  }
}
