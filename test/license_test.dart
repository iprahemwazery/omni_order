import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_order/data/repositories/local_license_store.dart';
import 'package:omni_order/data/repositories/supabase_license_repository.dart';
import 'package:omni_order/data/services/auth_service.dart';
import 'package:omni_order/data/services/license_service.dart';
import 'package:omni_order/data/services/secure_store.dart';
import 'package:omni_order/domain/models/license.dart';
import 'package:omni_order/features/auth/presentation/auth_cubit.dart';
import 'package:omni_order/features/auth/presentation/auth_state.dart';
import 'package:omni_order/features/license/presentation/license_cubit.dart';
import 'package:omni_order/features/license/presentation/license_state.dart';
import 'package:omni_order/main.dart';

import 'fakes/fake_store_repository.dart';
import 'test_helpers.dart';

/// تخزين آمن تجريبي بالذاكرة.
class InMemorySecureStore implements SecureStore {
  final Map<String, String> data = {};

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async {
    data[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    data.remove(key);
  }
}

/// خدمة ترخيص تجريبية: تتحكم في النتيجة يدويًا (بدون شبكة).
class FakeLicenseService extends LicenseService {
  FakeLicenseService({
    this.ready = true,
    License? stored,
    this.activateResult,
  }) : _stored = stored;

  final bool ready;
  LicenseResult? activateResult;
  License? _stored;
  String? lastLicenseKey;

  @override
  bool get isReady => ready;

  @override
  Future<LicenseResult> checkOffline() async {
    final s = _stored;
    if (s == null) {
      return LicenseResult.failure(
        LicenseResultStatus.notFound,
        'لا يوجد ترخيص مفعّل على هذا الجهاز.',
      );
    }
    final now = DateTime.now();
    final expiresAt = s.expiresAt;
    if (expiresAt != null && now.isAfter(expiresAt)) {
      return LicenseResult.failure(
        LicenseResultStatus.expired,
        'لقد انتهت صلاحية هذا الترخيص.',
      );
    }
    final verifiedAt = s.verifiedAt;
    if (verifiedAt != null && now.isBefore(verifiedAt)) {
      return LicenseResult.failure(
        LicenseResultStatus.timeTampered,
        'يبدو أن تاريخ الجهاز تم تعديله.',
      );
    }
    return LicenseResult.success(s, online: false);
  }

  @override
  Future<LicenseResult> activateOrVerify(String licenseKey) async {
    lastLicenseKey = licenseKey;
    final forced = activateResult;
    if (forced != null) {
      if (forced.isSuccess && forced.license != null) {
        _stored = forced.license;
      }
      return forced;
    }
    final license = License(
      licenseKey: licenseKey,
      deviceId: 'device-1',
      activatedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 365)),
      verifiedAt: DateTime.now(),
    );
    _stored = license;
    return LicenseResult.success(license, online: true);
  }
}

/// بوابة ترخيص تجريبية: تفويض حقيقي لـ FakeLicenseService عبر AuthService.
class FakeAuthService extends AuthService {
  FakeAuthService({required this.ready, LicenseService? license})
      : super(licenseService: license);

  final bool ready;
  bool signedOut = false;

  @override
  bool get isReady => ready;

  @override
  Future<void> logout() async {
    signedOut = true;
  }
}

/// ترخيص ساري للاختبارات.
License validLicense({
  String key = 'KEY-1234',
  String deviceId = 'device-1',
}) {
  return License(
    licenseKey: key,
    deviceId: deviceId,
    activatedAt: DateTime.now().subtract(const Duration(days: 1)),
    expiresAt: DateTime.now().add(const Duration(days: 30)),
    verifiedAt: DateTime.now().subtract(const Duration(hours: 1)),
  );
}

