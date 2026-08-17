import 'package:flutter_test/flutter_test.dart';
import 'package:omni_order/domain/models/product.dart';
import 'package:omni_order/features/customers/presentation/customers_cubit.dart';
import 'package:omni_order/features/products/presentation/products_cubit.dart';
import 'package:omni_order/features/sales/presentation/cart_cubit.dart';
import 'package:omni_order/features/sales/presentation/sales_cubit.dart';

import 'fakes/fake_store_repository.dart';

/// اختبار ضريبة القيمة المضافة: تُحسب من الصافي وتُسجَّل على الفاتورة
/// والسعر النهائي يبقى شاملاً للضريبة (لا يتغير إجمالي المبيعات).
void main() {
  test('الضريبة تُحسب من الصافي وتُسجَّل على الفاتورة (شاملة في السعر)', () async {
    final repository = FakeStoreRepository();
    await repository.addProduct(
      Product(name: 'عصير', price: 100, stock: 10),
    );

    final products = ProductsCubit(repository)..init();
    final customers = CustomersCubit(repository)..init();
    final sales = SalesCubit(repository)..init();
    final cart = CartCubit(
      repository: repository,
      productsCubit: products,
      customersCubit: customers,
      salesCubit: sales,
    );

    final product = (await repository.getProducts()).first;
    expect(cart.addToCart(product, 2), isNull); // الصافي قبل الضريبة = 200

    final sale = await cart.completeSale(taxRate: 14);

    expect(sale, isNotNull);
    // إجمالي الفاتورة لا يتغير (السعر شامل الضريبة).
    expect(sale!.total, 200);
    expect(sale.taxRate, 14);
    // قيمة الضريبة = 200 × 14/114 ≈ 24.56
    expect((sale.taxAmount * 100).round(), 2456);
    // الفاتورة محفوظة في المستودع بنفس قيم الضريبة.
    expect(repository.sales.single.taxRate, 14);
    expect((repository.sales.single.taxAmount * 100).round(), 2456);
  });

  test('بدون ضريبة: taxAmount يساوي صفرًا', () async {
    final repository = FakeStoreRepository();
    await repository.addProduct(Product(name: 'ماء', price: 10, stock: 5));

    final products = ProductsCubit(repository)..init();
    final customers = CustomersCubit(repository)..init();
    final sales = SalesCubit(repository)..init();
    final cart = CartCubit(
      repository: repository,
      productsCubit: products,
      customersCubit: customers,
      salesCubit: sales,
    );

    final product = (await repository.getProducts()).first;
    cart.addToCart(product, 1);

    final sale = await cart.completeSale(taxRate: 0);
    expect(sale, isNotNull);
    expect(sale!.taxAmount, 0);
    expect(sale.taxRate, 0);
    expect(sale.total, 10);
  });
}
