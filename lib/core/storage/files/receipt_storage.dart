import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

enum ReceiptLookupStatus { available, missing, invalidReference }

final class ReceiptLookup {
  const ReceiptLookup({required this.status, this.file});

  final ReceiptLookupStatus status;
  final File? file;
}

final class ReceiptClearReport {
  const ReceiptClearReport({
    required this.deletedFiles,
    required this.failures,
  });

  final int deletedFiles;
  final List<String> failures;

  bool get succeeded => failures.isEmpty;
}

final class ReceiptStorage {
  ReceiptStorage({Future<Directory> Function()? rootDirectory, Uuid? uuid})
    : _rootDirectory = rootDirectory ?? getApplicationDocumentsDirectory,
      _uuid = uuid ?? const Uuid();

  static const String directoryName = 'receipts';
  static const Set<String> supportedExtensions = <String>{
    '.jpg',
    '.jpeg',
    '.png',
    '.heic',
    '.heif',
  };

  final Future<Directory> Function() _rootDirectory;
  final Uuid _uuid;

  Future<String> importImage(File source) async {
    if (!await source.exists()) {
      throw FileSystemException('Receipt source does not exist.', source.path);
    }
    final extension = path.extension(source.path).toLowerCase();
    if (!supportedExtensions.contains(extension)) {
      throw const FormatException('Unsupported receipt image extension.');
    }
    final directory = await _receiptDirectory();
    final filename = '${_uuid.v4()}$extension';
    final destination = File(path.join(directory.path, filename));
    await source.copy(destination.path);
    return path.posix.join(directoryName, filename);
  }

  Future<ReceiptLookup> resolve(String relativeReference) async {
    if (!_isValidReference(relativeReference)) {
      return const ReceiptLookup(status: ReceiptLookupStatus.invalidReference);
    }
    final root = await _rootDirectory();
    final file = File(
      path.joinAll(<String>[root.path, ...path.posix.split(relativeReference)]),
    );
    if (!await file.exists()) {
      return const ReceiptLookup(status: ReceiptLookupStatus.missing);
    }
    return ReceiptLookup(status: ReceiptLookupStatus.available, file: file);
  }

  Future<bool> delete(String relativeReference) async {
    final lookup = await resolve(relativeReference);
    if (lookup.status == ReceiptLookupStatus.invalidReference) {
      throw const FormatException('Invalid receipt reference.');
    }
    if (lookup.file == null) {
      return false;
    }
    await lookup.file!.delete();
    return true;
  }

  Future<ReceiptClearReport> clearAll() async {
    final directory = await _receiptDirectory();
    var deleted = 0;
    final failures = <String>[];
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File) {
        continue;
      }
      try {
        await entity.delete();
        deleted += 1;
      } on FileSystemException {
        failures.add(path.basename(entity.path));
      }
    }
    return ReceiptClearReport(
      deletedFiles: deleted,
      failures: List<String>.unmodifiable(failures),
    );
  }

  Future<Directory> _receiptDirectory() async {
    final root = await _rootDirectory();
    final directory = Directory(path.join(root.path, directoryName));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  bool _isValidReference(String reference) {
    if (reference.isEmpty || path.posix.isAbsolute(reference)) {
      return false;
    }
    final normalized = path.posix.normalize(reference);
    return normalized == reference &&
        path.posix.isWithin(directoryName, normalized) &&
        path.posix.dirname(normalized) == directoryName;
  }
}