void main() {
  group('LocalLicenseStore - وضع عدم الاتصال', () {
    test('لا يوجد تفعيل محفوظ -> notFound', () async {
      final store = LocalLicenseStore(store: InMemorySecureStore());
      final result = await store.check('device-1');
      expect(result.status, LicenseResultStatus.notFound);
      expect(result.isSuccess, isFalse);
    });

    test('تفعيل ساري على نفس الجهاز -> Offline Verified', () async {
      final store = LocalLicenseStore(store: InMemorySecureStore());
      await store.save(validLicense());
      final result = await store.check('device-1');
      expect(result.status, LicenseResultStatus.offlineVerified);
      expect(result.isSuccess, isTrue);
      expect(result.license?.licenseKey, 'KEY-1234');
    });

    test('بصمة جهاز مختلفة -> رفض (Other Device)', () async {
      final store = LocalLicenseStore(store: InMemorySecureStore());
      await store.save(validLicense(deviceId: 'device-1'));
      final result = await store.check('device-2');
      expect(result.status, LicenseResultStatus.otherDevice);
      expect(result.isSuccess, isFalse);
    });

    test('انتهت الصلاحية محليًا -> Expired', () async {
      final store = LocalLicenseStore(store: InMemorySecureStore());
      await store.save(
        validLicense().copyWith(
          expiresAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      );
      final result = await store.check('device-1');
      expect(result.status, LicenseResultStatus.expired);
      expect(result.isSuccess, isFalse);
    });

    test('ترخيص دائم (بدون انتهاء) -> صالح', () async {
      final store = LocalLicenseStore(store: InMemorySecureStore());
      await store.save(validLicense().copyWith(expiresAt: null));
      final result = await store.check('device-1');
      expect(result.isSuccess, isTrue);
    });

    test('تلاعب بالتاريخ: تاريخ الجهاز أقدم من آخر تحقق -> رفض', () async {
      final store = LocalLicenseStore(store: InMemorySecureStore());
      await store.save(
        validLicense().copyWith(
          verifiedAt: DateTime.now().add(const Duration(days: 1)),
        ),
      );
      final result = await store.check('device-1');
      expect(result.status, LicenseResultStatus.timeTampered);
      expect(result.isSuccess, isFalse);
    });

    test('clear يمسح التفعيل المحفوظ', () async {
      final store = LocalLicenseStore(store: InMemorySecureStore());
      await store.save(validLicense());
      await store.clear();
      final result = await store.check('device-1');
      expect(result.status, LicenseResultStatus.notFound);
    });
  });

  group('SupabaseLicenseRepository - التحقق عبر RPC', () {
    SupabaseLicenseRepository repo(LocalLicenseStore store,
        Future<dynamic> Function(Map<String, dynamic>) caller) {
      return SupabaseLicenseRepository(localStore: store, rpcCaller: caller);
    }

    test('تفعيل أول -> Online Verified + حفظ محلي', () async {
      final store = LocalLicenseStore(store: InMemorySecureStore());
      final now = DateTime.now();
      final repository = repo(store, (_) async => {
        'success': true,
        'code': 'activated',
        'device_id': 'device-1',
        'activated_at': now.toIso8601String(),
        'expires_at': now
            .add(const Duration(days: 365))
            .toIso8601String(),
        'server_time': now.toIso8601String(),
      });

      final result =
          await repository.activateOrVerify(licenseKey: 'KEY-1234', deviceId: 'device-1');
      expect(result.status, LicenseResultStatus.onlineVerified);
      expect(result.isSuccess, isTrue);

      // التفعيل أصبح متاحًا محليًا (وضع عدم الاتصال).
      final offline = await repository.checkStoredActivation('device-1');
      expect(offline.isSuccess, isTrue);
    });

    test('تحقق لنفس الجهاز -> Online Verified', () async {
      final store = LocalLicenseStore(store: InMemorySecureStore());
      final repository = repo(store, (_) async => {
        'success': true,
        'code': 'verified',
        'device_id': 'device-1',
        'activated_at': DateTime.now().toIso8601String(),
        'server_time': DateTime.now().toIso8601String(),
      });
      final result = await repository.activateOrVerify(
          licenseKey: 'KEY-1234', deviceId: 'device-1');
      expect(result.isSuccess, isTrue);
      expect(result.status, LicenseResultStatus.onlineVerified);
    });

    test('ترخيص معطل -> Inactive + مسح التفعيل المحلي (Kill-Switch)', () async {
      final store = LocalLicenseStore(store: InMemorySecureStore());
      await store.save(validLicense());
      final repository = repo(store, (_) async => {
        'success': false,
        'code': 'license_inactive',
        'message': 'تم تعطيل هذا الترخيص',
      });

      final result = await repository.activateOrVerify(
          licenseKey: 'KEY-1234', deviceId: 'device-1');
      expect(result.status, LicenseResultStatus.inactive);
      expect(result.message, 'تم تعطيل هذا الترخيص من قبل الإدارة.');

      final offline = await repository.checkStoredActivation('device-1');
      expect(offline.isSuccess, isFalse, reason: 'يجب مسح التفعيل المحلي');
    });

    test('مفتاح غير موجود -> Not Found', () async {
      final repository = repo(
          LocalLicenseStore(store: InMemorySecureStore()),
          (_) async => {
                'success': false,
                'code': 'license_not_found',
                'message': 'مفتاح الترخيص غير موجود',
              });
      final result = await repository.activateOrVerify(
          licenseKey: 'WRONG', deviceId: 'device-1');
      expect(result.status, LicenseResultStatus.notFound);
      expect(result.message, 'مفتاح الترخيص غير صحيح أو غير موجود.');
    });

    test('جهاز مختلف -> Other Device', () async {
      final repository = repo(
          LocalLicenseStore(store: InMemorySecureStore()),
          (_) async => {
                'success': false,
                'code': 'license_other_device',
                'message': 'هذا الترخيص مستخدم على جهاز آخر',
              });
      final result = await repository.activateOrVerify(
          licenseKey: 'KEY-1234', deviceId: 'device-2');
      expect(result.status, LicenseResultStatus.otherDevice);
      expect(result.message,
          'هذا الترخيص مستخدم على جهاز آخر ولا يمكن استخدامه هنا.');
    });

    test('لا يوجد إنترنت + تفعيل محلي صالح -> Offline Verified', () async {
      final store = LocalLicenseStore(store: InMemorySecureStore());
      await store.save(validLicense());
      final repository = repo(store, (_) async {
        throw const SocketException('Connection failed');
      });

      final result = await repository.activateOrVerify(
          licenseKey: 'KEY-1234', deviceId: 'device-1');
      expect(result.status, LicenseResultStatus.offlineVerified);
      expect(result.isSuccess, isTrue);
    });

    test('لا يوجد إنترنت + لا يوجد تفعيل محلي -> رسالة الإنترنت', () async {
      final repository = repo(
          LocalLicenseStore(store: InMemorySecureStore()),
          (_) async => throw const SocketException('Connection failed'));
      final result = await repository.activateOrVerify(
          licenseKey: 'KEY-1234', deviceId: 'device-1');
      expect(result.status, LicenseResultStatus.error);
      expect(result.message, contains('تعذر الاتصال بالإنترنت'));
    });
  });

  group('LicenseCubit - الحالات الثلاث', () {
    test('بدون تفعيل -> Not Activated (تُعرض شاشة التفعيل)', () async {
      final cubit = LicenseCubit(FakeLicenseService());
      await cubit.init();
      expect(cubit.state.stage, LicenseStage.notActivated);
      expect(cubit.state.isGranted, isFalse);
    });

    test('تفعيل محلي صالح -> Granted (Offline Verified)', () async {
      final cubit = LicenseCubit(
        FakeLicenseService(stored: validLicense()),
      );
      await cubit.init();
      expect(cubit.state.stage, LicenseStage.granted);
      expect(cubit.state.isGranted, isTrue);
    });

    test('تفعيل أونلاين ناجح -> Granted', () async {
      final service = FakeLicenseService();
      final cubit = LicenseCubit(service);
      final error = await cubit.activate('KEY-1234');
      expect(error, isNull);
      expect(cubit.state.stage, LicenseStage.granted);
      expect(service.lastLicenseKey, 'KEY-1234');
    });

    test('رفض أونلاين -> Rejected مع رسالة عربية', () async {
      final service = FakeLicenseService()
        ..activateResult = LicenseResult.failure(
          LicenseResultStatus.otherDevice,
          'هذا الترخيص مستخدم على جهاز آخر ولا يمكن استخدامه هنا.',
        );
      final cubit = LicenseCubit(service);
      final error = await cubit.activate('KEY-1234');
      expect(error, 'هذا الترخيص مستخدم على جهاز آخر ولا يمكن استخدامه هنا.');
      expect(cubit.state.stage, LicenseStage.rejected);
    });

    test('بدون Supabase (وضع التطوير) -> البوابة مفتوحة مباشرة', () async {
      final cubit = LicenseCubit(FakeLicenseService(ready: false));
      await cubit.init();
      expect(cubit.state.stage, LicenseStage.granted);
    });
  });

  group('AuthCubit - بوابة الترخيص', () {
    test('بدون تفعيل محلي -> شاشة التفعيل', () async {
      final repo = FakeStoreRepository();
      await seedSuperAdmin(repo);
      final license = FakeLicenseService();
      final cubit = AuthCubit(
        repo,
        authService: FakeAuthService(ready: true, license: license),
      );

      await cubit.init();

      expect(cubit.state.status, AuthStatus.activation);
      expect(cubit.state.admin, isNull);
    });

    test('تفعيل محلي صالح -> يتجاوز شاشة التفعيل للدخول المحلي', () async {
      final repo = FakeStoreRepository();
      await seedSuperAdmin(repo);
      final license = FakeLicenseService(stored: validLicense());
      final cubit = AuthCubit(
        repo,
        authService: FakeAuthService(ready: true, license: license),
      );

      await cubit.init();

      expect(cubit.state.status, AuthStatus.unauthenticated);
    });

    test('تفعيل محلي صالح بدون أدمن -> شاشة الإعداد الأول', () async {
      final repo = FakeStoreRepository();
      final license = FakeLicenseService(stored: validLicense());
      final cubit = AuthCubit(
        repo,
        authService: FakeAuthService(ready: true, license: license),
      );

      await cubit.init();

      expect(cubit.state.status, AuthStatus.setup);
    });

    test('تفعيل أونلاين ناجح -> onLicenseGranted يكمل الدخول المحلي', () async {
      final repo = FakeStoreRepository();
      await seedSuperAdmin(repo);
      final license = FakeLicenseService();
      final auth = FakeAuthService(ready: true, license: license);
      final cubit = AuthCubit(repo, authService: auth);
      await cubit.init();
      expect(cubit.state.status, AuthStatus.activation);

      final licenseCubit = LicenseCubit(license);
      final error = await licenseCubit.activate('KEY-1234');
      expect(error, isNull);

      final grantedError = await cubit.onLicenseGranted();
      expect(grantedError, isNull);
      expect(cubit.state.status, AuthStatus.unauthenticated);
    });

    test('رفض التفعيل -> يبقى على شاشة التفعيل مع رسالة', () async {
      final repo = FakeStoreRepository();
      await seedSuperAdmin(repo);
      final license = FakeLicenseService()
        ..activateResult = LicenseResult.failure(
          LicenseResultStatus.inactive,
          'تم تعطيل هذا الترخيص من قبل الإدارة.',
        );
      final auth = FakeAuthService(ready: true, license: license);
      final cubit = AuthCubit(repo, authService: auth);
      await cubit.init();
      expect(cubit.state.status, AuthStatus.activation);

      final licenseCubit = LicenseCubit(license);
      final error = await licenseCubit.activate('KEY-1234');
      expect(error, 'تم تعطيل هذا الترخيص من قبل الإدارة.');
      expect(licenseCubit.state.stage, LicenseStage.rejected);

      final grantedError = await cubit.onLicenseGranted();
      expect(grantedError, isNotNull);
      expect(cubit.state.status, AuthStatus.activation);
    });

    test('بدون Supabase (وضع التطوير) -> لا توجد بوابة ترخيص', () async {
      final repo = FakeStoreRepository();
      await seedSuperAdmin(repo);
      final cubit = AuthCubit(
        repo,
        authService: FakeAuthService(ready: false, license: FakeLicenseService()),
      );

      await cubit.init();

      expect(cubit.state.status, AuthStatus.unauthenticated);
    });

    test('logout لا يمسح الترخيص', () async {
      final repo = FakeStoreRepository();
      final license = FakeLicenseService(stored: validLicense());
      final auth = FakeAuthService(ready: true, license: license);
      final cubit = AuthCubit(repo, authService: auth);
      await cubit.init();
      expect(cubit.state.status, AuthStatus.setup);

      await cubit.logout();

      expect(auth.signedOut, isTrue);
      expect(cubit.state.status, AuthStatus.unauthenticated);
      // الترخيص ما زال صالحًا -> الدخول من جديد لا يتطلب مفتاحًا.
      expect(await auth.checkOfflineActivation(), isNull);
    });

    test('الدخول المحلي يعمل بعد ضمان الترخيص', () async {
      final repo = FakeStoreRepository();
      await seedSuperAdmin(repo);
      final license = FakeLicenseService(stored: validLicense());
      final cubit = AuthCubit(
        repo,
        authService: FakeAuthService(ready: true, license: license),
      );
      await cubit.init();

      final error = await cubit.login(testUsername, testPassword);

      expect(error, isNull);
      expect(cubit.state.status, AuthStatus.authenticated);
      expect(cubit.state.admin?.username, testUsername);
      expect(cubit.state.admin?.isSuperAdmin, isTrue);
    });
  });

  group('بوابة الترخيص - تدفق كامل (Widget)', () {
    testWidgets('بدون تفعيل تظهر شاشة الترخيص، وبإدخال المفتاح يُكمل للدخول',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final repo = FakeStoreRepository();
      await seedSuperAdmin(repo);
      final license = FakeLicenseService();
      final auth = FakeAuthService(ready: true, license: license);

      await tester.pumpWidget(
        OmniOrderApp(repository: repo, authService: auth, licenseService: license),
      );
      await tester.pumpAndSettle();

      // بوابة التفعيل أولاً.
      expect(find.byKey(const Key('activation_key')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('activation_key')),
        'ABC-DEF-123',
      );
      await tester.tap(find.byKey(const Key('activation_submit')));
      await tester.pumpAndSettle();

      expect(license.lastLicenseKey, 'ABC-DEF-123');
      // بعد التفعيل -> شاشة الدخول المحلي.
      expect(find.byKey(const Key('login_username')), findsOneWidget);

      // دخول محلي -> الرئيسية.
      await login(tester);
      expect(find.text('بيع جديد'), findsOneWidget);
    });

    testWidgets('فشل التفعيل يعرض رسالة واضحة ويبقى على الشاشة', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final repo = FakeStoreRepository();
      await seedSuperAdmin(repo);
      final license = FakeLicenseService()
        ..activateResult = LicenseResult.failure(
          LicenseResultStatus.otherDevice,
          'هذا الترخيص مستخدم على جهاز آخر ولا يمكن استخدامه هنا.',
        );
      final auth = FakeAuthService(ready: true, license: license);

      await tester.pumpWidget(
        OmniOrderApp(repository: repo, authService: auth, licenseService: license),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('activation_key')),
        'ABC-DEF-123',
      );
      await tester.tap(find.byKey(const Key('activation_submit')));
      await tester.pumpAndSettle();

      expect(
        find.text('هذا الترخيص مستخدم على جهاز آخر ولا يمكن استخدامه هنا.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('activation_key')), findsOneWidget);
      expect(find.byKey(const Key('login_username')), findsNothing);
    });

    testWidgets('تفعيل محلي صالح يتجاوز شاشة الترخيص مباشرة', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final repo = FakeStoreRepository();
      await seedSuperAdmin(repo);
      final license = FakeLicenseService(stored: validLicense());
      final auth = FakeAuthService(ready: true, license: license);

      await tester.pumpWidget(
        OmniOrderApp(repository: repo, authService: auth, licenseService: license),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('activation_key')), findsNothing);
      expect(find.byKey(const Key('login_username')), findsOneWidget);
    });

    testWidgets('بدون Supabase (وضع التطوير) يعمل مباشرة بدون ترخيص',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final repo = FakeStoreRepository();
      await seedSuperAdmin(repo);
      final auth = FakeAuthService(ready: false, license: FakeLicenseService());

      await tester.pumpWidget(
        OmniOrderApp(repository: repo, authService: auth),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('activation_key')), findsNothing);
      expect(find.byKey(const Key('login_username')), findsOneWidget);
    });
  });
}
