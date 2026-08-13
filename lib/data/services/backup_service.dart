import 'dart:io';

import 'package:path/path.dart' as p;

import '../database/app_database.dart';

/// خدمة بسيطة للنسخ الاحتياطي واستعادة قاعدة البيانات المحلية.
class BackupService {
  BackupService._();

  static Future<String> createBackup() async {
    final dbPath = AppDatabase.instance.path;
    if (dbPath == null || dbPath.isEmpty) {
      throw StateError('لم يتم فتح قاعدة البيانات بعد.');
    }

    final dbFile = File(dbPath);
    if (!await dbFile.exists()) {
      throw StateError('ملف قاعدة البيانات غير موجود.');
    }

    final backupDir = dbFile.parent;
    final stamp = DateTime.now()
        .toUtc()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final backupPath = p.join(backupDir.path, 'omni_order_backup_$stamp.db');

    await dbFile.copy(backupPath);
    return backupPath;
  }

  static Future<bool> restoreLatestBackup() async {
    final dbPath = AppDatabase.instance.path;
    if (dbPath == null || dbPath.isEmpty) {
      return false;
    }

    final dbFile = File(dbPath);
    final dir = dbFile.parent;
    final backups = await dir
        .list()
        .where((entity) => entity is File)
        .map((entity) => entity as File)
        .where((file) => p.basename(file.path).startsWith('omni_order_backup_'))
        .toList();

    if (backups.isEmpty) return false;
    backups.sort((a, b) => b.path.compareTo(a.path));

    await AppDatabase.instance.close();
    await backups.first.copy(dbPath);
    await AppDatabase.instance.database;
    return true;
  }
}
