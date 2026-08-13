import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_order/core/utils/password_utils.dart';
import 'package:omni_order/data/services/auth_service.dart';
import 'package:omni_order/domain/models/admin.dart';
import 'package:omni_order/features/auth/presentation/auth_cubit.dart';
import 'package:omni_order/features/auth/presentation/auth_state.dart';
import 'package:omni_order/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'fakes/fake_store_repository.dart';

/// خدمة ترخيص تجريبية تتحكم في النتيجة يدويًا (بدون شبكة).
class FakeAuthService extends AuthService {
  FakeAuthService({required this.ready, this.error});

  final bool ready;
  final String? error;

  bool signedOut = false;
  String? lastEmail;
  String? lastPassword;

  @override
  bool get isReady => ready;

  @override
  Future<String?> loginSingleDevice({
    required String email,
    required String password,
  }) async {
    lastEmail = email;
    lastPassword = password;
    return error;
  }

  @override
  Future<void> logout() async {
    signedOut = true;
  }
}

/// خدمة تُرجع جلسة محفوظة (توكن) كما لو كان المستخدم سجّل الدخول سابقًا.
class FakeAuthServiceWithSession extends AuthService {
  FakeAuthServiceWithSession({required this.session});

  final Session? session;

  @override
  bool get isReady => true;

  @override
  Session? get currentSession => session;
}

