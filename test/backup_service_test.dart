import 'dart:convert';
import 'dart:io';

import 'package:cuan_mobile/features/settings/data/backup_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BackupService', () {
    test('menyimpan JSON ke file dan membuka share sheet', () async {
      final tmp = await Directory.systemTemp.createTemp('backup_test');
      var sharedPath = '';
      final service = BackupService(
        exportData: () async => {
          'transactions': [
            {'id': '1', 'amount': '35000'},
          ],
          'budgets': [],
        },
        documentsDir: () async => tmp,
        shareFile: (path) async => sharedPath = path,
      );

      final result = await service.backup();

      expect(
        result.fileName,
        matches(
          RegExp(r'^cuan-backup-\d{4}-\d{2}-\d{2}T\d{2}-\d{2}-\d{2}\.json$'),
        ),
      );
      final file = File('${tmp.path}/backups/${result.fileName}');
      expect(await file.exists(), isTrue);
      expect(result.filePath, file.path);
      final content = jsonDecode(await file.readAsString()) as Map;
      expect((content['transactions'] as List).length, 1);
      expect(sharedPath, result.filePath);

      await tmp.delete(recursive: true);
    });

    test('gagal dengan BackupException saat export error', () async {
      final tmp = await Directory.systemTemp.createTemp('backup_test');
      final service = BackupService(
        exportData: () async => throw Exception('network down'),
        documentsDir: () async => tmp,
        shareFile: (_) async {},
      );

      await expectLater(service.backup(), throwsA(isA<BackupException>()));

      await tmp.delete(recursive: true);
    });

    test('file tetap tersimpan walau share sheet gagal dibuka', () async {
      final tmp = await Directory.systemTemp.createTemp('backup_test');
      final service = BackupService(
        exportData: () async => {'transactions': []},
        documentsDir: () async => tmp,
        shareFile: (_) async =>
            throw PlatformException(code: 'SHARE_FAILED'),
      );

      final result = await service.backup();

      expect(await File(result.filePath).exists(), isTrue);

      await tmp.delete(recursive: true);
    });
  });
}
