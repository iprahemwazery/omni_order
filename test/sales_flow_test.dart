import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_order/domain/models/product.dart';
import 'package:omni_order/features/sales/presentation/widgets/quantity_stepper.dart';

import 'fakes/fake_store_repository.dart';
import 'test_helpers.dart';

/// اختبار تدفق كامل: بيع صنفين + فاتورة + خصم المخزون.
void main() {
  Future<void> pumpAppOnPhone(WidgetTester tester, FakeStoreRepository repo) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await pumpApp(tester, repo);
  }

  testWidgets('بيع كامل: اختيار صنف + كميات + فاتورة + خصم مخزون', (tester) async {
    final repository = FakeStoreRepository();
    await repository.addProduct(Product(name: 'عصير', price: 10, stock: 20));
    await repository.addProduct(Product(name: 'خبز', price: 5, stock: 10));

    await pumpAppOnPhone(tester, repository);

    // الدخول لشاشة البيع
    await tester.tap(find.text('بيع جديد'));
    await tester.pumpAndSettle();
    expect(find.text('المبيعات'), findsOneWidget);

    // اختيار الصنف الأول وضبط الكمية
    await tester.tap(find.text('عصير'));
    await tester.pumpAndSettle();
    expect(find.text('إضافة للسلة'), findsOneWidget);
    await tester.tap(find.text('إضافة للسلة'));
    await tester.pumpAndSettle();

    // اختيار الصنف الثاني بكمية 2
    await tester.tap(find.text('خبز'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(QuantityStepper),
        matching: find.byIcon(Icons.add),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('إضافة للسلة'));
    await tester.pumpAndSettle();

    // شريط السلة يظهر بالمجموع 20
    expect(find.text('20 ج.م'), findsOneWidget);

    // فتح السلة
    await tester.tap(find.text('عرض السلة'));
    await tester.pumpAndSettle();
    expect(find.text('إتمام البيع'), findsOneWidget);

    // إتمام البيع (يفتح شاشة تأكيد البيع)
    await tester.tap(find.text('إتمام البيع'));
    await tester.pumpAndSettle();
    expect(find.text('تأكيد البيع'), findsOneWidget);
    expect(find.text('نقدي'), findsOneWidget);

    // تأكيد البيع
    await tester.tap(find.text('تأكيد البيع'));
    await tester.pumpAndSettle();

    // شاشة الفاتورة ظهرت
    expect(find.text('الفاتورة'), findsOneWidget);
    expect(find.text('فاتورة بيع'), findsOneWidget);
    expect(find.text('تم حفظ الفاتورة بنجاح'), findsOneWidget);

    // المخزون اتصفّى والمبيعات سُجّلت
    expect(repository.products.firstWhere((p) => p.name == 'عصير').stock, 19);
    expect(repository.products.firstWhere((p) => p.name == 'خبز').stock, 8);
    expect(repository.sales.length, 1);
    expect(repository.saleItems[repository.sales.first.id]!.length, 2);
    expect(repository.sales.first.cashierName, testUsername);

    // اسم الكاشير ظاهر على الفاتورة
    expect(find.text(testUsername), findsOneWidget);

    // فاتورة جديدة ترجع لشاشة البيع والسلة فارغة
    await tester.scrollUntilVisible(find.text('فاتورة جديدة'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('فاتورة جديدة'));
    await tester.pumpAndSettle();
    expect(find.text('المبيعات'), findsOneWidget);
    expect(find.text('عرض السلة'), findsNothing);
  });
}
