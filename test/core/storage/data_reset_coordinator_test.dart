import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/core/storage/data_reset_coordinator.dart';
import 'package:trip_cost/core/storage/database/app_database.dart';
import 'package:trip_cost/core/storage/database/database_bootstrapper.dart';
import 'package:trip_cost/core/storage/files/receipt_storage.dart';

void main() {
  late Directory root;
  late AppDatabase database;
  late ReceiptStorage receiptStorage;
  late _FakeSharedSnapshotStore sharedSnapshotStore;
  final now = DateTime.utc(2026, 8, 17, 8);

  setUp(() async {
    root = await Directory.systemTemp.createTemp('m2-reset-');
    database = AppDatabase.inMemory();
    receiptStorage = ReceiptStorage(rootDirectory: () async => root);
    sharedSnapshotStore = _FakeSharedSnapshotStore();
    await DatabaseBootstrapper(
      database,
      clock: () => now,
    ).seedCurrencyMetadata();
  });

  tearDown(() async {
    await database.close();
    await root.delete(recursive: true);
  });

  test(
    'clearing receipts keeps expense rows and removes their references',
    () async {
      final source = File('${root.path}/receipt.png');
      await source.writeAsBytes(<int>[1]);
      final reference = await receiptStorage.importImage(source);
      await database.coreDao.upsertExpense(
        ExpensesCompanion.insert(
          id: 'expense-1',
          updatedAt: now,
          title: 'Dinner',
          category: 'food',
          transactionAmount: '100',
          transactionCurrency: 'JPY',
          referenceAmount: '5',
          homeCurrency: 'CNY',
          estimatedFinalAmount: '5',
          paymentRuleSnapshotJson: '{}',
          rateSnapshotJson: '{}',
          taxAmount: '0',
          tipAmount: '0',
          discountAmount: '0',
          occurredAt: now,
          receiptLocalPath: Value<String?>(reference),
          status: 'estimated',
          createdAt: now,
        ),
      );
      final coordinator = DataResetCoordinator(
        database: database,
        receiptStorage: receiptStorage,
        sharedSnapshotStore: sharedSnapshotStore,
        clock: () => now,
      );

      final report = await coordinator.clearReceiptImages();

      expect(report.succeeded, isTrue);
      final expenses = await database.coreDao.activeExpenses();
      expect(expenses, hasLength(1));
      expect(expenses.single.receiptLocalPath, isNull);
    },
  );

  test(
    'full reset requires a valid confirmation and clears shared snapshot',
    () async {
      final coordinator = DataResetCoordinator(
        database: database,
        receiptStorage: receiptStorage,
        sharedSnapshotStore: sharedSnapshotStore,
        clock: () => now,
      );

      await expectLater(
        coordinator.clearAllData(confirmationToken: 'not-confirmed'),
        throwsA(isA<DataResetConfirmationException>()),
      );
      final confirmation = coordinator.requestConfirmation();
      await coordinator.clearAllData(confirmationToken: confirmation.token);

      final currencies = await database.select(database.currencies).get();
      expect(currencies, isEmpty);
      expect(sharedSnapshotStore.wasCleared, isTrue);
    },
  );

  test('shared snapshot failure leaves the database intact', () async {
    final coordinator = DataResetCoordinator(
      database: database,
      receiptStorage: receiptStorage,
      sharedSnapshotStore: _ThrowingSharedSnapshotStore(),
      clock: () => now,
    );
    final confirmation = coordinator.requestConfirmation();

    await expectLater(
      coordinator.clearAllData(confirmationToken: confirmation.token),
      throwsStateError,
    );

    final currencies = await database.select(database.currencies).get();
    expect(currencies, isNotEmpty);
  });
}

final class _FakeSharedSnapshotStore implements SharedSnapshotStore {
  bool wasCleared = false;

  @override
  Future<void> clear() async {
    wasCleared = true;
  }
}

final class _ThrowingSharedSnapshotStore implements SharedSnapshotStore {
  @override
  Future<void> clear() => throw StateError('Snapshot unavailable.');
}
