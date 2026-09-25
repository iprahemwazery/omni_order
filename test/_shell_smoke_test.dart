import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_order/core/utils/password_utils.dart';
import 'package:omni_order/domain/models/admin.dart';

import 'fakes/fake_store_repository.dart';
import 'test_helpers.dart';

void main() {
  testWidgets('smoke: الهيكل الثابت على شاشة عريضة', (tester) async {
    final repository = FakeStoreRepository();
    await repository.addAdmin(
      Admin(
        username: testUsername,
        passwordHash: PasswordUtils.hash(testPassword),
        role: UserRole.superAdmin,
      ),
    );

    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(pumpAppWidget(repository));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('login_username')),
      testUsername,
    );
    await tester.enterText(
      find.byKey(const Key('login_password')),
      testPassword,
    );
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pumpAndSettle();

    // تنقل بين أقسام من القائمة الجانبية العريضة.
    await tester.tap(find.text('الطلبات السابقة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الرئيسية'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('طلب جديد').last);
    await tester.pumpAndSettle();

    expect(find.text('محل'), findsNothing);
  });
}
