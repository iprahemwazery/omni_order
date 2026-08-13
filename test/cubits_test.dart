import 'package:flutter_test/flutter_test.dart';
import 'package:omni_order/domain/models/customer.dart';
import 'package:omni_order/domain/models/product.dart';
import 'package:omni_order/features/customers/presentation/customers_cubit.dart';
import 'package:omni_order/features/products/presentation/products_cubit.dart';
import 'package:omni_order/features/sales/presentation/cart_cubit.dart';
import 'package:omni_order/features/sales/presentation/sales_cubit.dart';

import 'fakes/fake_store_repository.dart';

void main() {
  group('ProductsCubit - إدارة الأصناف', () {
    late FakeStoreRepository repository;
    late ProductsCubit products;

    setUp(() async {
      repository = FakeStoreRepository();
      products = ProductsCubit(repository);
      await products.init();
    });

    test('إضافة صنف يظهر في القائمة ويخزّن', () async {
      final error = await products.addProduct(
        name: 'أرز',
        price: 25,
        stock: 40,
        unit: 'كيلو',
      );
      expect(error, isNull);
      expect(products.state.products.length, 1);
      expect(products.state.products.first.name, 'أرز');
      expect(repository.products.length, 1);
    });

    test('لا يمكن إضافة صنف بدون سعر', () async {
      final error = await products.addProduct(
        name: 'زيت',
        price: 0,
        stock: 5,
        unit: 'قطعة',
      );
      expect(error, isNotNull);
      expect(products.state.products, isEmpty);
    });
  });

  group('CartCubit - السلة والبيع', () {
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

    Product product({double price = 10, double stock = 10, String name = 'عصير'}) {
      return Product(name: name, price: price, stock: stock);
    }

    test('إضافة للسلة تحسب الإجمالي', () {
      final p = product(price: 10, stock: 100);
      final error = cart.addToCart(p, 3);
      expect(error, isNull);
      expect(cart.state.lines.length, 1);
      expect(cart.state.total, 30);
      expect(cart.state.totalQuantity, 3);
    });

    test('لا يمكن بيع أكثر من المتاح', () {
      final p = product(price: 10, stock: 2);
      final error = cart.addToCart(p, 5);
      expect(error, isNotNull);
      expect(cart.state.isEmpty, isTrue);
    });

    test('إتمام البيع يخصم المخزون ويحفظ الفاتورة', () async {
      await products.addProduct(name: 'عصير', price: 10, stock: 10, unit: 'قطعة');
      await products.addProduct(name: 'خبز', price: 5, stock: 20, unit: 'قطعة');

      final juice = products.state.products.firstWhere((p) => p.name == 'عصير');
      final bread = products.state.products.firstWhere((p) => p.name == 'خبز');

      cart.addToCart(juice, 2);
      cart.addToCart(bread, 4);

      final sale = await cart.completeSale();

      expect(sale, isNotNull);
      expect(sale!.total, 40);
      expect(sale.itemsCount, 2);
      expect(repository.sales.length, 1);
      expect(cart.state.isEmpty, isTrue);

      expect(repository.products.firstWhere((p) => p.name == 'عصير').stock, 8);
      expect(repository.products.firstWhere((p) => p.name == 'خبز').stock, 16);

      // المخزون داخل الـ Cubit تزامن بعد البيع.
      expect(products.state.productById(juice.id)!.stock, 8);
      expect(products.state.productById(bread.id)!.stock, 16);

      final items = await repository.getSaleItems(sale.id!);
      expect(items.length, 2);

      // سجل المبيعات تزامن بعد البيع (الرئيسية والتقارير والسجل).
      expect(sales.state.sales.length, 1);
      expect(sales.state.sales.first.total, 40);
      expect(sales.state.totalRevenue, 40);
      expect(sales.state.revenueOn(DateTime.now()), 40);
      // بيع نقدي يُعدّ ربحًا محققًا وليس مديونية.
      expect(sales.state.totalCashRevenue, 40);
      expect(sales.state.totalDeferred, 0);
    });

    test('الكميات داخل السلة تخصم من المتاح', () {
      final p = product(price: 10, stock: 5);
      cart.addToCart(p, 3);
      expect(cart.state.availableStockOf(p), 2);
      final error = cart.addToCart(p, 3);
      expect(error, isNotNull);
    });

    test('البيع الآجل يحدّث مديونية العميل', () async {
      await products.addProduct(name: 'شاي', price: 10, stock: 20, unit: 'قطعة');
      final product = products.state.products.first;
      final customerId = await repository.addCustomer(
        Customer(name: 'أحمد', phone: '012'),
      );
      await customers.refresh();

      cart.addToCart(product, 1);
      cart.selectCustomer(customers.state.customerById(customerId));
      cart.setPaymentMethod('آجل');
      final sale = await cart.completeSale();

      expect(sale, isNotNull);
      expect(repository.customers.first.balance, 10);

      // البيع الآجل مديونية وليس ربحًا محققًا.
      expect(sales.state.totalCashRevenue, 0);
      expect(sales.state.totalDeferred, 10);
      expect(sales.state.totalRevenue, 10);
    });
  });
}
