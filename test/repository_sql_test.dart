import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:omni_order/core/constants.dart';
import 'package:omni_order/data/database/app_database.dart';
import 'package:omni_order/data/repositories/store_repository_impl.dart';
import 'package:omni_order/domain/models/hall.dart';
import 'package:omni_order/domain/models/held_cart.dart';
import 'package:omni_order/domain/models/order.dart';
import 'package:omni_order/domain/models/order_item.dart';
import 'package:omni_order/domain/models/product.dart';
import 'package:omni_order/domain/models/restaurant_table.dart';
import 'package:omni_order/domain/models/sale.dart';
import 'package:omni_order/domain/models/sale_item.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// اختبارات تكامل على SQLite حقيقية (ffi) للتحقق من إصلاح الأخطاء
/// في الاستعلامات والتزامن بين الجداول.
void main() {
  setUpAll(sqfliteFfiInit);

  late StoreRepositoryImpl repository;

  Future<void> freshDatabase() async {
    await AppDatabase.instance.close();
    final dir = await databaseFactoryFfi.getDatabasesPath();
    for (final name in [
      AppConstants.dbName,
      '${AppConstants.dbName}-wal',
      '${AppConstants.dbName}-shm',
    ]) {
      final file = File(p.join(dir, name));
      if (file.existsSync()) file.deleteSync();
    }
    AppDatabase.overrideDatabasesPath = dir;
    repository = StoreRepositoryImpl(AppDatabase.instance);
    await repository.init();
  }

  setUp(freshDatabase);

  Future<int> createHallOrder({
    required int productId,
    required int hallId,
    int? tableId,
    double total = 20,
  }) {
    return repository.createOrder(
      order: RestaurantOrder(
        tableId: tableId,
        hallId: hallId,
        total: total,
        orderType: OrderType.hall.name,
      ),
      items: [
        OrderItem(
          orderId: 0,
          productId: productId,
          name: 'طبق',
          price: total,
          quantity: 1,
          subtotal: total,
        ),
      ],
    );
  }

  test('تسديد الطاولة يحتسب الطلبات غير المسددة فقط ويحررها', () async {
    final productId = await repository.addProduct(
      Product(name: 'طبق', price: 20, stock: 20),
    );
    final hallId = await repository.addHall(Hall(name: 'الصالة'));
    final tableId = await repository.addTable(
      RestaurantTable(hallId: hallId, number: 1),
    );

    final pendingId = await createHallOrder(
      productId: productId,
      hallId: hallId,
      tableId: tableId,
      total: 20,
    );
    final servedId = await createHallOrder(
      productId: productId,
      hallId: hallId,
      tableId: tableId,
      total: 30,
    );
    await repository.updateOrderStatus(servedId, OrderStatus.served);
    expect(
      (await repository.getTableOrders(tableId)).length,
      2,
      reason: 'الطلب المقدم يبقى على الطاولة حتى الدفع',
    );

    expect(await repository.payTable(tableId, 'نقدي'), 50);
    expect((await repository.getTable(tableId))?.status, TableStatus.available);
    expect(
      (await repository.getOrder(pendingId))?.orderStatus,
      OrderStatus.paid,
    );
    expect((await repository.getOrder(servedId))?.paymentMethod, 'نقدي');
    expect(await repository.payTable(tableId, 'نقدي'), 0);
    expect((await repository.getTableOrders(tableId)), isEmpty);
  });

  test('لا يمكن إلغاء طلب تم تسديده', () async {
    final productId = await repository.addProduct(
      Product(name: 'طبق', price: 20, stock: 20),
    );
    final hallId = await repository.addHall(Hall(name: 'الصالة'));
    final tableId = await repository.addTable(
      RestaurantTable(hallId: hallId, number: 1),
    );
    final orderId = await createHallOrder(
      productId: productId,
      hallId: hallId,
      tableId: tableId,
    );
    await repository.payTable(tableId, 'نقدي');

    await expectLater(repository.cancelOrder(orderId), throwsStateError);
    expect((await repository.getOrder(orderId))?.orderStatus, OrderStatus.paid);
  });

  test('تحديث حالة طلب غير موجود لا يرمي استثناء', () async {
    await expectLater(
      repository.updateOrderStatus(9999, OrderStatus.served),
      completes,
    );
    expect(await repository.getOrderStatusHistory(9999), isEmpty);
  });

  test('تحديث حالة الطلب يحافظ على الطاولة عند وجود طلب نشط', () async {
    final productId = await repository.addProduct(
      Product(name: 'طبق', price: 20, stock: 20),
    );
    final hallId = await repository.addHall(Hall(name: 'الصالة'));
    final tableId = await repository.addTable(
      RestaurantTable(hallId: hallId, number: 1),
    );

    Future<int> createOrder() {
      return repository.createOrder(
        order: RestaurantOrder(
          tableId: tableId,
          hallId: hallId,
          total: 20,
          orderType: OrderType.hall.name,
        ),
        items: [
          OrderItem(
            orderId: 0,
            productId: productId,
            name: 'طبق',
            price: 20,
            quantity: 1,
            subtotal: 20,
          ),
        ],
      );
    }

    final firstOrderId = await createOrder();
    final secondOrderId = await createOrder();

    await repository.updateOrderStatus(
      firstOrderId,
      OrderStatus.served,
      note: 'تم التقديم',
    );
    expect((await repository.getTable(tableId))?.status, TableStatus.occupied);
    expect(
      (await repository.getOrderStatusHistory(
        firstOrderId,
      )).any((entry) => entry.status == OrderStatus.served.name),
      isTrue,
    );

    await repository.cancelOrder(secondOrderId);
    expect((await repository.getTable(tableId))?.status, TableStatus.occupied);
    expect(
      (await repository.getOrderStatusHistory(
        secondOrderId,
      )).any((entry) => entry.status == OrderStatus.cancelled.name),
      isTrue,
    );

    expect(await repository.payTable(tableId, 'نقدي'), 20);
    expect((await repository.getTable(tableId))?.status, TableStatus.available);
  });

  test('getDayHistory يستبعد الفواتير المرتجعة', () async {
    final productId = await repository.addProduct(
      Product(name: 'عصير', price: 10, stock: 20),
    );

    final keepId = await repository.createSale(
      sale: Sale(total: 10, itemsCount: 1),
      items: [
        SaleItem(
          saleId: 0,
          productId: productId,
          name: 'عصير',
          price: 10,
          costPrice: 4,
          quantity: 1,
          subtotal: 10,
        ),
      ],
    );

    final refundedId = await repository.createSale(
      sale: Sale(
        total: 20,
        itemsCount: 2,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      items: [
        SaleItem(
          saleId: 0,
          productId: productId,
          name: 'عصير',
          price: 10,
          costPrice: 4,
          quantity: 2,
          subtotal: 20,
        ),
      ],
    );

    await repository.refundSale(refundedId);

    final history = await repository.getDayHistory();
    final refundedDay = DateTime.now().subtract(const Duration(days: 1));
    final hasRefundedDay = history.any(
      (entry) =>
          entry.day.year == refundedDay.year &&
          entry.day.month == refundedDay.month &&
          entry.day.day == refundedDay.day,
    );
    expect(hasRefundedDay, isFalse);
    expect(repository, isNotNull);
    expect(keepId, greaterThan(0));
  });

  test('topProducts يستبعد بنود الفواتير المرتجعة', () async {
    final productId = await repository.addProduct(
      Product(name: 'خبز', price: 5, stock: 20),
    );

    final saleId = await repository.createSale(
      sale: Sale(total: 10, itemsCount: 2),
      items: [
        SaleItem(
          saleId: 0,
          productId: productId,
          name: 'خبز',
          price: 5,
          costPrice: 2,
          quantity: 2,
          subtotal: 10,
        ),
      ],
    );

    final before = await repository.topProducts();
    expect(before.any((t) => t.name == 'خبز'), isTrue);

    await repository.refundSale(saleId);
    final after = await repository.topProducts();
    expect(after.any((t) => t.name == 'خبز'), isFalse);
  });

  Future<int> createSale({
    required double total,
    required String method,
    String cashier = 'admin',
    double tendered = 0,
    double card = 0,
    DateTime? createdAt,
  }) async {
    final productId = await repository.addProduct(
      Product(name: 'منتج', price: total, stock: 100),
    );
    return repository.createSale(
      sale: Sale(
        total: total,
        itemsCount: 1,
        paymentMethod: method,
        cashierName: cashier,
        amountTendered: tendered,
        cardAmount: card,
        createdAt: createdAt,
      ),
      items: [
        SaleItem(
          saleId: 0,
          productId: productId,
          name: 'منتج',
          price: total,
          costPrice: 0,
          quantity: 1,
          subtotal: total,
        ),
      ],
    );
  }

  test(
    'البيع ينشئ وردية تلقائيًا ويحتسب تقرير الوردية حسب طريقة الدفع',
    () async {
      expect(await repository.getOpenShift('admin'), isNull);

      await createSale(total: 100, method: 'نقدي', tendered: 100);
      await createSale(total: 50, method: 'شبكة');
      await createSale(total: 40, method: 'مختلط', card: 10);
      await createSale(total: 30, method: 'آجل');
      await createSale(
        total: 200,
        method: 'نقدي',
        tendered: 250,
        cashier: 'sara',
      );

      final open = await repository.getOpenShift('admin');
      expect(open, isNotNull);
      expect(open!.isOpen, isTrue);

      final report = await repository.getShiftReport(open);
      expect(report.salesCount, 4);
      expect(report.cashTotal, 100);
      expect(report.cardTotal, 50);
      expect(report.walletTotal, 0);
      expect(report.transferTotal, 0);
      expect(report.mixedTotal, 40);
      expect(report.mixedCardPortion, 10);
      expect(report.deferredTotal, 30);
      expect(report.totalSales, 220);
      expect(report.cashReceived, 130); // 100 نقدي + 30 (نقد المختلط)
      expect(report.cardReceived, 60); // 50 شبكة + 10 شبكة المختلط

      // وردية كاشير آخر منفصلة.
      final saraOpen = await repository.getOpenShift('sara');
      expect(saraOpen, isNotNull);
      final saraReport = await repository.getShiftReport(saraOpen!);
      expect(saraReport.salesCount, 1);
      expect(saraReport.cashTotal, 200);
      expect(saraReport.changeGiven, 50);
    },
  );

  test('الباقي المُصرف يُحتسب في تقرير الوردية', () async {
    await createSale(total: 100, method: 'نقدي', tendered: 150);
    final open = (await repository.getOpenShift('admin'))!;
    final report = await repository.getShiftReport(open);
    expect(report.changeGiven, 50);
  });

  test('إغلاق الوردية وإسناد المرتجع للوردية التي حدث فيها', () async {
    final saleId = await createSale(total: 80, method: 'نقدي');
    await repository.refundSale(saleId);

    final open = (await repository.getOpenShift('admin'))!;
    final report = await repository.getShiftReport(open);
    expect(report.salesCount, 0);
    expect(report.refundCount, 1);
    expect(report.refundsTotal, 80);
    expect(report.totalSales, 0);

    final closed = await repository.closeShift('admin');
    expect(closed, isNotNull);
    expect(closed!.closedAt, isNotNull);
    expect(await repository.getOpenShift('admin'), isNull);
    expect(await repository.getLatestShift('admin'), isNotNull);

    // عملية بيع جديدة بعد الإغلاق تفتح وردية جديدة.
    await createSale(total: 10, method: 'نقدي');
    final newShift = (await repository.getOpenShift('admin'))!;
    expect(newShift.id, isNot(open.id));
    final newReport = await repository.getShiftReport(newShift);
    expect(newReport.salesCount, 1);
    expect(newReport.refundCount, 0);
  });

  test('تعليق واسترجاع وحذف الفواتير المعلقة', () async {
    final id = await repository.holdCart(
      cart: HeldCart(
        savedAt: DateTime.now(),
        discount: 5,
        paymentMethod: 'آجل',
        customerId: 7,
        note: 'ملاحظة',
        cashierName: 'admin',
        itemsCount: 2,
        total: 45,
      ),
      items: [
        HeldCartItem(
          heldCartId: 0,
          productId: 1,
          name: 'شاي',
          price: 25,
          quantity: 2,
          subtotal: 50,
        ),
      ],
    );
    expect(id, greaterThan(0));

    final carts = await repository.getHeldCarts();
    expect(carts.length, 1);
    final cart = carts.first;
    expect(cart.total, 45);
    expect(cart.discount, 5);
    expect(cart.paymentMethod, 'آجل');
    expect(cart.customerId, 7);

    final items = await repository.getHeldCartItems(id);
    expect(items.length, 1);
    expect(items.first.name, 'شاي');
    expect(items.first.quantity, 2);

    await repository.deleteHeldCart(id);
    expect((await repository.getHeldCarts()), isEmpty);
    expect((await repository.getHeldCartItems(id)), isEmpty);
  });

  test('المبلغ المدفوع والجزء بالشبكة يُحفظان ويُقرآن', () async {
    final productId = await repository.addProduct(
      Product(name: 'زيت', price: 30, stock: 10),
    );

    final saleId = await repository.createSale(
      sale: Sale(
        total: 30,
        itemsCount: 1,
        paymentMethod: 'مختلط',
        amountTendered: 30,
        cardAmount: 10,
      ),
      items: [
        SaleItem(
          saleId: 0,
          productId: productId,
          name: 'زيت',
          price: 30,
          costPrice: 20,
          quantity: 1,
          subtotal: 30,
        ),
      ],
    );

    final saved = await repository.getSale(saleId);
    expect(saved!.amountTendered, 30);
    expect(saved.cardAmount, 10);
    expect(saved.changeDue, 0);
  });
}
