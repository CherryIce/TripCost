import 'dart:convert';
import 'dart:io';

import 'package:trip_cost/core/storage/database/app_database.dart';

final class BackupService {
  BackupService(this._database, {DateTime Function()? clock})
    : _clock = clock ?? (() => DateTime.now().toUtc());

  static const int formatVersion = 1;
  static const int maximumBackupBytes = 50 * 1024 * 1024;

  final AppDatabase _database;
  final DateTime Function() _clock;

  Future<void> exportTo(File destination) async {
    final envelope = <String, Object?>{
      'format': 'local-accounting-backup',
      'formatVersion': formatVersion,
      'databaseSchemaVersion': _database.schemaVersion,
      'createdAt': _clock().toUtc().toIso8601String(),
      'tables': await _database.exportRawData(),
    };
    await destination.writeAsString(jsonEncode(envelope), flush: true);
  }

  Future<void> restoreFrom(File source) async {
    final length = await source.length();
    if (length > maximumBackupBytes) {
      throw const BackupValidationException('Backup file is too large.');
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(await source.readAsString());
    } on FormatException {
      throw const BackupValidationException('Backup is not valid JSON.');
    }
    final tables = _validateEnvelope(decoded);
    await _database.replaceRawData(tables);
  }

  Map<String, List<Map<String, Object?>>> _validateEnvelope(Object? value) {
    if (value is! Map<String, Object?> ||
        value['format'] != 'local-accounting-backup' ||
        value['formatVersion'] != formatVersion ||
        value['databaseSchemaVersion'] != _database.schemaVersion) {
      throw const BackupValidationException(
        'Backup format or schema version is unsupported.',
      );
    }
    final createdAt = value['createdAt'];
    if (createdAt is! String || DateTime.tryParse(createdAt)?.isUtc != true) {
      throw const BackupValidationException('Backup timestamp is invalid.');
    }
    final rawTables = value['tables'];
    if (rawTables is! Map<String, Object?>) {
      throw const BackupValidationException('Backup tables are missing.');
    }

    final result = <String, List<Map<String, Object?>>>{};
    for (final entry in rawTables.entries) {
      final rows = entry.value;
      if (rows is! List<Object?>) {
        throw const BackupValidationException('Backup table rows are invalid.');
      }
      result[entry.key] = <Map<String, Object?>>[
        for (final row in rows) _validateRow(row),
      ];
    }
    return result;
  }

  Map<String, Object?> _validateRow(Object? value) {
    if (value is! Map<String, Object?>) {
      throw const BackupValidationException('Backup row is invalid.');
    }
    for (final field in value.values) {
      if (field != null && field is! String && field is! int) {
        throw const BackupValidationException(
          'Backup row contains an unsupported value.',
        );
      }
    }
    return Map<String, Object?>.from(value);
  }
}

final class BackupValidationException implements Exception {
  const BackupValidationException(this.message);

  final String message;

  @override
  String toString() => 'BackupValidationException: $message';
}
