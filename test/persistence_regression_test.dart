import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:omni_order/data/database/app_database.dart';
import 'package:omni_order/data/repositories/store_repository_impl.dart';
import 'package:omni_order/domain/models/admin.dart';
import 'package:omni_order/domain/models/product.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// اختبار انحدار: بيانات الأدمن والأصناف يجب أن تبقى محفوظة بعد إعادة
/// فتح قاعدة البيانات (محاكاة إعادة تشغيل التطبيق بالكامل).
void main() {
  setUpAll(sqfliteFfiInit);

  test('الأدمن والبيانات تُحمّل بعد إعادة التشغيل (تظهر شاشة الدخول)', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await Directory.systemTemp.createTemp('omni_db_persist');
    AppDatabase.overrideDatabasesPath = dir.path;
    try {
      // أول تشغيل: إنشاء أدمن أساسي + بيانات.
      await AppDatabase.instance.close();
      var repository = StoreRepositoryImpl(AppDatabase.instance);
      await repository.init();
      await repository.addAdmin(Admin(
        username: 'owner1',
        passwordHash: 'hash',
        role: UserRole.superAdmin,
      ));
      await repository.addProduct(Product(name: 'صنف تجربة', price: 5, stock: 9));
      await AppDatabase.instance.close();

      // إعادة تشغيل: نفس المسار، اتصال جديد — يجب ألا تظهر شاشة الإعداد.
      repository = StoreRepositoryImpl(AppDatabase.instance);
      await repository.init();

      final admins = await repository.getAdmins();
      expect(admins, isNotEmpty, reason: 'يجب عرض شاشة تسجيل الدخول');
      expect(admins.first.username, 'owner1');

      final products = await repository.getProducts();
      expect(products.first.name, 'صنف تجربة');
    } finally {
      await AppDatabase.instance.close();
      AppDatabase.overrideDatabasesPath = null;
      dir.deleteSync(recursive: true);
    }
  });
}
