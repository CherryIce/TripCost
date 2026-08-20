import 'package:drift/drift.dart';

mixin SyncableColumns on Table {
  TextColumn get id => text()();

  IntColumn get syncVersion => integer().withDefault(const Constant(1))();

  DateTimeColumn get updatedAt => dateTime()();

  DateTimeColumn get deletedAt => dateTime().nullable()();
}

class Currencies extends Table {
  TextColumn get code => text().withLength(min: 3, max: 3)();

  TextColumn get numericCode => text().nullable()();

  TextColumn get name => text()();

  TextColumn get symbol => text()();

  IntColumn get minorUnits => integer()();

  TextColumn get countryCodesJson => text().withDefault(const Constant('[]'))();

  DateTimeColumn get updatedAt => dateTime()();

  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{code};
}

class RateSnapshots extends Table with SyncableColumns {
  @ReferenceName('baseCurrencyRateSnapshots')
  TextColumn get baseCurrency =>
      text().references(Currencies, #code, onDelete: KeyAction.restrict)();

  @ReferenceName('quoteCurrencyRateSnapshots')
  TextColumn get quoteCurrency =>
      text().references(Currencies, #code, onDelete: KeyAction.restrict)();

  TextColumn get rate => text()();

  TextColumn get sourceType => text()();

  TextColumn get sourceName => text()();

  DateTimeColumn get sourceTimestamp => dateTime()();

  DateTimeColumn get fetchedAt => dateTime()();

  BoolColumn get isCached => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class PaymentMethods extends Table with SyncableColumns {
  TextColumn get name => text()();

  TextColumn get type => text()();

  TextColumn get network => text()();

  TextColumn get billingCurrency =>
      text().references(Currencies, #code, onDelete: KeyAction.restrict)();

  TextColumn get foreignFeePercent => text()();

  TextColumn get crossBorderFeePercent => text()();

  TextColumn get rateMarkupPercent => text()();

  TextColumn get fixedFee => text()();

  TextColumn get cashbackPercent => text()();

  TextColumn get minimumFee => text().nullable()();

  TextColumn get maximumFee => text().nullable()();

  TextColumn get cashExchangeRate => text().nullable()();

  TextColumn get supportedTxnTypesJson => text()();

  TextColumn get sourceUrl => text().nullable()();

  DateTimeColumn get effectiveFrom => dateTime().nullable()();

  DateTimeColumn get lastVerifiedAt => dateTime().nullable()();

  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class Trips extends Table with SyncableColumns {
  TextColumn get name => text()();

  TextColumn get destinationCodesJson => text()();

  TextColumn get routeStopsJson => text().withDefault(const Constant('[]'))();

  DateTimeColumn get startDate => dateTime()();

  DateTimeColumn get endDate => dateTime()();

  TextColumn get homeCurrency =>
      text().references(Currencies, #code, onDelete: KeyAction.restrict)();

  TextColumn get localCurrenciesJson => text()();

  TextColumn get totalBudget => text().nullable()();

  IntColumn get participantCount => integer().withDefault(const Constant(1))();

  TextColumn get defaultPaymentMethodId => text().nullable().references(
    PaymentMethods,
    #id,
    onDelete: KeyAction.setNull,
  )();

  DateTimeColumn get offlinePackUpdatedAt => dateTime().nullable()();

  TextColumn get status => text()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class Expenses extends Table with SyncableColumns {
  TextColumn get tripId =>
      text().nullable().references(Trips, #id, onDelete: KeyAction.setNull)();

  TextColumn get title => text()();

  TextColumn get category => text()();

  TextColumn get transactionAmount => text()();

  @ReferenceName('transactionCurrencyExpenses')
  TextColumn get transactionCurrency =>
      text().references(Currencies, #code, onDelete: KeyAction.restrict)();

  TextColumn get referenceAmount => text()();

  @ReferenceName('homeCurrencyExpenses')
  TextColumn get homeCurrency =>
      text().references(Currencies, #code, onDelete: KeyAction.restrict)();

  TextColumn get estimatedFinalAmount => text()();

  TextColumn get actualFinalAmount => text().nullable()();

  TextColumn get paymentMethodId => text().nullable().references(
    PaymentMethods,
    #id,
    onDelete: KeyAction.setNull,
  )();

  TextColumn get paymentRuleSnapshotJson => text()();

  TextColumn get rateSnapshotId => text().nullable().references(
    RateSnapshots,
    #id,
    onDelete: KeyAction.setNull,
  )();

  TextColumn get rateSnapshotJson => text()();

  TextColumn get taxAmount => text()();

  TextColumn get tipAmount => text()();

  TextColumn get discountAmount => text()();

  IntColumn get participantCount => integer().withDefault(const Constant(1))();

  DateTimeColumn get occurredAt => dateTime()();

  TextColumn get receiptLocalPath => text().nullable()();

  TextColumn get notes => text().nullable()();

  BoolColumn get budgetIncluded =>
      boolean().withDefault(const Constant(true))();

  TextColumn get status => text()();

  TextColumn get entryType => text().withDefault(const Constant('purchase'))();

  TextColumn get relatedExpenseId => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class FeeCalibrations extends Table with SyncableColumns {
  TextColumn get paymentMethodId =>
      text().references(PaymentMethods, #id, onDelete: KeyAction.restrict)();

  TextColumn get expenseId =>
      text().references(Expenses, #id, onDelete: KeyAction.restrict)();

  TextColumn get referenceAmount => text()();

  TextColumn get actualFinalAmount => text()();

  TextColumn get effectiveMarkupPercent => text()();

  DateTimeColumn get calculatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class UserSettingsRecords extends Table with SyncableColumns {
  TextColumn get defaultCurrency =>
      text().references(Currencies, #code, onDelete: KeyAction.restrict)();

  @ReferenceName('lastTransactionCurrencySettings')
  TextColumn get lastTransactionCurrency => text().nullable().references(
    Currencies,
    #code,
    onDelete: KeyAction.restrict,
  )();

  TextColumn get favoriteCurrenciesJson => text()();

  TextColumn get languageMode => text()();

  IntColumn get refreshIntervalMinutes => integer()();

  BoolColumn get wifiOnlyRefresh =>
      boolean().withDefault(const Constant(false))();

  BoolColumn get syncEnabled => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class SyncMetadataEntries extends Table {
  TextColumn get entityType => text()();

  TextColumn get recordId => text()();

  IntColumn get syncVersion => integer()();

  TextColumn get syncState => text()();

  DateTimeColumn get updatedAt => dateTime()();

  DateTimeColumn get deletedAt => dateTime().nullable()();

  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  TextColumn get lastErrorCode => text().nullable()();

  TextColumn get deviceId => text().nullable()();

  TextColumn get changeId => text().nullable()();

  TextColumn get lastSyncedPayloadJson => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{entityType, recordId};
}

class SyncRuntimeEntries extends Table {
  TextColumn get id => text()();

  TextColumn get cursor => text().nullable()();

  TextColumn get deviceId => text()();

  TextColumn get accountState => text()();

  TextColumn get phase => text()();

  IntColumn get failureCount => integer().withDefault(const Constant(0))();

  DateTimeColumn get lastAttemptAt => dateTime().nullable()();

  DateTimeColumn get lastSuccessAt => dateTime().nullable()();

  DateTimeColumn get nextRetryAt => dateTime().nullable()();

  TextColumn get lastErrorCode => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class SyncConflictEntries extends Table {
  TextColumn get id => text()();

  TextColumn get entityType => text()();

  TextColumn get recordId => text()();

  TextColumn get fieldName => text()();

  TextColumn get localPayloadJson => text()();

  TextColumn get remotePayloadJson => text()();

  DateTimeColumn get detectedAt => dateTime()();

  DateTimeColumn get resolvedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}
