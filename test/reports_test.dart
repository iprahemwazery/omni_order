import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_order/core/utils/formatters.dart';
import 'package:omni_order/domain/models/customer.dart';
import 'package:omni_order/domain/models/expense.dart';
import 'package:omni_order/domain/models/product.dart';
import 'package:omni_order/domain/models/sale.dart';
import 'package:omni_order/domain/models/sale_item.dart';

import 'fakes/fake_store_repository.dart';
import 'test_helpers.dart';

/// اختبار تكامل التقارير: صافي الربح يُحسب من المبيعات والمصروفات المسجّلة.
void main() {
  Future<void> pumpAppOnPhone(WidgetTester tester, FakeStoreRepository repo) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await pumpApp(tester, repo);
  }

  // فتح شاشة التقارير (كارت أسفل الشاشة الرئيسية — نمرّر له أولًا).
  Future<void> openReports(WidgetTester tester) async {
    await tester.scrollUntilVisible(find.text('التقارير'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('التقارير'));
    await tester.pumpAndSettle();
  }

  testWidgets('التقارير: صافي الربح = المبيعات - المصروفات', (tester) async {
    final repository = FakeStoreRepository();
    final product = Product(name: 'عصير', price: 50, stock: 20);
    final productId = await repository.addProduct(product);
    await repository.createSale(
      sale: Sale(total: 100, itemsCount: 2, cashierName: testUsername),
      items: [
        SaleItem(
          saleId: 0,
          productId: productId,
          name: 'عصير',
          price: 50,
          quantity: 2,
          subtotal: 100,
        ),
      ],
    );
    await repository.addExpense(Expense(name: 'إيجار', amount: 30));

    await pumpAppOnPhone(tester, repository);

    await openReports(tester);

    // بانر صافي الربح (المبيعات 100 - المصروفات 30 = 70).
    expect(find.text('صافي الربح'), findsOneWidget);
    expect(find.text('70 ج.م'), findsWidgets);

    // بطاقات الإحصاءات.
    expect(find.text('مبيعات اليوم'), findsOneWidget);
    expect(find.text('مصروفات اليوم'), findsOneWidget);
    expect(find.text('صافي اليوم'), findsOneWidget);
    expect(find.text('100 ج.م'), findsWidgets);
    expect(find.text('30 ج.م'), findsWidgets);
  });

  testWidgets('التقارير: البيع الآجل يُحسب مديونية ولا يدخل في صافي الربح', (tester) async {
    final repository = FakeStoreRepository();
    final product = Product(name: 'عصير', price: 50, stock: 20);
    final productId = await repository.addProduct(product);
    final customerId = await repository.addCustomer(
      Customer(name: 'محمود', phone: '010'),
    );
    await repository.createSale(
      sale: Sale(
        total: 40,
        itemsCount: 2,
        paymentMethod: 'آجل',
        customerId: customerId,
        cashierName: testUsername,
      ),
      items: [
        SaleItem(
          saleId: 0,
          productId: productId,
          name: 'عصير',
          price: 20,
          quantity: 2,
          subtotal: 40,
        ),
      ],
    );
    await repository.updateCustomer(
      repository.customers.firstWhere((c) => c.id == customerId).copyWith(balance: 40),
    );
    await repository.createSale(
      sale: Sale(total: 60, itemsCount: 1, cashierName: testUsername),
      items: [
        SaleItem(
          saleId: 0,
          productId: productId,
          name: 'عصير',
          price: 60,
          quantity: 1,
          subtotal: 60,
        ),
      ],
    );
    await repository.addExpense(Expense(name: 'كهرباء', amount: 10));

    await pumpAppOnPhone(tester, repository);

    await openReports(tester);

    // صافي الربح = المبيعات النقدية 60 - المصروفات 10 = 50 (الآجل 40 غير محسوب).
    expect(find.text('50 ج.م'), findsWidgets);

    // المديونية (الآجل) ظاهرة كبطاقة منفصلة.
    expect(find.text('مديونية اليوم'), findsOneWidget);
    expect(find.text('إجمالي الآجل'), findsOneWidget);
    expect(find.text('40 ج.م'), findsWidgets);
    expect(find.text('ديون العملاء'), findsOneWidget);
  });

  testWidgets('التقارير: الأيام السابقة تُعرض مجمّعة حسب الشهر ويفتح كل يوم تقريره منفصلًا', (tester) async {
    final repository = FakeStoreRepository();
    final product = Product(name: 'مياه', price: 10, stock: 50);
    final productId = await repository.addProduct(product);
    final pastDay = DateTime.now().subtract(const Duration(days: 3));

    await repository.createSale(
      sale: Sale(
        total: 200,
        itemsCount: 2,
        cashierName: testUsername,
        createdAt: pastDay,
      ),
      items: [
        SaleItem(
          saleId: 0,
          productId: productId,
          name: 'مياه',
          price: 100,
          quantity: 2,
          subtotal: 200,
        ),
      ],
    );
    await repository.addExpense(
      Expense(name: 'إيجار', amount: 50, createdAt: pastDay),
    );

    await pumpAppOnPhone(tester, repository);

    await openReports(tester);

    // جدول الأيام السابقة موجود أسفل التقرير، مع شهر منفصل باسم الشهر.
    await tester.scrollUntilVisible(find.text('الأيام السابقة'), 300,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('الأيام السابقة'), findsOneWidget);
    final monthHeader = '${AppFormatters.arabicMonth(pastDay)} ${pastDay.year}';
    await tester.scrollUntilVisible(find.text(monthHeader), 300,
        scrollable: find.byType(Scrollable).first);
    expect(find.text(monthHeader), findsOneWidget);

    // فتح تقرير اليوم المنفصل يعرض فواتير اليوم ومصروفاته.
    final weekday = AppFormatters.arabicWeekday(pastDay);
    await tester.scrollUntilVisible(find.text(weekday).first, 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text(weekday).first);
    await tester.pumpAndSettle();

    expect(find.text('فواتير اليوم'), findsOneWidget);
    expect(find.text('مصروفات اليوم'), findsOneWidget);
    expect(find.text('فاتورة #1'), findsOneWidget);
    expect(find.text('إيجار'), findsOneWidget);
    expect(find.text('200 ج.م'), findsWidgets);
    expect(find.text('50 ج.م'), findsWidgets);
  });
}

