import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_order/core/utils/password_utils.dart';
import 'package:omni_order/domain/models/admin.dart';
import 'package:omni_order/main.dart';

import 'fakes/fake_store_repository.dart';

const String testUsername = 'admin';
const String testPassword = '123456';

/// يضيف أدمن أساسي جاهز للدخول في المستودع التجريبي.
Future<void> seedSuperAdmin(FakeStoreRepository repo) async {
  await repo.addAdmin(Admin(
    username: testUsername,
    passwordHash: PasswordUtils.hash(testPassword),
    role: UserRole.superAdmin,
  ));
}

/// يسجل الدخول عبر شاشة الدخول (بعد أن تظهر).
Future<void> login(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('login_email')),
    testUsername,
  );
  await tester.enterText(
    find.byKey(const Key('login_password')),
    testPassword,
  );
  await tester.tap(find.byKey(const Key('login_submit')));
  await tester.pumpAndSettle();
}

/// واجهة التطبيق كاملة (للبوم بدون دخول — يُتحكم بالدخول يدويًا).
Widget pumpAppWidget(FakeStoreRepository repo) {
  return OmniOrderApp(repository: repo);
}

/// يجهّز التطبيق كاملًا: أدمن أساسي + دخول + الشاشة الرئيسية.
Future<void> pumpApp(WidgetTester tester, FakeStoreRepository repo) async {
  await seedSuperAdmin(repo);
  await tester.pumpWidget(OmniOrderApp(repository: repo));
  await tester.pumpAndSettle();
  await login(tester);
}
