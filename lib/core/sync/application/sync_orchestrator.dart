import 'dart:async';
import 'dart:math' as math;

import 'package:trip_cost/core/sync/data/drift_sync_store.dart';
import 'package:trip_cost/core/sync/domain/sync_models.dart';

final class SyncOrchestrator {
  SyncOrchestrator({
    required CloudSyncGateway gateway,
    required DriftSyncStore store,
    DateTime Function()? clock,
  }) : _gateway = gateway,
       _store = store,
       _clock = clock ?? (() => DateTime.now().toUtc());

  final CloudSyncGateway _gateway;
  final DriftSyncStore _store;
  final DateTime Function() _clock;
  Future<SyncRuntimeStatus>? _activeRun;
  final StreamController<SyncCompletionEvent> _completionController =
      StreamController<SyncCompletionEvent>.broadcast();

  Stream<SyncCompletionEvent> get completions => _completionController.stream;

  Future<void> dispose() => _completionController.close();

  Future<SyncRuntimeStatus> synchronize({bool force = false}) {
    return _activeRun ??= _run(
      force: force,
    ).whenComplete(() => _activeRun = null);
  }

  void requestBackgroundSync() {
    unawaited(synchronize().catchError((Object _) => _store.status()));
  }

  Future<SyncRuntimeStatus> _run({required bool force}) async {
    final now = _clock().toUtc();
    final previous = await _store.status();
    if (!force &&
        previous.nextRetryAt != null &&
        now.isBefore(previous.nextRetryAt!)) {
      await _store.updateRuntime(
        accountState: previous.accountState,
        phase: SyncPhase.waitingRetry,
      );
      return _store.status();
    }
    try {
      final account = await _gateway.accountStatus();
      if (account != SyncAccountState.available) {
        await _store.updateRuntime(
          accountState: account,
          phase: SyncPhase.failed,
          failureCount: previous.failureCount + 1,
          lastAttemptAt: now,
          nextRetryAt: now.add(_retryDelay(previous.failureCount + 1)),
          lastErrorCode: 'icloud-${account.name}',
        );
        return _store.status();
      }
      await _store.updateRuntime(
        accountState: account,
        phase: SyncPhase.pushing,
        lastAttemptAt: now,
      );
      var pulledRecordCount = 0;
      while (true) {
        final pending = await _store.pendingRecords();
        if (pending.isEmpty) break;
        final pushed = await _gateway.pushChanges(pending);
        if (pushed.acceptedKeys.isEmpty) {
          throw const SyncFailure('empty-push-result');
        }
        await _store.markPushed(pending, pushed.acceptedKeys);
        if (pushed.acceptedKeys.length < pending.length) break;
      }

      await _store.updateRuntime(
        accountState: account,
        phase: SyncPhase.pulling,
      );
      var cursor = await _store.cursor();
      var didResetExpiredCursor = false;
      while (true) {
        final CloudPullResult pulled;
        try {
          pulled = await _gateway.pullChanges(cursor);
        } on SyncFailure catch (error) {
          if (error.code != 'cloud-cursor-expired' ||
              cursor == null ||
              didResetExpiredCursor) {
            rethrow;
          }
          await _store.resetCursor();
          cursor = null;
          didResetExpiredCursor = true;
          continue;
        }
        pulledRecordCount += pulled.records.length;
        await _store.applyPullBatch(pulled.records, pulled.cursor);
        cursor = pulled.cursor;
        if (!pulled.hasMore) break;
      }
      final completedAt = _clock().toUtc();
      await _store.updateRuntime(
        accountState: account,
        phase: SyncPhase.succeeded,
        failureCount: 0,
        lastAttemptAt: now,
        lastSuccessAt: completedAt,
        clearRetry: true,
      );
      _completionController.add(
        SyncCompletionEvent(
          completedAt: completedAt,
          pulledRecordCount: pulledRecordCount,
        ),
      );
      return _store.status();
    } on Object catch (error) {
      final count = previous.failureCount + 1;
      await _store.updateRuntime(
        accountState: previous.accountState,
        phase: SyncPhase.failed,
        failureCount: count,
        lastAttemptAt: now,
        nextRetryAt: now.add(_retryDelay(count)),
        lastErrorCode: error is SyncFailure ? error.code : 'unknown',
      );
      return _store.status();
    }
  }

  Duration _retryDelay(int failureCount) {
    final minutes = math.min(360, math.pow(2, failureCount).toInt());
    return Duration(minutes: minutes);
  }
}

final class SyncCompletionEvent {
  const SyncCompletionEvent({
    required this.completedAt,
    required this.pulledRecordCount,
  });

  final DateTime completedAt;
  final int pulledRecordCount;
}
