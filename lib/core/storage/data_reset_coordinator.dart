import 'package:trip_cost/core/storage/database/app_database.dart';
import 'package:trip_cost/core/storage/files/receipt_storage.dart';
import 'package:uuid/uuid.dart';

abstract interface class SharedSnapshotStore {
  Future<void> clear();
}

final class DataResetConfirmation {
  const DataResetConfirmation._(this.token, this.expiresAt);

  final String token;
  final DateTime expiresAt;
}

final class DataResetCoordinator {
  DataResetCoordinator({
    required AppDatabase database,
    required ReceiptStorage receiptStorage,
    required SharedSnapshotStore sharedSnapshotStore,
    DateTime Function()? clock,
    Uuid? uuid,
  }) : _database = database,
       _receiptStorage = receiptStorage,
       _sharedSnapshotStore = sharedSnapshotStore,
       _clock = clock ?? (() => DateTime.now().toUtc()),
       _uuid = uuid ?? const Uuid();

  final AppDatabase _database;
  final ReceiptStorage _receiptStorage;
  final SharedSnapshotStore _sharedSnapshotStore;
  final DateTime Function() _clock;
  final Uuid _uuid;
  String? _pendingToken;
  DateTime? _expiresAt;

  DataResetConfirmation requestConfirmation({
    Duration validity = const Duration(minutes: 2),
  }) {
    final now = _clock().toUtc();
    _pendingToken = _uuid.v4();
    _expiresAt = now.add(validity);
    return DataResetConfirmation._(_pendingToken!, _expiresAt!);
  }

  Future<void> clearAllData({required String confirmationToken}) async {
    final now = _clock().toUtc();
    if (_pendingToken == null ||
        _pendingToken != confirmationToken ||
        _expiresAt == null ||
        now.isAfter(_expiresAt!)) {
      throw const DataResetConfirmationException();
    }
    _pendingToken = null;
    _expiresAt = null;

    // Clear the shared summary first so a partial failure can never leave a
    // Widget exposing stale accounting data after the local database is gone.
    await _sharedSnapshotStore.clear();
    final receiptReport = await _receiptStorage.clearAll();
    if (!receiptReport.succeeded) {
      throw StateError('Could not remove all local receipt images.');
    }
    await _database.coreDao.clearAllData();
  }

  Future<ReceiptClearReport> clearReceiptImages() async {
    final report = await _receiptStorage.clearAll();
    if (report.succeeded) {
      await _database.coreDao.clearReceiptReferences();
    }
    return report;
  }
}

final class DataResetConfirmationException implements Exception {
  const DataResetConfirmationException();

  @override
  String toString() => 'DataResetConfirmationException';
}
