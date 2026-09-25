import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_order/core/utils/password_utils.dart';
import 'package:omni_order/domain/models/admin.dart';
import 'package:omni_order/domain/models/product.dart';
import 'package:omni_order/domain/models/store_settings.dart';

import 'fakes/fake_store_repository.dart';
import 'test_helpers.dart';

void main() {
  testWidgets('الشاشة الرئيسية تظهر اسم المتجر والبطاقات الأساسية', (tester) async {
    final repository = FakeStoreRepository();
    await repository.addProduct(Product(name: 'عصير', price: 10, stock: 5));
    await repository.saveSettings(
      StoreSettings.empty.copyWith(storeName: 'محل السعادة'),
    );

    await pumpApp(tester, repository);

    expect(find.text('محل السعادة'), findsOneWidget);
    // البطاقات الأساسية فقط في الرئيسية.
    expect(find.text('طلب جديد'), findsOneWidget);
    expect(find.text('أوردر الدليفري'), findsOneWidget);
    expect(find.text('المنيو'), findsOneWidget);
    expect(find.text('الوردية'), findsOneWidget);
    expect(find.text('التقارير'), findsOneWidget);
    // باقي الميزات في القائمة الجانبية.
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    expect(find.text('الطلبات السابقة'), findsOneWidget);
    expect(find.text('الموردين'), findsOneWidget);
    expect(find.text('العملاء'), findsOneWidget);
  });

  testWidgets('فتح شاشة المنيو يعرض الأصناف المحفوظة', (tester) async {
    final repository = FakeStoreRepository();
    await repository.addProduct(Product(name: 'أرز', price: 25, stock: 40));
    await repository.addProduct(Product(name: 'زيت', price: 60, stock: 10));

    await pumpApp(tester, repository);

    await tester.scrollUntilVisible(
      find.text('المنيو'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('المنيو'));
    await tester.pumpAndSettle();

    expect(find.text('أرز'), findsOneWidget);
    expect(find.text('زيت'), findsOneWidget);
  });

  testWidgets('بدون مستخدمين تظهر شاشة إنشاء الأدمن الأساسي', (tester) async {
    final repository = FakeStoreRepository();

    await tester.pumpWidget(pumpAppWidget(repository));
    await tester.pumpAndSettle();

    expect(find.text('إنشاء الأدمن الأساسي'), findsOneWidget);
    expect(find.byKey(const Key('setup_username')), findsOneWidget);
  });

  testWidgets('تسجيل دخول خاطئ يعرض رسالة خطأ', (tester) async {
    final repository = FakeStoreRepository();
    await seedSuperAdmin(repository);

    await tester.pumpWidget(pumpAppWidget(repository));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('login_username')), testUsername);
    await tester.enterText(find.byKey(const Key('login_password')), 'wrong');
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pumpAndSettle();

    expect(find.text('اسم المستخدم أو كلمة السر غير صحيحة.'), findsOneWidget);
  });

  testWidgets('الكاشير يرى البيع فقط ولا يرى إدارة المخزون', (tester) async {
    final repository = FakeStoreRepository();
    await seedSuperAdmin(repository);
    await repository.addAdmin(
      Admin(
        username: 'cashier1',
        passwordHash: PasswordUtils.hash(testPassword),
        role: UserRole.cashier,
      ),
    );

    await tester.pumpWidget(pumpAppWidget(repository));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('login_username')), 'cashier1');
    await tester.enterText(
      find.byKey(const Key('login_password')),
      testPassword,
    );
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pumpAndSettle();

    expect(find.text('طلب جديد'), findsOneWidget);
    // الكاشير لا يرى إلا بطاقات البيع الأساسية.
    expect(find.text('المنيو'), findsNothing);
    expect(find.text('التقارير'), findsNothing);
    // باقي الميزات (بما فيها العملاء والطلبات السابقة) في القائمة الجانبية
    // حسب صلاحياته، وليست في الرئيسية.
    expect(find.text('العملاء'), findsNothing);
    expect(find.text('المصروفات'), findsNothing);
    expect(find.text('الطلبات السابقة'), findsNothing);

    // يفتح القائمة الجانبية فيرى ما يملك صلاحيتها فقط.
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    expect(find.text('الطلبات السابقة'), findsOneWidget);
    expect(find.text('العملاء'), findsOneWidget);
    expect(find.text('الموردين'), findsNothing);
  });

  testWidgets('تبديل الدور من الإعدادات: أدمن -> كاشير -> أدمن', (
    tester,
  ) async {
    final repository = FakeStoreRepository();
    await seedSuperAdmin(repository);
    await tester.pumpWidget(pumpAppWidget(repository));
    await tester.pumpAndSettle();
    await login(tester);

    // أدمن -> كاشير مباشرة (بدون كلمة سر).
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    final switchAction = find.text('تبديل الدور');
    await tester.ensureVisible(switchAction);
    await tester.tap(switchAction);
    await tester.pumpAndSettle();
    await tester.tap(find.text('تبديل'));
    await tester.pumpAndSettle();

    // واجهة الكاشير: بيع فقط.
    expect(find.text('طلب جديد'), findsOneWidget);
    expect(find.text('المنيو'), findsNothing);
    expect(find.text('التقارير'), findsNothing);

    // كاشير -> أدمن: يلزم اسم المستخدم وكلمة السر.
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    final switchAction2 = find.text('تبديل الدور');
    await tester.ensureVisible(switchAction2);
    await tester.tap(switchAction2);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('admin_username')),
      testUsername,
    );
    await tester.enterText(
      find.byKey(const Key('admin_password')),
      testPassword,
    );
    await tester.enterText(
      find.byKey(const Key('admin_confirm')),
      testPassword,
    );
    await tester.tap(find.text('إنشاء ودخول'));
    await tester.pumpAndSettle();

    // عودة لواجهة الأدمن.
    expect(find.text('المنيو'), findsOneWidget);
    expect(find.text('التقارير'), findsOneWidget);
  });

  testWidgets('إعدادات التطبيق تعرض خيارات النسخ الاحتياطي والاستعادة', (
    tester,
  ) async {
    final repository = FakeStoreRepository();
    await seedSuperAdmin(repository);
    await tester.pumpWidget(pumpAppWidget(repository));
    await tester.pumpAndSettle();
    await login(tester);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.text('نسخ احتياطي'), findsOneWidget);
    expect(find.text('استعادة نسخة'), findsOneWidget);
  });

}