/// اختبار ربط تسجيل الدخول بـ Supabase والترخيص وصلاحيات النظام المحلية.
void main() {
  group('AuthCubit - تسجيل الدخول عبر Supabase', () {
    test('نجاح الترخيص ينتقل لاختيار الدور دون إنشاء أدمن بعد', () async {
      final repo = FakeStoreRepository();
      final auth = FakeAuthService(ready: true);
      final cubit = AuthCubit(repo, authService: auth);

      final error = await cubit.login('owner@store.com', 'pass123');

      expect(error, isNull);
      expect(auth.lastEmail, 'owner@store.com');
      expect(auth.lastPassword, 'pass123');
      expect(cubit.state.status, AuthStatus.chooseRole);
      expect(cubit.state.pendingEmail, 'owner@store.com');
      expect(cubit.state.admin, isNull);
      expect(repo.admins, isEmpty);
    });

    test('الدخول كأدمن بدون أدمن موجود ينشئ أدمنًا أساسيًا (زي الإعداد القديم)',
        () async {
      final repo = FakeStoreRepository();
      final auth = FakeAuthService(ready: true);
      final cubit = AuthCubit(repo, authService: auth);

      await cubit.login('owner@store.com', 'pass');
      expect(await cubit.needsAdminCreation(), isTrue);

      final error = await cubit.loginAsAdmin(
        username: 'owner',
        password: '123456',
        confirmPassword: '123456',
      );

      expect(error, isNull);
      expect(cubit.state.status, AuthStatus.authenticated);
      expect(cubit.state.admin?.username, 'owner');
      expect(cubit.state.admin?.isSuperAdmin, isTrue);
      expect(repo.admins.length, 1);
      expect(repo.admins.first.username, 'owner');
      expect(repo.admins.first.isSuperAdmin, isTrue);
    });

    test('إعادة الدخول كأدمن يتحقق من البيانات ولا ينشئ أدمنًا جديدًا',
        () async {
      final repo = FakeStoreRepository();
      final auth = FakeAuthService(ready: true);
      final cubit = AuthCubit(repo, authService: auth);

      await cubit.login('owner@store.com', 'pass');
      await cubit.loginAsAdmin(
        username: 'owner',
        password: '123456',
        confirmPassword: '123456',
      );
      await cubit.logout();
      expect(repo.admins.length, 1);

      await cubit.login('owner@store.com', 'pass');
      final error = await cubit.loginAsAdmin(
        username: 'owner',
        password: '123456',
      );

      expect(error, isNull);
      expect(cubit.state.admin?.username, 'owner');
      expect(repo.admins.length, 1);
    });

    test('الدخول كأدمن بكلمة سر خاطئة يرجّع خطأ', () async {
      final repo = FakeStoreRepository();
      final auth = FakeAuthService(ready: true);
      final cubit = AuthCubit(repo, authService: auth);

      await cubit.login('owner@store.com', 'pass');
      await cubit.loginAsAdmin(
        username: 'owner',
        password: '123456',
        confirmPassword: '123456',
      );
      await cubit.logout();

      await cubit.login('owner@store.com', 'pass');
      final error = await cubit.loginAsAdmin(
        username: 'owner',
        password: 'wrong',
      );

      expect(error, 'اسم المستخدم أو كلمة السر غير صحيحة.');
      expect(cubit.state.status, AuthStatus.chooseRole);
    });

    test('لا يُنشأ أدمن جديد بعد وجود أدمن (اسم مستخدم غير موجود)', () async {
      final repo = FakeStoreRepository();
      final auth = FakeAuthService(ready: true);
      final cubit = AuthCubit(repo, authService: auth);

      await cubit.login('owner@store.com', 'pass');
      await cubit.loginAsAdmin(
        username: 'owner',
        password: '123456',
        confirmPassword: '123456',
      );
      await cubit.logout();

      await cubit.login('owner@store.com', 'pass');
      final error = await cubit.loginAsAdmin(
        username: 'other',
        password: 'x',
        confirmPassword: 'x',
      );

      expect(error, 'اسم المستخدم أو كلمة السر غير صحيحة.');
      expect(repo.admins.length, 1);
    });

    test('إنشاء الأدمن بمصادقة كلمة سر مختلفة يرجّع خطأ', () async {
      final repo = FakeStoreRepository();
      final auth = FakeAuthService(ready: true);
      final cubit = AuthCubit(repo, authService: auth);

      await cubit.login('owner@store.com', 'pass');
      final error = await cubit.loginAsAdmin(
        username: 'owner',
        password: '123456',
        confirmPassword: '654321',
      );

      expect(error, 'كلمتا السر غير متطابقتين.');
      expect(repo.admins, isEmpty);
    });

    test('الدخول ككاشير ينشئ أدمنًا بدور كاشير', () async {
      final repo = FakeStoreRepository();
      final auth = FakeAuthService(ready: true);
      final cubit = AuthCubit(repo, authService: auth);

      await cubit.login('cashier@store.com', 'pass');
      final error = await cubit.loginAsCashier();

      expect(error, isNull);
      expect(cubit.state.status, AuthStatus.authenticated);
      expect(cubit.state.admin?.role, UserRole.cashier);
      expect(cubit.state.admin?.has(UserPermission.makeSales), isTrue);
      expect(cubit.state.admin?.has(UserPermission.manageProducts), isFalse);
    });

    test('الدخول ككاشير بنفس الإيميل يحدّث دور نفس الأدمن دون تكرار', () async {
      final repo = FakeStoreRepository();
      final auth = FakeAuthService(ready: true);
      final cubit = AuthCubit(repo, authService: auth);

      await cubit.login('cashier@store.com', 'pass');
      await cubit.loginAsCashier();
      await cubit.logout();

      await cubit.login('cashier@store.com', 'pass');
      await cubit.loginAsCashier();

      expect(repo.admins.length, 1);
      expect(cubit.state.admin?.id, repo.admins.first.id);
      expect(repo.admins.first.role, UserRole.cashier);
    });

    test('فشل الترخيص يرجّع رسالة الخطأ ولا ينتقل لاختيار الدور', () async {
      final repo = FakeStoreRepository();
      final auth = FakeAuthService(
        ready: true,
        error: 'خطأ في جدول الترخيص: table not found',
      );
      final cubit = AuthCubit(repo, authService: auth);
      await cubit.init();

      final error = await cubit.login('owner@store.com', 'wrong');

      expect(error, 'خطأ في جدول الترخيص: table not found');
      expect(cubit.state.status, AuthStatus.unauthenticated);
      expect(cubit.state.admin, isNull);
      expect(cubit.state.pendingEmail, isNull);
      expect(repo.admins, isEmpty);
    });

    test('الدخول كأدمن أو ككاشير بدون جلسة دخول يرجّع خطأ', () async {
      final repo = FakeStoreRepository();
      final auth = FakeAuthService(ready: true);
      final cubit = AuthCubit(repo, authService: auth);
      await cubit.init();

      final adminError = await cubit.loginAsAdmin(
        username: 'owner',
        password: 'x',
      );
      final cashierError = await cubit.loginAsCashier();

      expect(adminError, isNotNull);
      expect(cashierError, isNotNull);
      expect(cubit.state.status, AuthStatus.unauthenticated);
    });

    test('حين يكون Supabase غير مفعّل يعود لتسجيل الدخول المحلي', () async {
      final repo = FakeStoreRepository();
      await repo.addAdmin(Admin(
        username: 'admin',
        passwordHash: PasswordUtils.hash('123456'),
        role: UserRole.superAdmin,
      ));
      final auth = FakeAuthService(ready: false);
      final cubit = AuthCubit(repo, authService: auth);

      final error = await cubit.login('admin', '123456');

      expect(error, isNull);
      expect(cubit.state.status, AuthStatus.authenticated);
      expect(cubit.state.admin?.username, 'admin');
      expect(auth.lastEmail, isNull, reason: 'لا يوجد اتصال بـ Supabase');
    });

    test('logout يسجّل الخروج من Supabase', () async {
      final repo = FakeStoreRepository();
      final auth = FakeAuthService(ready: true);
      final cubit = AuthCubit(repo, authService: auth);

      await cubit.login('owner@store.com', 'pass');
      await cubit.loginAsAdmin(
        username: 'owner',
        password: '123456',
        confirmPassword: '123456',
      );
      await cubit.logout();

      expect(auth.signedOut, isTrue);
      expect(cubit.state.status, AuthStatus.unauthenticated);
    });

    test('عند تفعيل Supabase تُعرض شاشة الدخول بدل الإعداد الأول', () async {
      final repo = FakeStoreRepository(); // لا يوجد أي أدمن محلي
      final auth = FakeAuthService(ready: true);
      final cubit = AuthCubit(repo, authService: auth);

      await cubit.init();

      expect(cubit.state.status, AuthStatus.unauthenticated);
    });

    test('عند عدم تفعيل Supabase وعدم وجود أدمن -> شاشة الإعداد الأول', () async {
      final repo = FakeStoreRepository();
      final auth = FakeAuthService(ready: false);
      final cubit = AuthCubit(repo, authService: auth);

      await cubit.init();

      expect(cubit.state.status, AuthStatus.setup);
    });
  });

  group('AuthCubit - استعادة الجلسة المحفوظة (الدخول المباشر)', () {
    Session makeSession(String email) => Session(
          accessToken: 'access-token-123',
          refreshToken: 'refresh-token-123',
          tokenType: 'bearer',
          user: User(
            id: 'user-1',
            appMetadata: const {},
            userMetadata: const {},
            aud: 'authenticated',
            email: email,
            createdAt: '2026-01-01T00:00:00.000Z',
          ),
        );

    test('عند وجود جلسة محفوظة يُفتح التطبيق مباشرة بدون شاشة الدخول',
        () async {
      final repo = FakeStoreRepository();
      await repo.addAdmin(Admin(
        username: 'owner@store.com',
        passwordHash: PasswordUtils.hash('x'),
        role: UserRole.superAdmin,
      ));
      final auth = FakeAuthServiceWithSession(
        session: makeSession('owner@store.com'),
      );
      final cubit = AuthCubit(repo, authService: auth);

      await cubit.init();

      expect(cubit.state.status, AuthStatus.authenticated);
      expect(cubit.state.admin?.username, 'owner@store.com');
      expect(cubit.state.isSuperAdmin, isTrue);
    });

    test('استعادة الجلسة تحافظ على دور المستخدم المحفوظ (كاشير)', () async {
      final repo = FakeStoreRepository();
      await repo.addAdmin(Admin(
        username: 'cashier@store.com',
        passwordHash: PasswordUtils.hash('x'),
        role: UserRole.cashier,
      ));
      final auth = FakeAuthServiceWithSession(
        session: makeSession('cashier@store.com'),
      );
      final cubit = AuthCubit(repo, authService: auth);

      await cubit.init();

      expect(cubit.state.status, AuthStatus.authenticated);
      expect(cubit.state.admin?.role, UserRole.cashier);
      expect(cubit.state.admin?.has(UserPermission.makeSales), isTrue);
    });

    test('لو الجلسة بدون إيميل تُعرض شاشة تسجيل الدخول', () async {
      final repo = FakeStoreRepository();
      final auth = FakeAuthServiceWithSession(session: makeSession(''));
      final cubit = AuthCubit(repo, authService: auth);

      await cubit.init();

      expect(cubit.state.status, AuthStatus.unauthenticated);
    });

    test('الجلسة تُستعاد من Supabase (التوكن محفوظ محليًا)', () async {
      final repo = FakeStoreRepository();
      await repo.addAdmin(Admin(
        username: 'owner@store.com',
        passwordHash: PasswordUtils.hash('x'),
        role: UserRole.superAdmin,
      ));
      final auth = FakeAuthServiceWithSession(
        session: makeSession('owner@store.com'),
      );
      final cubit = AuthCubit(repo, authService: auth);

      await cubit.init();
      await cubit.logout();

      expect(cubit.state.status, AuthStatus.unauthenticated);
      expect(cubit.state.admin, isNull);
    });
  });

  group('تسجيل الدخول عبر Supabase - تدفق كامل (Widget)', () {
    testWidgets('دخول ناجح -> اختيار كاشير -> الرئيسية بصلاحيات الكاشير فقط',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final repo = FakeStoreRepository();
      final auth = FakeAuthService(ready: true);

      await tester.pumpWidget(
        OmniOrderApp(repository: repo, authService: auth),
      );
      await tester.pumpAndSettle();

      // لأن Supabase مفعّل: شاشة الدخول بدل الإعداد الأول.
      expect(find.text('البريد الإلكتروني'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('login_email')),
        'owner@store.com',
      );
      await tester.enterText(
        find.byKey(const Key('login_password')),
        'secret',
      );
      await tester.tap(find.byKey(const Key('login_submit')));
      await tester.pumpAndSettle();

      // شاشة اختيار الدور بعد نجاح الدخول.
      expect(find.text('اختيار الدور'), findsOneWidget);
      expect(find.text('دخول كأدمن'), findsOneWidget);
      expect(find.text('دخول ككاشير'), findsOneWidget);

      await tester.tap(find.text('دخول ككاشير'));
      await tester.pumpAndSettle();

      // الرئيسية بدور كاشير: بيع فقط وبدون إدارة المخزون.
      expect(find.text('بيع جديد'), findsOneWidget);
      expect(find.text('المخزون'), findsNothing);
      expect(repo.admins.single.role, UserRole.cashier);
    });

    testWidgets('دخول ناجح -> اختيار أدمن -> كل صلاحيات الإدارة متاحة',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final repo = FakeStoreRepository();
      final auth = FakeAuthService(ready: true);

      await tester.pumpWidget(
        OmniOrderApp(repository: repo, authService: auth),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('login_email')),
        'owner@store.com',
      );
      await tester.enterText(
        find.byKey(const Key('login_password')),
        'secret',
      );
      await tester.tap(find.byKey(const Key('login_submit')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('دخول كأدمن'));
      await tester.pumpAndSettle();

      // لأن مفيش أدمن بعد: نموذج إنشاء الأدمن الأساسي (زي الفكرة القديمة).
      expect(find.text('إنشاء الأدمن الأساسي'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('admin_username')), 'owner');
      await tester.enterText(find.byKey(const Key('admin_password')), '123456');
      await tester.enterText(find.byKey(const Key('admin_confirm')), '123456');
      await tester.tap(find.text('إنشاء ودخول'));
      await tester.pumpAndSettle();

      expect(find.text('المخزون'), findsOneWidget);
      expect(find.text('التقارير'), findsOneWidget);
      expect(find.text('العملاء'), findsOneWidget);
      expect(repo.admins.single.username, 'owner');
      expect(repo.admins.single.isSuperAdmin, isTrue);
    });

    testWidgets('الدخول كأدمن ببيانات خاطئة يعرض خطأ ولا يدخل', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final repo = FakeStoreRepository();
      final auth = FakeAuthService(ready: true);

      await tester.pumpWidget(
        OmniOrderApp(repository: repo, authService: auth),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('login_email')),
        'owner@store.com',
      );
      await tester.enterText(
        find.byKey(const Key('login_password')),
        'secret',
      );
      await tester.tap(find.byKey(const Key('login_submit')));
      await tester.pumpAndSettle();

      // إنشاء الأدمن الأول.
      await tester.tap(find.text('دخول كأدمن'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('admin_username')), 'owner');
      await tester.enterText(find.byKey(const Key('admin_password')), '123456');
      await tester.enterText(find.byKey(const Key('admin_confirm')), '123456');
      await tester.tap(find.text('إنشاء ودخول'));
      await tester.pumpAndSettle();
      expect(repo.admins.single.isSuperAdmin, isTrue);

      // تسجيل الخروج ثم محاولة الدخول بكلمة سر خاطئة.
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تسجيل الخروج'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('login_email')),
        'owner@store.com',
      );
      await tester.enterText(
        find.byKey(const Key('login_password')),
        'secret',
      );
      await tester.tap(find.byKey(const Key('login_submit')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('دخول كأدمن'));
      await tester.pumpAndSettle();

      // الآن يوجد أدمن: نموذج دخول وليس إنشاء، وبلا حقل تأكيد.
      expect(find.text('دخول الأدمن'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('admin_username')), 'owner');
      await tester.enterText(find.byKey(const Key('admin_password')), 'wrong');
      await tester.tap(find.text('دخول'));
      await tester.pumpAndSettle();

      expect(find.text('اسم المستخدم أو كلمة السر غير صحيحة.'), findsOneWidget);
      expect(find.text('المخزون'), findsNothing);
    });

    testWidgets('عند انقطاع الإنترنت تظهر رسالة واضحة في شاشة الدخول',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final repo = FakeStoreRepository();
      final auth = FakeAuthService(
        ready: true,
        error: AuthService.noInternetMessage,
      );

      await tester.pumpWidget(
        OmniOrderApp(repository: repo, authService: auth),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('login_email')),
        'owner@store.com',
      );
      await tester.enterText(
        find.byKey(const Key('login_password')),
        'secret',
      );
      await tester.tap(find.byKey(const Key('login_submit')));
      await tester.pumpAndSettle();

      expect(find.text(AuthService.noInternetMessage), findsOneWidget);
      expect(find.text('المخزون'), findsNothing);
    });
  });
}
