import 'package:drift/drift.dart';
import 'package:trip_cost/core/storage/database/app_database.dart';
import 'package:trip_cost/core/storage/database/tables.dart';

part 'core_dao.g.dart';

@DriftAccessor(
  tables: <Type>[
    Currencies,
    RateSnapshots,
    PaymentMethods,
    Trips,
    Expenses,
    FeeCalibrations,
    UserSettingsRecords,
    SyncMetadataEntries,
    SyncRuntimeEntries,
    SyncConflictEntries,
  ],
)
final class CoreDao extends DatabaseAccessor<AppDatabase> with _$CoreDaoMixin {
  CoreDao(super.attachedDatabase);

  Future<void> upsertCurrency(CurrenciesCompanion value) {
    return into(currencies).insertOnConflictUpdate(value);
  }

  Future<List<Currency>> activeCurrencies() {
    return (select(currencies)
          ..where((table) => table.deletedAt.isNull())
          ..orderBy(<OrderingTerm Function($CurrenciesTable)>[
            (table) => OrderingTerm.asc(table.code),
          ]))
        .get();
  }

  Future<int> softDeleteCurrenciesNotIn(
    Iterable<String> currencyCodes,
    DateTime deletedAt,
  ) {
    final codes = currencyCodes.toSet();
    final query = update(currencies)
      ..where((table) => table.deletedAt.isNull() & table.code.isNotIn(codes));
    return query.write(
      CurrenciesCompanion(
        deletedAt: Value<DateTime?>(deletedAt),
        updatedAt: Value<DateTime>(deletedAt),
      ),
    );
  }

  Future<void> upsertRateSnapshot(RateSnapshotsCompanion value) {
    return into(rateSnapshots).insertOnConflictUpdate(value);
  }

