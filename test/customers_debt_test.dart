import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_order/domain/models/customer.dart';
import 'package:omni_order/domain/models/product.dart';
import 'package:omni_order/domain/models/sale.dart';
import 'package:omni_order/domain/models/sale_item.dart';

import 'fakes/fake_store_repository.dart';
import 'test_helpers.dart';

/// اختبار شاشة تفاصيل مديونية العميل.
void main() {
  Future<void> pumpAppOnPhone(WidgetTester tester, FakeStoreRepository repo) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await pumpApp(tester, repo);
  }

  testWidgets('الضغط على عميل عليه دين يفتح تفاصيل الدين وفواتيره الآجلة', (tester) async {
    final repository = FakeStoreRepository();
    final productId = await repository.addProduct(
      Product(name: 'سكر', price: 20, stock: 30),
    );
    final customerId = await repository.addCustomer(
      Customer(name: 'محمود', phone: '010'),
    );
    await repository.createSale(
      sale: Sale(total: 40, itemsCount: 2, paymentMethod: 'آجل', customerId: customerId),
      items: [
        SaleItem(
          saleId: 0,
          productId: productId,
          name: 'سكر',
          price: 20,
          quantity: 2,
          subtotal: 40,
        ),
      ],
    );
    await repository.updateCustomer(
      repository.customers.firstWhere((c) => c.id == customerId).copyWith(balance: 40),
    );

    await pumpAppOnPhone(tester, repository);

    // فتح شاشة العملاء والضغط على العميل
    await tester.tap(find.text('العملاء'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('محمود'));
    await tester.pumpAndSettle();

    // تفاصيل الدين ظهرت
    expect(find.text('الفواتير الآجلة'), findsOneWidget);
    expect(find.text('فاتورة #1'), findsOneWidget);
    expect(find.text('تسجيل سداد'), findsOneWidget);

    // قيم الملخص: إجمالي الفواتير 40 والمتبقي 40 (بلا سداد بعد)
    expect(find.text('40 ج.م'), findsWidgets);

    // فتح الفاتورة من التفاصيل
    await tester.tap(find.text('فاتورة #1'));
    await tester.pumpAndSettle();
    expect(find.text('الفاتورة'), findsOneWidget);
    expect(find.text('محمود'), findsWidgets);
  });

  testWidgets('تسجيل سداد من شاشة تفاصيل الدين يقلّل المتبقي', (tester) async {
    final repository = FakeStoreRepository();
    final productId = await repository.addProduct(
      Product(name: 'سكر', price: 20, stock: 30),
    );
    final customerId = await repository.addCustomer(
      Customer(name: 'محمود', phone: '010'),
    );
    await repository.createSale(
      sale: Sale(total: 40, itemsCount: 2, paymentMethod: 'آجل', customerId: customerId),
      items: [
        SaleItem(
          saleId: 0,
          productId: productId,
          name: 'سكر',
          price: 20,
          quantity: 2,
          subtotal: 40,
        ),
      ],
    );
    await repository.updateCustomer(
      repository.customers.firstWhere((c) => c.id == customerId).copyWith(balance: 40),
    );

    await pumpAppOnPhone(tester, repository);

    await tester.tap(find.text('العملاء'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('محمود'));
    await tester.pumpAndSettle();

    // تسجيل سداد 15
    await tester.tap(find.text('تسجيل سداد'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byWidgetPredicate(
        (w) => w is TextField && (w.decoration?.hintText ?? '') == 'المبلغ المسدد',
      ),
      '15',
    );
    await tester.tap(find.text('تسجيل'));
    await tester.pumpAndSettle();

    // المتبقي أصبح 25
    final customer = repository.customers.firstWhere((c) => c.id == customerId);
    expect(customer.balance, 25);
    expect(find.text('25 ج.م'), findsWidgets);
  });
}
