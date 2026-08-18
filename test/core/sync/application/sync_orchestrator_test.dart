import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/core/storage/database/app_database.dart';
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
}

final class _FakeGateway implements CloudSyncGateway {
  _FakeGateway({
    this.account = SyncAccountState.available,
    this.expireFirstCursor = false,
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
      acceptedKeys: <String>{for (final record in records) record.key},
    );
  }
}