  Future<RateSnapshot?> getRateSnapshot(String id) {
    return (select(
      rateSnapshots,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
  }

  Future<RateSnapshot?> latestRateSnapshot({
    required String baseCurrencyCode,
    required String quoteCurrencyCode,
    String? sourceType,
    DateTime? sourceAtOrBefore,
  }) {
    final query = select(rateSnapshots)
      ..where(
        (table) =>
            table.deletedAt.isNull() &
            table.baseCurrency.equals(baseCurrencyCode) &
            table.quoteCurrency.equals(quoteCurrencyCode),
      );
    if (sourceType != null) {
      query.where((table) => table.sourceType.equals(sourceType));
    }
    if (sourceAtOrBefore != null) {
      query.where(
        (table) =>
            table.sourceTimestamp.isSmallerOrEqualValue(sourceAtOrBefore),
      );
    }
    query
      ..orderBy(<OrderingTerm Function($RateSnapshotsTable)>[
        (table) => OrderingTerm.desc(table.sourceTimestamp),
        (table) => OrderingTerm.desc(table.fetchedAt),
      ])
      ..limit(1);
    return query.getSingleOrNull();
  }

  Future<int> softDeleteRateSnapshotsForPairAndSource({
    required String baseCurrencyCode,
    required String quoteCurrencyCode,
    required String sourceType,
    required DateTime deletedAt,
  }) {
    return (update(rateSnapshots)..where(
          (table) =>
              table.deletedAt.isNull() &
              table.baseCurrency.equals(baseCurrencyCode) &
              table.quoteCurrency.equals(quoteCurrencyCode) &
              table.sourceType.equals(sourceType),
        ))
        .write(
          RateSnapshotsCompanion(
            deletedAt: Value<DateTime?>(deletedAt),
            updatedAt: Value<DateTime>(deletedAt),
          ),
        );
  }

  Future<void> upsertPaymentMethod(PaymentMethodsCompanion value) {
    return into(paymentMethods).insertOnConflictUpdate(value);
  }

  Future<List<PaymentMethod>> activePaymentMethods() {
    return (select(paymentMethods)
          ..where((table) => table.deletedAt.isNull())
          ..orderBy(<OrderingTerm Function($PaymentMethodsTable)>[
            (table) => OrderingTerm.asc(table.createdAt),
          ]))
        .get();
  }

  Future<int> softDeletePaymentMethod(String id, DateTime deletedAt) {
    return (update(
      paymentMethods,
    )..where((table) => table.id.equals(id))).write(
      PaymentMethodsCompanion(
        deletedAt: Value<DateTime?>(deletedAt),
        updatedAt: Value<DateTime>(deletedAt),
      ),
    );
  }

  Future<void> upsertTrip(TripsCompanion value) {
    return into(trips).insertOnConflictUpdate(value);
  }

  Future<Trip?> getTrip(String id) {
    return (select(
      trips,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
  }

  Future<List<Trip>> activeTrips() {
    return (select(trips)
          ..where((table) => table.deletedAt.isNull())
          ..orderBy(<OrderingTerm Function($TripsTable)>[
            (table) => OrderingTerm.asc(table.startDate),
            (table) => OrderingTerm.asc(table.createdAt),
          ]))
        .get();
  }

  Future<int> softDeleteTrip(String id, DateTime deletedAt) {
    return (update(trips)..where((table) => table.id.equals(id))).write(
      TripsCompanion(
        deletedAt: Value<DateTime?>(deletedAt),
        updatedAt: Value<DateTime>(deletedAt),
      ),
    );
  }

  Future<void> upsertExpense(ExpensesCompanion value) {
    return into(expenses).insertOnConflictUpdate(value);
  }

  Future<Expense?> getExpense(String id) {
    return (select(
      expenses,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
  }

  Future<void> upsertFeeCalibration(FeeCalibrationsCompanion value) {
    return into(feeCalibrations).insertOnConflictUpdate(value);
  }

  Future<List<FeeCalibration>> calibrationsForPaymentMethod(String id) {
    return (select(feeCalibrations)
          ..where(
            (table) =>
                table.deletedAt.isNull() & table.paymentMethodId.equals(id),
          )
          ..orderBy(<OrderingTerm Function($FeeCalibrationsTable)>[
            (table) => OrderingTerm.desc(table.calculatedAt),
          ]))
        .get();
  }

  Future<void> upsertUserSettings(UserSettingsRecordsCompanion value) {
    return into(userSettingsRecords).insertOnConflictUpdate(value);
  }

  Future<void> upsertSyncMetadata(SyncMetadataEntriesCompanion value) {
    return into(syncMetadataEntries).insertOnConflictUpdate(value);
  }

  Future<UserSettingsRecord?> getUserSettings(String id) {
    return (select(
      userSettingsRecords,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
  }

  Future<List<Expense>> activeExpenses() {
    return (select(expenses)
          ..where((table) => table.deletedAt.isNull())
          ..orderBy(<OrderingTerm Function($ExpensesTable)>[
            (table) => OrderingTerm.desc(table.occurredAt),
            (table) => OrderingTerm.desc(table.createdAt),
          ]))
        .get();
  }

  Future<List<Expense>> activeExpensesForTrip(String tripId) {
    return (select(expenses)
          ..where(
            (table) => table.deletedAt.isNull() & table.tripId.equals(tripId),
          )
          ..orderBy(<OrderingTerm Function($ExpensesTable)>[
            (table) => OrderingTerm.desc(table.occurredAt),
          ]))
        .get();
  }

  Future<int> softDeleteExpense(String id, DateTime deletedAt) {
    return (update(expenses)..where((table) => table.id.equals(id))).write(
      ExpensesCompanion(
        deletedAt: Value<DateTime?>(deletedAt),
        updatedAt: Value<DateTime>(deletedAt),
      ),
    );
  }

  Future<SyncMetadataEntry?> getSyncMetadata(
    String entityType,
    String recordId,
  ) {
    return (select(syncMetadataEntries)..where(
          (table) =>
              table.entityType.equals(entityType) &
              table.recordId.equals(recordId),
        ))
        .getSingleOrNull();
  }

  Future<void> upsertSyncRuntime(SyncRuntimeEntriesCompanion value) {
    return into(syncRuntimeEntries).insertOnConflictUpdate(value);
  }

  Future<SyncRuntimeEntry?> getSyncRuntime(String id) {
    return (select(
      syncRuntimeEntries,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
  }

  Future<void> insertSyncConflict(SyncConflictEntriesCompanion value) {
    return into(syncConflictEntries).insertOnConflictUpdate(value);
  }

  Future<List<SyncConflictEntry>> unresolvedSyncConflicts() {
    return (select(syncConflictEntries)
          ..where((table) => table.resolvedAt.isNull())
          ..orderBy(<OrderingTerm Function($SyncConflictEntriesTable)>[
            (table) => OrderingTerm.desc(table.detectedAt),
          ]))
        .get();
  }

  Future<int> resolveSyncConflict(String id, DateTime resolvedAt) {
    return (update(
      syncConflictEntries,
    )..where((table) => table.id.equals(id))).write(
      SyncConflictEntriesCompanion(resolvedAt: Value<DateTime?>(resolvedAt)),
    );
  }

  Future<int> updateTripOfflinePackTimestamp(
    String tripId,
    DateTime updatedAt,
  ) {
    return (update(trips)..where((table) => table.id.equals(tripId))).write(
      TripsCompanion(offlinePackUpdatedAt: Value<DateTime?>(updatedAt)),
    );
  }

  Future<void> clearReceiptReferences() {
    return update(
      expenses,
    ).write(const ExpensesCompanion(receiptLocalPath: Value<String?>(null)));
  }

  Future<void> clearAllData() async {
    await transaction(() async {
      await delete(syncConflictEntries).go();
      await delete(syncRuntimeEntries).go();
      await delete(syncMetadataEntries).go();
      await delete(feeCalibrations).go();
      await delete(expenses).go();
      await delete(trips).go();
      await delete(paymentMethods).go();
      await delete(rateSnapshots).go();
      await delete(userSettingsRecords).go();
      await delete(currencies).go();
    });
  }
}
