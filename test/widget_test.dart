import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_order/core/utils/password_utils.dart';
import 'package:omni_order/domain/models/admin.dart';
import 'package:omni_order/domain/models/product.dart';
import 'package:omni_order/domain/models/store_settings.dart';
import 'package:omni_order/domain/models/supplier.dart';
import 'package:omni_order/features/products/presentation/products_cubit.dart';
import 'package:omni_order/features/purchases/presentation/purchase_form_screen.dart';
import 'package:omni_order/features/purchases/presentation/purchases_cubit.dart';
import 'package:omni_order/features/settings/presentation/settings_cubit.dart';
import 'package:omni_order/features/suppliers/presentation/supplier_reports_screen.dart';
import 'package:omni_order/features/suppliers/presentation/suppliers_cubit.dart';
import 'package:omni_order/main.dart';

import 'fakes/fake_store_repository.dart';
import 'test_helpers.dart';

void main() {
  testWidgets('الشاشة الرئيسية تظهر اسم المتجر والقوائم', (tester) async {
    final repository = FakeStoreRepository();
    await repository.addProduct(Product(name: 'عصير', price: 10, stock: 5));
    await repository.saveSettings(
      StoreSettings.empty.copyWith(storeName: 'محل السعادة'),
    );

    await pumpApp(tester, repository);

    expect(find.text('محل السعادة'), findsOneWidget);
    expect(find.text('بيع جديد'), findsOneWidget);
    expect(find.text('المخزون'), findsOneWidget);
    expect(find.text('المبيعات السابقة'), findsOneWidget);
  });

  testWidgets('فتح شاشة المخزون يعرض الأصناف المحفوظة', (tester) async {
    final repository = FakeStoreRepository();
    await repository.addProduct(Product(name: 'أرز', price: 25, stock: 40));
    await repository.addProduct(Product(name: 'زيت', price: 60, stock: 10));

    await pumpApp(tester, repository);

    await tester.tap(find.text('المخزون'));
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

    await tester.enterText(find.byKey(const Key('login_email')), testUsername);
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

    await tester.enterText(find.byKey(const Key('login_email')), 'cashier1');
    await tester.enterText(
      find.byKey(const Key('login_password')),
      testPassword,
    );
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pumpAndSettle();

    expect(find.text('بيع جديد'), findsOneWidget);
    expect(find.text('المبيعات السابقة'), findsOneWidget);
    expect(find.text('المخزون'), findsNothing);
    expect(find.text('العملاء'), findsNothing);
    expect(find.text('المصروفات'), findsNothing);
    expect(find.text('التقارير'), findsNothing);
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
    expect(find.text('بيع جديد'), findsOneWidget);
    expect(find.text('المخزون'), findsNothing);
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
    expect(find.text('المخزون'), findsOneWidget);
    expect(find.text('التقارير'), findsOneWidget);
  });

  testWidgets(
    'إضافة عنصر جديد لفاتورة شراء مع تحديد الوحدة وسعر البيع والكمية',
    (tester) async {
      final repository = FakeStoreRepository();

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => ProductsCubit(repository)..init()),
            BlocProvider(create: (_) => SuppliersCubit(repository)..init()),
            BlocProvider(
              create: (context) =>
                  PurchasesCubit(repository, context.read<ProductsCubit>())
                    ..init(),
            ),
          ],
          child: const MaterialApp(home: PurchaseFormScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('purchase_new_product_name')),
        'ماء معبأ',
      );
      await tester.enterText(
        find.byKey(const Key('purchase_new_product_sale_price')),
        '18',
      );
      await tester.tap(find.text('كرتونة'));
      await tester.enterText(find.byKey(const Key('purchase_quantity')), '5');
      await tester.enterText(find.byKey(const Key('purchase_price')), '12');
      await tester.ensureVisible(find.text('إضافة للفاتورة'));
      await tester.tap(find.text('إضافة للفاتورة'));
      await tester.pumpAndSettle();

      expect(find.text('ماء معبأ'), findsOneWidget);
      expect(find.text('كرتونة'), findsWidgets);

      await tester.enterText(
        find.byKey(const Key('purchase_supplier')),
        'مورد الأرز',
      );
      await tester.ensureVisible(find.text('حفظ فاتورة الشراء'));
      await tester.tap(find.text('حفظ فاتورة الشراء'));
      await tester.pumpAndSettle();

      expect(repository.products.length, 1);
      expect(repository.products.first.name, 'ماء معبأ');
      expect(repository.products.first.unit, 'كرتونة');
      expect(repository.products.first.price, 18);
      expect(repository.products.first.stock, 5);
      expect(repository.purchases.length, 1);
    },
  );

  testWidgets('فواتير الشراء الجزئية ترفع المديونية فقط بعد الخصم من الدفع', (
    tester,
  ) async {
    final repository = FakeStoreRepository();
    final supplier = await repository.addSupplier(
      Supplier(name: 'مورد الأرز', phone: '01000000000'),
    );
    final productsCubit = ProductsCubit(repository)..init();
    final purchasesCubit = PurchasesCubit(repository, productsCubit)..init();
    final product = Product(name: 'أرز', price: 30, stock: 0, unit: 'كجم');
    await repository.addProduct(product);

    final error = await purchasesCubit.createPurchase(
      supplierName: 'مورد الأرز',
      note: 'فاتورة جزئية',
      paidAmount: 30,
      lines: [
        (
          product: (await repository.getProducts()).first,
          quantity: 5,
          price: 20,
        ),
      ],
    );

    expect(error, isNull);
    expect(repository.purchases.length, 1);
    expect(repository.purchases.first.total, 100);
    expect(repository.purchases.first.paidAmount, 30);
    expect(repository.suppliers.first.balance, 70);
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

  testWidgets('شاشة التقارير تعرض تقرير الموردين مع فلتر التاريخ والتصدير', (
    tester,
  ) async {
    final repository = FakeStoreRepository();
    await repository.addSupplier(
      Supplier(name: 'مورد الأرز', phone: '01000000000', balance: 300),
    );
    final productsCubit = ProductsCubit(repository)..init();
    final purchasesCubit = PurchasesCubit(repository, productsCubit)..init();
    final suppliersCubit = SuppliersCubit(repository)..init();
    final settingsCubit = SettingsCubit(repository)..init();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ProductsCubit>.value(value: productsCubit),
          BlocProvider<PurchasesCubit>.value(value: purchasesCubit),
          BlocProvider<SuppliersCubit>.value(value: suppliersCubit),
          BlocProvider<SettingsCubit>.value(value: settingsCubit),
        ],
        child: const MaterialApp(home: SupplierReportsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('تقرير الموردين'), findsOneWidget);
    expect(find.text('تصفية حسب المورد'), findsOneWidget);
    expect(find.text('تصدير Excel'), findsOneWidget);
  });

  testWidgets('فتح تفاصيل المورد يعرض المديونية وسجل السداد', (tester) async {
    final repository = FakeStoreRepository();
    await seedSuperAdmin(repository);
    await repository.addSupplier(
      Supplier(name: 'مورد الأرز', phone: '01000000000', balance: 300),
    );

    await tester.pumpWidget(OmniOrderApp(repository: repository));
    await tester.pumpAndSettle();
    await login(tester);

    await tester.tap(find.text('الموردين'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('مورد الأرز'));
    await tester.pumpAndSettle();

    expect(find.text('تفاصيل المورد'), findsOneWidget);
    expect(find.text('مستحق: 300 ج.م'), findsOneWidget);
  });
}
