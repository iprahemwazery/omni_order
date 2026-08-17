import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_order/domain/models/product.dart';
import 'package:omni_order/features/customers/presentation/customers_cubit.dart';
import 'package:omni_order/features/products/presentation/products_cubit.dart';
import 'package:omni_order/features/sales/presentation/cart_cubit.dart';
import 'package:omni_order/features/sales/presentation/sales_cubit.dart';

import 'fakes/fake_store_repository.dart';
import 'test_helpers.dart';

/// اختبارات المرحلة الثانية: الفواتير المعلقة (Hold) وتقرير الوردية (Z-Report).
void main() {
  group('CartCubit - تعليق واسترجاع السلة', () {
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

    test('holdCart يحفظ السلة ويُفرّغها، والاسترجاع يعيد البنود ويحذف المعلقة',
        () async {
      final productId = await repository.addProduct(
        Product(name: 'شاي', price: 10, stock: 5),
      );
      await products.refresh();
      final product = repository.products.firstWhere((p) => p.id == productId);
      cart.addToCart(product, 2);

      final id = await cart.holdCart(cashierName: 'admin');
      expect(id, greaterThan(0));
      expect(cart.state.isEmpty, isTrue);
      expect(repository.heldCarts.length, 1);
      expect(repository.heldCartItems[id]!.length, 1);
      expect(repository.heldCarts.first.total, 20);

      final message = await cart.restoreHeldCart(repository.heldCarts.first);
      expect(message, isNull);
      expect(cart.state.totalQuantity, 2);
      expect(cart.state.lines.first.product.id, productId);
      expect(repository.heldCarts, isEmpty);
    });

    test('استرجاع يتجاهل الأصناف النافدة ويُرجع تحذيرًا', () async {
      final productId = await repository.addProduct(
        Product(name: 'لبن', price: 10, stock: 3),
      );
      await products.refresh();
      final product = repository.products.firstWhere((p) => p.id == productId);
      cart.addToCart(product, 2);
      final id = await cart.holdCart(cashierName: 'admin');
      expect(id, greaterThan(0));

      // الصنف نَفد قبل الاسترجاع.
      final index = repository.products.indexWhere((p) => p.id == productId);
      repository.products[index] =
          repository.products[index].copyWith(stock: 0);
      await products.refresh();

      final message = await cart.restoreHeldCart(repository.heldCarts.first);
      expect(message, isNotNull);
      expect(message, contains('لبن'));
      expect(cart.state.isEmpty, isTrue);
      // فشل الاسترجاع بالكامل → تبقى الفاتورة معلقة للمحاولة لاحقًا.
      expect(repository.heldCarts.length, 1);
    });
  });

  group('واجهة تعليق الفواتير', () {
    Future<void> pumpOnPhone(WidgetTester tester, FakeStoreRepository repo) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await pumpApp(tester, repo);
    }

    testWidgets('تعليق السلة ثم استرجاعها من قائمة المعلقة', (tester) async {
      final repository = FakeStoreRepository();
      await repository.addProduct(Product(name: 'عصير', price: 10, stock: 20));
      await pumpOnPhone(tester, repository);

      await tester.tap(find.text('بيع جديد'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('عصير'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('إضافة للسلة'));
      await tester.pumpAndSettle();

      // تعليق من السلة.
      await tester.tap(find.text('عرض السلة'));
      await tester.pumpAndSettle();
      expect(find.text('تعليق'), findsOneWidget);
      await tester.tap(find.text('تعليق'));
      await tester.pumpAndSettle();

      // السلة فُرضت والمعلقة حُفظت في المستودع.
      expect(find.text('عرض السلة'), findsNothing);
      expect(repository.heldCarts.length, 1);

      // فتح قائمة الفواتير المعلقة من شريط الأعلى.
      await tester.tap(find.byIcon(Icons.pause_circle_outline));
      await tester.pumpAndSettle();
      expect(find.text('الفواتير المعلقة'), findsOneWidget);
      expect(find.text('استرجاع'), findsOneWidget);

      // الاسترجاع يعيدنا لشاشة البيع والسلة ممتلئة.
      await tester.tap(find.text('استرجاع'));
      await tester.pumpAndSettle();
      expect(find.text('المبيعات'), findsOneWidget);
      expect(repository.heldCarts, isEmpty);
      // ننتظر اختفاء SnackBar حتى لا يحجب شريط السلة السفلي.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.shopping_cart_outlined).first);
      await tester.pumpAndSettle();
      expect(find.text('عصير'), findsWidgets);
    });

    testWidgets('حذف فاتورة معلقة من القائمة', (tester) async {
      final repository = FakeStoreRepository();
      await repository.addProduct(Product(name: 'قهوة', price: 5, stock: 10));
      await pumpOnPhone(tester, repository);

      await tester.tap(find.text('بيع جديد'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('قهوة'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('إضافة للسلة'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('عرض السلة'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تعليق'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.pause_circle_outline));
      await tester.pumpAndSettle();
      expect(repository.heldCarts.length, 1);

      await tester.tap(find.text('حذف'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'حذف'));
      await tester.pumpAndSettle();

      expect(repository.heldCarts, isEmpty);
      expect(find.text('لا توجد فواتير معلقة'), findsOneWidget);
    });
  });

  group('تقرير الوردية (Z-Report)', () {
    testWidgets('بدء وردية وإغلاقها من شاشة البيع', (tester) async {
      final repository = FakeStoreRepository();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await pumpApp(tester, repository);

      await tester.tap(find.text('بيع جديد'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.event_note_outlined));
      await tester.pumpAndSettle();
      expect(find.text('تقرير الوردية (Z-Report)'), findsOneWidget);

      // لا وردية بعد → زر بدء.
      expect(find.text('بدء الوردية الآن'), findsOneWidget);
      await tester.tap(find.text('بدء الوردية الآن'));
      await tester.pumpAndSettle();

      expect(find.text('إجمالي مبيعات الوردية'), findsOneWidget);
      expect(find.text('وردية مفتوحة'), findsOneWidget);

      // إغلاق الوردية مع التأكيد.
      await tester.tap(find.text('إغلاق الوردية'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(FilledButton, 'إغلاق الوردية'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('مغلقة'), findsOneWidget);
      expect(find.text('تم إغلاق الوردية بنجاح.'), findsOneWidget);
      expect(repository.shifts.single.closedAt, isNotNull);
    });
  });
}
