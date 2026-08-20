import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/core/domain/core_models.dart';
import 'package:trip_cost/core/storage/database/app_database.dart';
import 'package:trip_cost/core/storage/database/database_bootstrapper.dart';
import 'package:trip_cost/core/storage/settings/drift_settings_repository.dart';

import '../../../generated_migrations/schema.dart';
import '../../../generated_migrations/schema_v1.dart' as v1;
import '../../../generated_migrations/schema_v2.dart' as v2;
import '../../../generated_migrations/schema_v3.dart' as v3;
import '../../../generated_migrations/schema_v4.dart' as v4;
import '../../../generated_migrations/schema_v5.dart' as v5;
import '../../../generated_migrations/schema_v6.dart' as v6;

void main() {
  late AppDatabase database;
  final now = DateTime.utc(2026, 8, 17, 8);

  setUp(() async {
    database = AppDatabase.inMemory();
    await DatabaseBootstrapper(
      database,
      clock: () => now,
    ).seedCurrencyMetadata();
  });

  tearDown(() => database.close());

  test('schema v6 matches the exported migration baseline', () async {
    await database.close();
    final verifier = SchemaVerifier(GeneratedHelper());
    final connection = await verifier.startAt(6);
    final schemaDatabase = AppDatabase(connection);
    addTearDown(schemaDatabase.close);

    await verifier.migrateAndValidate(schemaDatabase, 6);
  });

  test('migrates v1 payment methods with a nullable cash rate', () async {
    await database.close();
    final verifier = SchemaVerifier(GeneratedHelper());
    final schema = await verifier.schemaAt(1);
    addTearDown(schema.close);
    final oldDatabase = v1.DatabaseAtV1(schema.newConnection());
    await oldDatabase.customStatement(
      'INSERT INTO currencies '
      '(code, name, symbol, minor_units, updated_at) '
      'VALUES (?, ?, ?, ?, ?)',
      <Object?>[
        'CNY',
        'Chinese Yuan',
        '¥',
        2,
        now.millisecondsSinceEpoch ~/ 1000,
      ],
    );
    await oldDatabase.customStatement(
      'INSERT INTO payment_methods '
      '(id, updated_at, name, type, network, billing_currency, '
      'foreign_fee_percent, cross_border_fee_percent, '
      'rate_markup_percent, fixed_fee, cashback_percent, '
      'supported_txn_types_json, created_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      <Object?>[
        'legacy-card',
        now.millisecondsSinceEpoch ~/ 1000,
        'Legacy card',
        'creditCard',
        'unknown',
        'CNY',
        '1',
        '0',
        '0',
        '0',
        '0',
        '["purchase"]',
        now.millisecondsSinceEpoch ~/ 1000,
      ],
    );
    await oldDatabase.close();

    final migrationDatabase = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(migrationDatabase, 6);
    await migrationDatabase.close();

    final checkDatabase = v6.DatabaseAtV6(schema.newConnection());
    final row = await checkDatabase
        .customSelect(
          'SELECT id, cash_exchange_rate FROM payment_methods '
          'WHERE id = ?',
          variables: <Variable<Object>>[Variable<String>('legacy-card')],
        )
        .getSingle();
    expect(row.data['id'], 'legacy-card');
    expect(row.data['cash_exchange_rate'], null);
    await checkDatabase.close();
  });

  test('migrates v2 expenses with purchase adjustment defaults', () async {
    await database.close();
    final verifier = SchemaVerifier(GeneratedHelper());
    final schema = await verifier.schemaAt(2);
    addTearDown(schema.close);
    final oldDatabase = v2.DatabaseAtV2(schema.newConnection());
    await oldDatabase.customStatement(
      'INSERT INTO currencies '
      '(code, name, symbol, minor_units, updated_at) '
      'VALUES (?, ?, ?, ?, ?)',
      <Object?>[
        'CNY',
        'Chinese Yuan',
        '¥',
        2,
        now.millisecondsSinceEpoch ~/ 1000,
      ],
    );
    await oldDatabase.customStatement(
      'INSERT INTO expenses '
      '(id, updated_at, title, category, transaction_amount, '
      'transaction_currency, reference_amount, home_currency, '
      'estimated_final_amount, payment_rule_snapshot_json, '
      'rate_snapshot_json, tax_amount, tip_amount, discount_amount, '
      'occurred_at, status, created_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      <Object?>[
        'legacy-expense',
        now.millisecondsSinceEpoch ~/ 1000,
        'Lunch',
        'food',
        '10',
        'CNY',
        '10',
        'CNY',
        '10',
        '{}',
        '{}',
        '0',
        '0',
        '0',
        now.millisecondsSinceEpoch ~/ 1000,
        'estimated',
        now.millisecondsSinceEpoch ~/ 1000,
      ],
    );
    await oldDatabase.close();

    final migrationDatabase = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(migrationDatabase, 6);
    final row = await migrationDatabase
        .customSelect(
          'SELECT entry_type, related_expense_id FROM expenses WHERE id = ?',
          variables: <Variable<Object>>[Variable<String>('legacy-expense')],
        )
        .getSingle();
    expect(row.data['entry_type'], 'purchase');
    expect(row.data['related_expense_id'], null);
    await migrationDatabase.close();
  });

  test('migrates v3 sync metadata and creates M7 state tables', () async {
    await database.close();
    final verifier = SchemaVerifier(GeneratedHelper());
    final schema = await verifier.schemaAt(3);
    addTearDown(schema.close);
    final oldDatabase = v3.DatabaseAtV3(schema.newConnection());
    await oldDatabase.customStatement(
      'INSERT INTO sync_metadata_entries '
      '(entity_type, record_id, sync_version, sync_state, updated_at) '
      'VALUES (?, ?, ?, ?, ?)',
      <Object?>[
        'trip',
        'trip-v3',
        2,
        'pending',
        now.millisecondsSinceEpoch ~/ 1000,
      ],
    );
    await oldDatabase.close();

    final migrationDatabase = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(migrationDatabase, 6);
    await migrationDatabase.close();

    final checkDatabase = v6.DatabaseAtV6(schema.newConnection());
    final metadata = await checkDatabase
        .customSelect(
          'SELECT record_id, device_id, change_id, '
          'last_synced_payload_json FROM sync_metadata_entries',
        )
        .getSingle();
    expect(metadata.data['record_id'], 'trip-v3');
    expect(metadata.data['device_id'], equals(null));
    expect(metadata.data['change_id'], equals(null));
    expect(metadata.data['last_synced_payload_json'], equals(null));
    final tables = await checkDatabase
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name IN ('sync_runtime_entries', 'sync_conflict_entries')",
        )
        .get();
    expect(tables, hasLength(2));
    await checkDatabase.close();
  });

  test('migrates v4 settings with a fallback transaction currency', () async {
    await database.close();
    final verifier = SchemaVerifier(GeneratedHelper());
    final schema = await verifier.schemaAt(4);
    addTearDown(schema.close);
    final oldDatabase = v4.DatabaseAtV4(schema.newConnection());
    for (final currency in <String>['CNY', 'USD']) {
      await oldDatabase.customStatement(
        'INSERT INTO currencies '
        '(code, name, symbol, minor_units, updated_at) '
        'VALUES (?, ?, ?, ?, ?)',
        <Object?>[
          currency,
          currency,
          currency,
          2,
          now.millisecondsSinceEpoch ~/ 1000,
        ],
      );
    }
    await oldDatabase.customStatement(
      'INSERT INTO user_settings_records '
      '(id, updated_at, default_currency, favorite_currencies_json, '
      'language_mode, refresh_interval_minutes) '
      'VALUES (?, ?, ?, ?, ?, ?)',
      <Object?>[
        DriftSettingsRepository.settingsRecordId,
        now.millisecondsSinceEpoch ~/ 1000,
        'CNY',
        '["USD"]',
        AppLanguageMode.system.name,
        360,
      ],
    );
    await oldDatabase.close();

    final migrationDatabase = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(migrationDatabase, 6);
    final restored = await DriftSettingsRepository(migrationDatabase).load();
    expect(restored!.defaultCurrency.code, 'CNY');
    expect(restored.lastTransactionCurrency.code, 'USD');
    await migrationDatabase.close();
  });

  test('migrates v5 trips with an empty route-stop payload', () async {
    await database.close();
    final verifier = SchemaVerifier(GeneratedHelper());
    final schema = await verifier.schemaAt(5);
    addTearDown(schema.close);
    final oldDatabase = v5.DatabaseAtV5(schema.newConnection());
    for (final currency in <String>['CNY', 'JPY']) {
      await oldDatabase.customStatement(
        'INSERT INTO currencies '
        '(code, name, symbol, minor_units, updated_at) '
        'VALUES (?, ?, ?, ?, ?)',
        <Object?>[
          currency,
          currency,
          currency,
          2,
          now.millisecondsSinceEpoch ~/ 1000,
        ],
      );
    }
    await oldDatabase.customStatement(
      'INSERT INTO trips '
      '(id, updated_at, name, destination_codes_json, start_date, end_date, '
      'home_currency, local_currencies_json, participant_count, status, '
      'created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      <Object?>[
        'legacy-trip',
        now.millisecondsSinceEpoch ~/ 1000,
        'Tokyo',
        '["JP"]',
        now.millisecondsSinceEpoch ~/ 1000,
        now.add(const Duration(days: 2)).millisecondsSinceEpoch ~/ 1000,
        'CNY',
        '["JPY"]',
        1,
        'active',
        now.millisecondsSinceEpoch ~/ 1000,
      ],
    );
    await oldDatabase.close();

    final migrationDatabase = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(migrationDatabase, 6);
    final row = await migrationDatabase
        .customSelect(
          'SELECT route_stops_json FROM trips WHERE id = ?',
          variables: <Variable<Object>>[Variable<String>('legacy-trip')],
        )
        .getSingle();
    expect(row.data['route_stops_json'], '[]');
    await migrationDatabase.close();
  });

  test('foreign keys are enabled and reject unknown currencies', () async {
    final pragma = await database
        .customSelect('PRAGMA foreign_keys')
        .getSingle();
    expect(pragma.data.values.single, 1);

    expect(
      () => database.coreDao.upsertPaymentMethod(
        PaymentMethodsCompanion.insert(
          id: 'payment-unknown-currency',
          updatedAt: now,
          name: 'Cash',
          type: 'cash',
          network: 'unknown',
          billingCurrency: 'ZZZ',
          foreignFeePercent: '0',
          crossBorderFeePercent: '0',
          rateMarkupPercent: '0',
          fixedFee: '0',
          cashbackPercent: '0',
          supportedTxnTypesJson: '["purchase"]',
          createdAt: now,
        ),
      ),
      throwsA(anything),
    );
  });

  test(
    'soft-deleting current rules does not alter expense snapshots',
    () async {
      const originalRule = <String, Object?>{
        'paymentMethodId': 'payment-1',
        'foreignFeePercent': '1.5',
        'fixedFee': '0',
      };
      const rateSnapshot = <String, Object?>{
        'id': 'rate-1',
        'baseCurrency': 'JPY',
        'quoteCurrency': 'CNY',
        'rate': '0.047841',
        'sourceType': 'market',
      };
      await database.coreDao.upsertPaymentMethod(
        PaymentMethodsCompanion.insert(
          id: 'payment-1',
          updatedAt: now,
          name: '1.5% card',
          type: 'creditCard',
          network: 'visa',
          billingCurrency: 'CNY',
          foreignFeePercent: '1.5',
          crossBorderFeePercent: '0',
          rateMarkupPercent: '0',
          fixedFee: '0',
          cashbackPercent: '0',
          supportedTxnTypesJson: '["purchase"]',
          createdAt: now,
        ),
      );
      await database.coreDao.upsertExpense(
        ExpensesCompanion.insert(
          id: 'expense-1',
          updatedAt: now,
          title: 'Lunch',
          category: 'food',
          transactionAmount: '12800',
          transactionCurrency: 'JPY',
          referenceAmount: '612.3648',
          homeCurrency: 'CNY',
          estimatedFinalAmount: '621.550272',
          paymentMethodId: const Value<String?>('payment-1'),
          paymentRuleSnapshotJson: jsonEncode(originalRule),
          rateSnapshotJson: jsonEncode(rateSnapshot),
          taxAmount: '0',
          tipAmount: '0',
          discountAmount: '0',
          occurredAt: now,
          status: 'estimated',
          createdAt: now,
        ),
      );

      await database.coreDao.upsertPaymentMethod(
        PaymentMethodsCompanion.insert(
          id: 'payment-1',
          updatedAt: now.add(const Duration(minutes: 1)),
          deletedAt: Value<DateTime?>(now.add(const Duration(minutes: 1))),
          name: 'Changed card',
          type: 'creditCard',
          network: 'visa',
          billingCurrency: 'CNY',
          foreignFeePercent: '9.9',
          crossBorderFeePercent: '0',
          rateMarkupPercent: '0',
          fixedFee: '100',
          cashbackPercent: '0',
          supportedTxnTypesJson: '["purchase"]',
          createdAt: now,
        ),
      );

      final expenses = await database.coreDao.activeExpenses();
      expect(expenses, hasLength(1));
      expect(jsonDecode(expenses.single.paymentRuleSnapshotJson), originalRule);
      expect(jsonDecode(expenses.single.rateSnapshotJson), rateSnapshot);
      expect(expenses.single.estimatedFinalAmount, '621.550272');
    },
  );
}
