import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:omni_order/data/database/app_database.dart';
import 'package:omni_order/data/repositories/store_repository_impl.dart';
import 'package:omni_order/domain/models/admin.dart';
import 'package:omni_order/domain/models/category.dart';
import 'package:omni_order/domain/models/coupon.dart';
import 'package:omni_order/domain/models/customer.dart';
import 'package:omni_order/domain/models/employee.dart';
import 'package:omni_order/domain/models/expense.dart';
import 'package:omni_order/domain/models/hall.dart';
import 'package:omni_order/domain/models/product.dart';
import 'package:omni_order/domain/models/purchase.dart';
import 'package:omni_order/domain/models/queue_entry.dart';
import 'package:omni_order/domain/models/restaurant_table.dart';
import 'package:omni_order/domain/models/reservation.dart';
import 'package:omni_order/domain/models/sale.dart';
import 'package:omni_order/domain/models/sale_item.dart';
import 'package:omni_order/core/constants/payment_methods.dart';
import 'package:omni_order/domain/models/store_settings.dart';
import 'package:omni_order/domain/models/supplier.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// اختبار الحفظ الدائم الشامل: إنشاء كل أنواع البيانات، ثم إغلاق قاعدة
/// البيانات وإعادة فتحها (محاكاة إغلاق التطبيق وفتحه) والتحقق من أن كل
/// شيء ما زال محفوظًا.
void main() {
  setUpAll(sqfliteFfiInit);

  test('كل البيانات تبقى محفوظة بعد إعادة تشغيل التطبيق', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await Directory.systemTemp.createTemp('omni_full_persist');
    AppDatabase.overrideDatabasesPath = dir.path;
    try {
      // ── الجلسة الأولى: المستخدم يُنشئ كل شيء ──
      await AppDatabase.instance.close();
      var repo = StoreRepositoryImpl(AppDatabase.instance);
      await repo.init();

      await repo.addAdmin(Admin(
        username: 'المدير',
        passwordHash: 'hash123',
        role: UserRole.superAdmin,
      ));

      await repo.saveSettings(StoreSettings(
        storeName: 'مطعمي',
        phone: '01000000000',
        currency: 'ج.م',
      ));

      final categoryId = await repo.addCategory(Category(name: 'مشروبات'));
      await repo.addProduct(Product(
        name: 'عصير مانجو',
        price: 25,
        stock: 50,
        categoryId: categoryId,
      ));

      await repo.addCustomer(Customer(name: 'أحمد', phone: '01111111111'));
      await repo.addSupplier(Supplier(name: 'شركة المرطبات'));
      await repo.addExpense(Expense(name: 'إيجار', amount: 2000));
      final hallId = await repo.addHall(Hall(name: 'الصالة الرئيسية', capacity: 20));
      await repo.addEmployee(Employee(name: 'محمد الكاشير'));
      await repo.addCoupon(Coupon(code: 'RABH10', discountValue: 10));

      // جداول كانت ناقصة في القواعد الجديدة قبل الإصلاح.
      final tableId = await repo.addTable(
        RestaurantTable(hallId: hallId, number: 5),
      );
      await repo.createReservation(Reservation(
        tableId: tableId,
        tableNumber: 5,
        customerName: 'وليد',
        partySize: 4,
        reservationTime: DateTime.now(),
      ));
      await repo.addQueueEntry(QueueEntry(customerName: 'زائر انتظار', partySize: 2));
      await repo.createPurchase(
        purchase: Purchase(supplierName: 'شركة المرطبات', total: 480),
        items: [],
      );

      final productId = (await repo.getProducts()).first.id!;
      await repo.createSale(
        sale: Sale(
          total: 25,
          itemsCount: 1,
          paymentMethod: PaymentMethod.cash,
          cashierName: 'المدير',
        ),
        items: [
          SaleItem(
            saleId: 0,
            productId: productId,
            name: 'عصير مانجو',
            price: 25,
            quantity: 1,
            subtotal: 25,
          ),
        ],
      );

      // ── إغلاق التطبيق وفتحه من جديد ──
      await AppDatabase.instance.close();
      repo = StoreRepositoryImpl(AppDatabase.instance);
      await repo.init();

      // ── الجلسة الثانية: كل شيء يجب أن يكون موجودًا ──
      final admins = await repo.getAdmins();
      expect(admins, isNotEmpty, reason: 'الأدمن محفوظ → شاشة تسجيل الدخول');
      expect(admins.first.username, 'المدير');

      expect((await repo.getSettings()).storeName, 'مطعمي');
      expect((await repo.getCategories()).first.name, 'مشروبات');

      final products = await repo.getProducts();
      expect(products.first.name, 'عصير مانجو');
      expect(products.first.categoryId, categoryId);

      expect((await repo.getCustomers()).first.name, 'أحمد');
      expect((await repo.getSuppliers()).first.name, 'شركة المرطبات');
      expect((await repo.getExpenses()).first.name, 'إيجار');
      expect((await repo.getHalls()).first.name, 'الصالة الرئيسية');
      expect((await repo.getEmployees()).first.name, 'محمد الكاشير');
      expect((await repo.getCoupons()).first.code, 'RABH10');

      // الجداول المُصلحة: بياناتها محفوظة بعد إعادة التشغيل.
      expect((await repo.getReservations()).first.customerName, 'وليد');
      expect((await repo.getQueueEntries()).first.customerName, 'زائر انتظار');
      expect((await repo.getPurchases()).first.supplierName, 'شركة المرطبات');

      final sales = await repo.getSalesOn(DateTime.now());
      expect(sales, isNotEmpty, reason: 'الفاتورة محفوظة');
    } finally {
      await AppDatabase.instance.close();
      AppDatabase.overrideDatabasesPath = null;
      dir.deleteSync(recursive: true);
    }
  });
}
