import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_order/domain/models/customer.dart';
import 'package:omni_order/domain/models/product.dart';

import 'fakes/fake_store_repository.dart';
import 'test_helpers.dart';

/// اختبار تدفق إتمام البيع: خصم + بيع آجل + تحديث مديونية العميل.
void main() {
  Future<void> pumpAppOnPhone(WidgetTester tester, FakeStoreRepository repo) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await pumpApp(tester, repo);
  }

  testWidgets('إتمام بيع آجل مع خصم نسبة يحدّث الفاتورة ومديونية العميل', (tester) async {
    final repository = FakeStoreRepository();
    await repository.addProduct(Product(name: 'شاي', price: 10, stock: 20));
    final customerId = await repository.addCustomer(Customer(name: 'أحمد', phone: '012'));

    await pumpAppOnPhone(tester, repository);

    // الدخول لشاشة البيع وإضافة الصنف بسرعة (زر +1)
    await tester.tap(find.text('بيع جديد'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('10 ج.م'), findsWidgets);
    expect(find.text('عرض السلة'), findsOneWidget);

    // فتح السلة ثم شاشة تأكيد البيع
    await tester.tap(find.text('عرض السلة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إتمام البيع'));
    await tester.pumpAndSettle();

    // اختيار بيع آجل + عميل
    await tester.tap(find.text('آجل'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<int?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('أحمد').last);
    await tester.pumpAndSettle();

    // خصم 10%
    await tester.tap(find.text('نسبة %'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byWidgetPredicate(
        (w) => w is TextField && (w.decoration?.hintText ?? '') == 'مثال: 10',
      ),
      '10',
    );
    await tester.pumpAndSettle();
    expect(find.text('9 ج.م'), findsOneWidget);

    // تأكيد البيع والانتقال للفاتورة
    await tester.tap(find.text('تأكيد البيع'));
    await tester.pumpAndSettle();
    expect(find.text('الفاتورة'), findsOneWidget);
    expect(find.text('أحمد'), findsOneWidget);
    expect(find.text('آجل'), findsOneWidget);

    // التحقق من بيانات الفاتورة والعميل
    expect(repository.sales.length, 1);
    final sale = repository.sales.first;
    expect(sale.total, 9);
    expect(sale.discount, 1);
    expect(sale.paymentMethod, 'آجل');
    expect(sale.customerId, customerId);

    final customer = repository.customers.firstWhere((c) => c.id == customerId);
    expect(customer.balance, 9);
    expect(sale.cashierName, testUsername);
    expect(find.text(testUsername), findsOneWidget);
  });

  testWidgets('إضافة عميل جديد من شاشة تأكيد البيع وتحديده للبيع الآجل', (tester) async {
    final repository = FakeStoreRepository();
    await repository.addProduct(Product(name: 'بن', price: 8, stock: 20));

    await pumpAppOnPhone(tester, repository);

    // الدخول لشاشة البيع وإضافة الصنف
    await tester.tap(find.text('بيع جديد'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.text('عرض السلة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إتمام البيع'));
    await tester.pumpAndSettle();

    // اختيار بيع آجل ثم إضافة عميل جديد من داخل الشاشة
    await tester.tap(find.text('آجل'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إضافة عميل جديد'));
    await tester.pumpAndSettle();
    expect(find.text('إضافة عميل'), findsOneWidget);

    await tester.enterText(
      find.byWidgetPredicate(
        (w) => w is TextField && (w.decoration?.labelText ?? '') == 'اسم العميل *',
      ),
      'سارة',
    );
    await tester.tap(find.text('إضافة'));
    await tester.pumpAndSettle();

    // العميل الجديد اختير تلقائيًا
    expect(find.text('سارة'), findsOneWidget);

    // تأكيد البيع الآجل وربطه بالعميل الجديد
    await tester.tap(find.text('تأكيد البيع'));
    await tester.pumpAndSettle();
    expect(find.text('الفاتورة'), findsOneWidget);

    expect(repository.sales.length, 1);
    final sale = repository.sales.first;
    expect(sale.paymentMethod, 'آجل');
    expect(sale.total, 8);

    final added = repository.customers.firstWhere((c) => c.name == 'سارة');
    expect(sale.customerId, added.id);
    expect(added.balance, 8);
  });
}
