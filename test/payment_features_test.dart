import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_order/domain/models/product.dart';
import 'package:omni_order/features/customers/presentation/customers_cubit.dart';
import 'package:omni_order/features/products/presentation/products_cubit.dart';
import 'package:omni_order/features/sales/presentation/cart_cubit.dart';
import 'package:omni_order/features/sales/presentation/sales_cubit.dart';

import 'fakes/fake_store_repository.dart';
import 'test_helpers.dart';

/// اختبارات حساب الباقي والدفع المختلط (نقدي + شبكة).
void main() {
  group('CartCubit - المبلغ المدفوع والباقي', () {
    late FakeStoreRepository repository;
    late ProductsCubit products;
    late CustomersCubit customers;
    late SalesCubit sales;
    late CartCubit cart;

    setUp(() async {
      repository = FakeStoreRepository();
      products = ProductsCubit(repository);
      customers = CustomersCubit(repository);
      sales = SalesCubit(repository);
      cart = CartCubit(
        repository: repository,
        productsCubit: products,
        customersCubit: customers,
        salesCubit: sales,
      );
      await products.init();
      await customers.init();
      await sales.init();
    });

    test('المبلغ المدفوع الأكبر من الصافي يُحسب الباقي للعميل', () async {
      cart.addToCart(Product(name: 'عصير', price: 10, stock: 10), 2);
      expect(cart.state.total, 20);

      cart.setAmountTendered(50);
      expect(cart.state.amountTendered, 50);
      expect(cart.state.changeDue, 30);

      final sale = await cart.completeSale();
      expect(sale, isNotNull);
      expect(sale!.amountTendered, 50);
      expect(sale.changeDue, 30);
      expect(repository.sales.first.amountTendered, 50);
    });

    test('الدفع المختلط يحفظ الجزء المدفوع بالشبكة', () async {
      cart.addToCart(Product(name: 'شاي', price: 30, stock: 10), 1);
      expect(cart.state.total, 30);

      cart.setPaymentMethod('مختلط');
      cart.setAmountTendered(30);
      cart.setCardAmount(10); // 20 نقدًا + 10 شبكة

      final sale = await cart.completeSale();
      expect(sale, isNotNull);
      expect(sale!.paymentMethod, 'مختلط');
      expect(sale.cardAmount, 10);
      expect(sale.changeDue, 0);
    });
  });

  group('شاشة تأكيد البيع - الباقي والدفع المختلط', () {
    Future<void> openCheckout(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final repo = FakeStoreRepository();
      await repo.addProduct(Product(name: 'عصير', price: 10, stock: 20));
      await pumpApp(tester, repo);

      await tester.tap(find.text('بيع جديد'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.tap(find.text('عرض السلة'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('إتمام البيع'));
      await tester.pumpAndSettle();
    }

    testWidgets('إدخال مبلغ مدفوع أكبر يعرض الباقي للعميل ويُحفظ', (tester) async {
      await openCheckout(tester);

      await tester.enterText(
        find.byWidgetPredicate(
          (w) =>
              w is TextField &&
              (w.decoration?.hintText ?? '') == 'مثال: 100',
        ),
        '50',
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('الباقي للعميل'), findsOneWidget);

      await tester.ensureVisible(find.text('تأكيد البيع'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تأكيد البيع'));
      await tester.pumpAndSettle();

      expect(find.text('الفاتورة'), findsOneWidget);
      // 40 ج.م الباقي ظاهر على الفاتورة.
      expect(find.textContaining('الباقي للعميل'), findsOneWidget);
    });

    testWidgets('الدفع المختلط يظهر الجزء بالشبكة ويُحفظ', (tester) async {
      await openCheckout(tester);

      await tester.tap(find.text('مختلط'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byWidgetPredicate(
          (w) =>
              w is TextField &&
              (w.decoration?.hintText ?? '') == 'مثال: 30',
        ),
        '3',
      );
      await tester.pumpAndSettle();

      expect(find.text('الجزء بالشبكة'), findsOneWidget);
      expect(find.text('7 ج.م'), findsWidgets);

      await tester.ensureVisible(find.text('تأكيد البيع'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تأكيد البيع'));
      await tester.pumpAndSettle();

      expect(find.text('الفاتورة'), findsOneWidget);
    });
  });
}
