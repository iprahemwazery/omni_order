import 'dart:io';

import 'package:media_store_plus/media_store_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../database/app_database.dart';

/// خدمة بسيطة للنسخ الاحتياطي واستعادة قاعدة البيانات المحلية،
/// مع التصدير إلى التنزيلات العامة والمزامنة السحابية عبر Supabase Storage.
class BackupService {
  BackupService._();

  static const String _cloudBucket = 'omni_order_backups';
  static const String _cloudFolder = 'backups';
  static bool _mediaStoreInitialized = false;

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

  /// ينشئ نسخة احتياطية ويحفظها في مجلد التنزيلات العام حتى يصل إليها المستخدم
  /// بسهولة. يعيد وصف مكان الحفظ عند النجاح أو null عند الفشل.
  static Future<String?> createBackupInDownloads() async {
    final backupPath = await createBackup();

    if (!Platform.isAndroid) {
      final dir = await getApplicationDocumentsDirectory();
      final target = File(p.join(dir.path, p.basename(backupPath)));
      await File(backupPath).copy(target.path);
      return 'مستندات التطبيق';
    }

    if (!_mediaStoreInitialized) {
      await MediaStore.ensureInitialized();
      _mediaStoreInitialized = true;
    }
    MediaStore.appFolder = 'OmniOrder';

    final store = MediaStore();
    final info = await store.saveFile(
      tempFilePath: backupPath,
      dirType: DirType.download,
      dirName: DirName.download,
      relativePath: FilePath.root,
    );

    return info == null ? null : 'مجلد التنزيلات';
  }

  /// يرفع نسخة احتياطية إلى Supabase Storage ويعيد اسم الملف المرفوع.
  static Future<String> uploadBackupToCloud() async {
    _ensureSupabase();
    final backupPath = await createBackup();
    final fileName = '$_cloudFolder/omni_order_${DateTime.now().millisecondsSinceEpoch}.db';

    await Supabase.instance.client.storage
        .from(_cloudBucket)
        .upload(fileName, File(backupPath), fileOptions: const FileOptions(upsert: true));

    return fileName;
  }

  /// يسحب أحدث نسخة احتياطية من السحابة ويستعيدها محليًا.
  /// يعيد عدد النسخ السحابية المتاحة قبل الاستعادة.
  static Future<int> downloadLatestFromCloud() async {
    _ensureSupabase();
    final storage = Supabase.instance.client.storage;
    final files = await storage.from(_cloudBucket).list(path: _cloudFolder);
    if (files.isEmpty) {
      throw StateError('لا توجد نسخ احتياطية في السحابة بعد.');
    }

    final latest = files
        .where((f) => f.name.endsWith('.db'))
        .toList()
      ..sort((a, b) => b.name.compareTo(a.name));
    if (latest.isEmpty) {
      throw StateError('لا توجد نسخ احتياطية في السحابة بعد.');
    }

    final dbPath = AppDatabase.instance.path;
    if (dbPath == null || dbPath.isEmpty) {
      throw StateError('لم يتم فتح قاعدة البيانات بعد.');
    }

    final tempDir = await getTemporaryDirectory();
    final tempFile = File(p.join(tempDir.path, latest.first.name));
    final bytes = await storage
        .from(_cloudBucket)
        .download('$_cloudFolder/${latest.first.name}');
    await tempFile.writeAsBytes(bytes);

    await AppDatabase.instance.close();
    await tempFile.copy(dbPath);
    await AppDatabase.instance.database;
    return files.length;
  }

  static void _ensureSupabase() {
    if (!SupabaseConfig.isConfigured || !Supabase.instance.isInitialized) {
      throw StateError(
        'Supabase غير مُهيّأ. أضف بيانات مشروعك في supabase_config.dart أولًا.',
      );
    }
  }
}
