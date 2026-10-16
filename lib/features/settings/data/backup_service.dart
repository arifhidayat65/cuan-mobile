import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/api/cuan_api.dart';

/// Thrown when a backup cannot be completed (export or file write failed).
class BackupException implements Exception {
  BackupException(this.message);

  final String message;

  @override
  String toString() => 'BackupException: $message';
}

/// Result of a successful backup: the saved file.
class BackupResult {
  BackupResult({required this.fileName, required this.filePath});

  final String fileName;
  final String filePath;
}

/// Exports user data to a JSON file and opens the Android share sheet.
///
/// Dependencies are injectable so the flow is unit-testable without a device:
/// - [exportData] defaults to [CuanApi.backupExport]
/// - [documentsDir] defaults to [getApplicationDocumentsDirectory]
/// - [shareFile] defaults to the native share sheet via MethodChannel
///   `com.cuan.app/share` (no-op on non-Android platforms).
class BackupService {
  BackupService({
    Future<Map<String, dynamic>> Function()? exportData,
    Future<Directory> Function()? documentsDir,
    Future<void> Function(String path)? shareFile,
  })  : _exportData = exportData ?? (() => api.backupExport()),
        _documentsDir = documentsDir ?? getApplicationDocumentsDirectory,
        _shareFile = shareFile ?? _nativeShareFile;

  final Future<Map<String, dynamic>> Function() _exportData;
  final Future<Directory> Function() _documentsDir;
  final Future<void> Function(String) _shareFile;

  static const MethodChannel _channel = MethodChannel('com.cuan.app/share');

  /// Opens the Android share sheet for [path] via MainActivity.
  static Future<void> _nativeShareFile(String path) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('shareFile', {'path': path});
  }

  /// Downloads the export, saves it as `cuan-backup-<timestamp>.json` under
  /// `<documents>/backups/`, then opens the share sheet.
  ///
  /// A failing share sheet does NOT fail the backup — the file is already
  /// saved, so the result is still returned.
  Future<BackupResult> backup() async {
    late final Map<String, dynamic> data;
    try {
      data = await _exportData();
    } catch (e) {
      throw BackupException('Gagal mengunduh data: $e');
    }

    final dir = Directory('${(await _documentsDir()).path}/backups');
    final stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final fileName = 'cuan-backup-$stamp.json';
    final file = File('${dir.path}/$fileName');
    try {
      await dir.create(recursive: true);
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(data),
      );
    } catch (e) {
      throw BackupException('Gagal menyimpan file backup: $e');
    }

    // Best-effort: the backup file already exists even if the sheet fails.
    try {
      await _shareFile(file.path);
    } catch (_) {
      // ignore — file is saved; UI still reports success.
    }
    return BackupResult(fileName: fileName, filePath: file.path);
  }
}
