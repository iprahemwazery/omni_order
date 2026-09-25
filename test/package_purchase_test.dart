import 'package:flutter_test/flutter_test.dart';
import 'package:omni_order/domain/models/product.dart';
import 'package:omni_order/domain/models/purchase.dart';
import 'package:omni_order/domain/models/purchase_item.dart';

import 'fakes/fake_store_repository.dart';

void main() {
  test('شراء بالكرتونة يضيف المخزون بالقطع ويحدّث تكلفة القطعة', () async {
    final repository = FakeStoreRepository();
    final productId = await repository.addProduct(
      Product(
        name: 'مشروب غازي',
        price: 10,
        stock: 0,
        unit: 'قطعة',
        packageUnit: 'كرتونة',
        unitsPerPackage: 24,
      ),
    );

    // شراء 8 كراتين × 24 قطعة، سعر الكرتونة 480.
    await repository.createPurchase(
      purchase: Purchase(supplierName: 'المورد', total: 3840),
      items: [
        PurchaseItem(
          purchaseId: 0,
          productId: productId,
          name: 'مشروب غازي',
          quantity: 8,
          price: 480,
          unit: 'كرتونة',
          conversionFactor: 24,
        ),
      ],
    );

    final updated = (await repository.getProducts()).first;
    expect(updated.stock, 8 * 24); // 192 قطعة في المخزون
    expect(updated.costPrice, 20); // 480 / 24 لكل قطعة
  });

  test('الشراء بوحدة المخزون الأساسية يعمل كالسابق', () async {
    final repository = FakeStoreRepository();
    final productId = await repository.addProduct(
      Product(name: 'أرز', price: 25, stock: 5, unit: 'كيلو'),
    );

    await repository.createPurchase(
      purchase: Purchase(supplierName: 'المورد', total: 100),
      items: [
        PurchaseItem(
          purchaseId: 0,
          productId: productId,
          name: 'أرز',
          quantity: 10,
          price: 10,
        ),
      ],
    );

    final updated = (await repository.getProducts()).first;
    expect(updated.stock, 15);
    expect(updated.costPrice, 10);
  });

  test('بنود بدون منتج مرتبط لا تؤثر على المخزون', () async {
    final repository = FakeStoreRepository();
    await repository.addProduct(
      Product(name: 'صنف', price: 5, stock: 1),
    );

    await repository.createPurchase(
      purchase: Purchase(supplierName: 'المورد', total: 50),
      items: [
        PurchaseItem(purchaseId: 0, name: 'مصروف متنوع', quantity: 5, price: 10),
      ],
    );

    final updated = (await repository.getProducts()).first;
    expect(updated.stock, 1);
  });
}
