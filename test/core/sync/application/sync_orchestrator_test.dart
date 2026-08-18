import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/core/storage/database/app_database.dart';
import 'package:trip_cost/core/storage/database/database_bootstrapper.dart';
import 'package:trip_cost/core/sync/application/sync_orchestrator.dart';
import 'package:trip_cost/core/sync/data/drift_sync_store.dart';
import 'package:trip_cost/core/sync/domain/sync_models.dart';

void main() {
  late AppDatabase database;
  final now = DateTime.utc(2026, 8, 17, 8);

  setUp(() {
    database = AppDatabase.inMemory();
  });

  tearDown(() => database.close());

  test('pulls every page and commits the final cursor', () async {
    final gateway = _FakeGateway(
      pulls: const <CloudPullResult>[
        CloudPullResult(
          records: <CloudSyncRecord>[],
          cursor: 'c1',
          hasMore: true,
        ),
        CloudPullResult(
          records: <CloudSyncRecord>[],
          cursor: 'c2',
          hasMore: false,
        ),
      ],
    );
    final store = DriftSyncStore(database, clock: () => now);
    final orchestrator = SyncOrchestrator(
      gateway: gateway,
      store: store,
      clock: () => now,
    );
    addTearDown(orchestrator.dispose);
    final completion = orchestrator.completions.first;
    final status = await orchestrator.synchronize(force: true);

    expect(status.phase, SyncPhase.succeeded);
    expect(status.lastSuccessAt, now);
    expect(await store.cursor(), 'c2');
    expect(gateway.pullCursors, <String?>[null, 'c1']);
    expect((await completion).pulledRecordCount, 0);
  });

  test('iCloud account failure is structured and schedules retry', () async {
    final store = DriftSyncStore(database, clock: () => now);
    final orchestrator = SyncOrchestrator(
      gateway: _FakeGateway(account: SyncAccountState.noAccount),
      store: store,
      clock: () => now,
    );
    addTearDown(orchestrator.dispose);
    final status = await orchestrator.synchronize(force: true);

    expect(status.phase, SyncPhase.failed);
    expect(status.lastErrorCode, 'icloud-noAccount');
    expect(status.nextRetryAt, now.add(const Duration(minutes: 2)));
  });

  test('expired cursor is cleared once before a full pull', () async {
    final store = DriftSyncStore(database, clock: () => now);
    await store.applyPullBatch(const <CloudSyncRecord>[], 'expired');
    final gateway = _FakeGateway(expireFirstCursor: true);

    final orchestrator = SyncOrchestrator(
      gateway: gateway,
      store: store,
      clock: () => now,
    );
    addTearDown(orchestrator.dispose);
    final status = await orchestrator.synchronize(force: true);

    expect(status.phase, SyncPhase.succeeded);
    expect(gateway.pullCursors, <String?>['expired', null]);
    expect(await store.cursor(), isNull);
  });

  test('partial push is a failure and does not advance success time', () async {
    final store = DriftSyncStore(database, clock: () => now);
    final previousSuccess = now.subtract(const Duration(days: 1));
    await store.updateRuntime(
      accountState: SyncAccountState.available,
      phase: SyncPhase.succeeded,
      lastSuccessAt: previousSuccess,
    );
    await DatabaseBootstrapper(
      database,
      clock: () => now,
    ).seedCurrencyMetadata();
    await _insertTrip(database, 'trip-1', now);
    await _insertTrip(database, 'trip-2', now);
    final gateway = _FakeGateway(acceptOnlyFirst: true);
    final orchestrator = SyncOrchestrator(
      gateway: gateway,
      store: store,
      clock: () => now,
    );
    addTearDown(orchestrator.dispose);

    final status = await orchestrator.synchronize(force: true);

    expect(status.phase, SyncPhase.failed);
    expect(status.lastErrorCode, 'partial-push-result');
    expect(status.lastSuccessAt, previousSuccess);
    expect(gateway.pullCursors, isEmpty);
    expect(await store.pendingRecords(), hasLength(1));
  });
}

Future<void> _insertTrip(AppDatabase database, String id, DateTime updatedAt) {
  return database.coreDao.upsertTrip(
    TripsCompanion.insert(
      id: id,
      updatedAt: updatedAt,
      name: id,
      destinationCodesJson: '["JP"]',
      startDate: updatedAt,
      endDate: updatedAt.add(const Duration(days: 1)),
      homeCurrency: 'CNY',
      localCurrenciesJson: '["JPY"]',
      status: 'active',
      createdAt: updatedAt,
      deletedAt: const Value<DateTime?>.absent(),
    ),
  );
}

final class _FakeGateway implements CloudSyncGateway {
  _FakeGateway({
    this.account = SyncAccountState.available,
    this.expireFirstCursor = false,
    this.acceptOnlyFirst = false,
    this.pulls = const <CloudPullResult>[
      CloudPullResult(
        records: <CloudSyncRecord>[],
        cursor: null,
        hasMore: false,
      ),
    ],
  });

  final SyncAccountState account;
  final bool expireFirstCursor;
  final bool acceptOnlyFirst;
  final List<CloudPullResult> pulls;
  final List<String?> pullCursors = <String?>[];
  var _pullIndex = 0;

  @override
  Future<SyncAccountState> accountStatus() async => account;

  @override
  Future<CloudPullResult> pullChanges(String? cursor) async {
    pullCursors.add(cursor);
    if (expireFirstCursor && pullCursors.length == 1 && cursor != null) {
      throw const SyncFailure('cloud-cursor-expired');
    }
    return pulls[_pullIndex++];
  }

  @override
  Future<CloudPushResult> pushChanges(List<CloudSyncRecord> records) async {
    return CloudPushResult(
      acceptedKeys: acceptOnlyFirst
          ? <String>{records.first.key}
          : <String>{for (final record in records) record.key},
    );
  }
}
