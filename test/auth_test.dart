import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_order/core/utils/password_utils.dart';
import 'package:omni_order/domain/models/admin.dart';
import 'package:omni_order/features/auth/presentation/auth_cubit.dart';
import 'package:omni_order/features/auth/presentation/auth_state.dart';

import 'fakes/fake_store_repository.dart';

void main() {
  group('الصلاحيات', () {
    test('الأدمن الأساسي يملك كل الصلاحيات', () {
      for (final permission in UserPermission.values) {
        expect(UserRole.superAdmin.has(permission), isTrue,
            reason: permission.name);
      }
    });

    test('الأدمن يملك كل شيء عدا إدارة المستخدمين', () {
      for (final permission in UserPermission.values) {
        expect(UserRole.admin.has(permission), permission != UserPermission.manageUsers);
      }
    });

    test('الكاشير يملك البيع وسجل المبيعات فقط', () {
      expect(UserRole.cashier.has(UserPermission.makeSales), isTrue);
      expect(UserRole.cashier.has(UserPermission.viewSales), isTrue);
      expect(UserRole.cashier.has(UserPermission.manageProducts), isFalse);
      expect(UserRole.cashier.has(UserPermission.manageUsers), isFalse);
      expect(UserRole.cashier.has(UserPermission.viewReports), isFalse);
    });
  });

  group('AuthCubit - الإعداد الأول', () {
    test('بدون أي مستخدم -> شاشة الإعداد', () async {
      final cubit = AuthCubit(FakeStoreRepository());
      await cubit.init();
      expect(cubit.state.status, AuthStatus.setup);
    });

    test('يوجد مستخدم -> شاشة تسجيل الدخول', () async {
      final repository = FakeStoreRepository();
      await repository.addAdmin(Admin(
        username: 'admin',
        passwordHash: PasswordUtils.hash('1234'),
        role: UserRole.superAdmin,
      ));
      final cubit = AuthCubit(repository);
      await cubit.init();
      expect(cubit.state.status, AuthStatus.unauthenticated);
    });

    test('setupOwner ينشئ أدمن أساسي ويسجل الدخول', () async {
      final repository = FakeStoreRepository();
      final cubit = AuthCubit(repository);
      await cubit.init();

      final error = await cubit.setupOwner(
        username: 'owner',
        password: '1234',
        confirmPassword: '1234',
      );
      expect(error, isNull);
      expect(cubit.state.status, AuthStatus.authenticated);
      expect(cubit.state.isSuperAdmin, isTrue);
      expect(cubit.state.admin?.username, 'owner');

      final admins = await repository.getAdmins();
      expect(admins.length, 1);
      expect(PasswordUtils.verify('1234', admins.first.passwordHash), isTrue);
    });

    test('setupOwner يرفض كلمتي سر غير متطابقتين', () async {
      final cubit = AuthCubit(FakeStoreRepository());
      await cubit.init();
      final error = await cubit.setupOwner(
        username: 'owner',
        password: '1234',
        confirmPassword: '5678',
      );
      expect(error, isNotNull);
      expect(cubit.state.status, AuthStatus.setup);
    });
  });

  group('AuthCubit - تسجيل الدخول', () {
    Future<AuthCubit> loggedOutCubit() async {
      final repository = FakeStoreRepository();
      await repository.addAdmin(Admin(
        username: 'admin',
        passwordHash: PasswordUtils.hash('1234'),
        role: UserRole.superAdmin,
      ));
      final cubit = AuthCubit(repository);
      await cubit.init();
      return cubit;
    }

    test('دخول ناجح', () async {
      final cubit = await loggedOutCubit();
      final error = await cubit.login('admin', '1234');
      expect(error, isNull);
      expect(cubit.state.status, AuthStatus.authenticated);
      expect(cubit.state.admin?.username, 'admin');
    });

    test('كلمة سر خاطئة', () async {
      final cubit = await loggedOutCubit();
      final error = await cubit.login('admin', 'wrong');
      expect(error, isNotNull);
      expect(cubit.state.status, AuthStatus.unauthenticated);
    });

    test('مستخدم غير موجود', () async {
      final cubit = await loggedOutCubit();
      final error = await cubit.login('x', '1234');
      expect(error, isNotNull);
    });

    test('logout يعود لشاشة الدخول', () async {
      final cubit = await loggedOutCubit();
      await cubit.login('admin', '1234');
      await cubit.logout();
      expect(cubit.state.status, AuthStatus.unauthenticated);
      expect(cubit.state.admin, isNull);
    });
  });

  group('AuthCubit - إدارة المستخدمين', () {
    Future<(AuthCubit, FakeStoreRepository)> superAdminContext() async {
      final repository = FakeStoreRepository();
      await repository.addAdmin(Admin(
        username: 'owner',
        passwordHash: PasswordUtils.hash('1234'),
        role: UserRole.superAdmin,
      ));
      final cubit = AuthCubit(repository);
      await cubit.init();
      await cubit.login('owner', '1234');
      return (cubit, repository);
    }

    test('createUser يضيف كاشير وأدمن', () async {
      final (cubit, repository) = await superAdminContext();

      final error = await cubit.createUser(
        username: 'cashier1',
        password: '1234',
        confirmPassword: '1234',
        role: UserRole.cashier,
      );
      expect(error, isNull);

      final admins = await repository.getAdmins();
      expect(admins.length, 2);
      expect(admins.last.role, UserRole.cashier);
      expect(cubit.state.admins.length, 2);
    });

    test('createUser يرفض اسمًا مكررًا', () async {
      final (cubit, _) = await superAdminContext();
      final error = await cubit.createUser(
        username: 'owner',
        password: '1234',
        confirmPassword: '1234',
      );
      expect(error, isNotNull);
    });

    test('غير الأدمن الأساسي لا يمكنه إضافة مستخدمين', () async {
      final repository = FakeStoreRepository();
      await repository.addAdmin(Admin(
        username: 'owner',
        passwordHash: PasswordUtils.hash('1234'),
        role: UserRole.superAdmin,
      ));
      final cubit = AuthCubit(repository);
      await cubit.init();
      await cubit.login('owner', '1234');
      await cubit.createUser(
        username: 'cashier1',
        password: '1234',
        confirmPassword: '1234',
        role: UserRole.cashier,
      );

      // تسجيل الخروج والدخول ككاشير.
      await cubit.logout();
      await cubit.login('cashier1', '1234');
      final error = await cubit.createUser(
        username: 'x',
        password: '1234',
        confirmPassword: '1234',
      );
      expect(error, isNotNull);
    });

    test('updateRole يغيّر الدور ولا يمكن تغيير دور النفس', () async {
      final (cubit, _) = await superAdminContext();
      await cubit.createUser(
        username: 'cashier1',
        password: '1234',
        confirmPassword: '1234',
        role: UserRole.cashier,
      );
      final user = cubit.state.admins.firstWhere((a) => a.username == 'cashier1');

      final error = await cubit.updateRole(user, UserRole.admin);
      expect(error, isNull);

      final updated = cubit.state.admins.firstWhere((a) => a.username == 'cashier1');
      expect(updated.role, UserRole.admin);

      final selfError = await cubit.updateRole(cubit.state.admin!, UserRole.cashier);
      expect(selfError, isNotNull);
    });

    test('لا يمكن تغيير دور آخر أدمن أساسي أو حذفه', () async {
      final repository = FakeStoreRepository();
      await repository.addAdmin(Admin(
        username: 'owner',
        passwordHash: PasswordUtils.hash('1234'),
        role: UserRole.superAdmin,
      ));
      final cubit = AuthCubit(repository);
      await cubit.init();
      await cubit.login('owner', '1234');

      final owner = cubit.state.admin!;
      final roleError = await cubit.updateRole(owner, UserRole.cashier);
      expect(roleError, isNotNull);

      final deleteError = await cubit.deleteUser(owner);
      expect(deleteError, isNotNull);
    });

    test('لا يمكن حذف النفس', () async {
      final (cubit, _) = await superAdminContext();
      final error = await cubit.deleteUser(cubit.state.admin!);
      expect(error, isNotNull);
    });

    test('deleteUser يحذف مستخدمًا عاديًا', () async {
      final (cubit, repository) = await superAdminContext();
      await cubit.createUser(
        username: 'cashier1',
        password: '1234',
        confirmPassword: '1234',
        role: UserRole.cashier,
      );
      final user = cubit.state.admins.firstWhere((a) => a.username == 'cashier1');

      final error = await cubit.deleteUser(user);
      expect(error, isNull);

      final admins = await repository.getAdmins();
      expect(admins.length, 1);
    });
  });

  group('AuthCubit - تبديل الدور', () {
    Future<AuthCubit> adminCubit() async {
      final repository = FakeStoreRepository();
      await repository.addAdmin(Admin(
        username: 'owner',
        passwordHash: PasswordUtils.hash('123456'),
        role: UserRole.superAdmin,
      ));
      final cubit = AuthCubit(repository);
      await cubit.init();
      await cubit.login('owner', '123456');
      return cubit;
    }

    test('أدمن -> كاشير مباشرة بدون كلمة سر', () async {
      final cubit = await adminCubit();
      expect(cubit.state.isSuperAdmin, isTrue);

      final error = await cubit.switchToCashier();
      expect(error, isNull);
      expect(cubit.state.admin?.role, UserRole.cashier);
      expect(cubit.state.admin?.has(UserPermission.makeSales), isTrue);
      expect(cubit.state.admin?.has(UserPermission.manageProducts), isFalse);
      expect(cubit.state.isSuperAdmin, isFalse);
    });

    test('كاشير -> أدمن يلزم اسم المستخدم وكلمة السر', () async {
      final cubit = await adminCubit();
      await cubit.switchToCashier();
      expect(cubit.state.admin?.role, UserRole.cashier);

      // كلمة سر خاطئة.
      final wrong = await cubit.switchToAdmin(
        username: 'owner',
        password: 'wrong',
      );
      expect(wrong, 'اسم المستخدم أو كلمة السر غير صحيحة.');
      expect(cubit.state.admin?.role, UserRole.cashier);

      // بيانات صحيحة.
      final error = await cubit.switchToAdmin(
        username: 'owner',
        password: '123456',
      );
      expect(error, isNull);
      expect(cubit.state.admin?.role, UserRole.superAdmin);
      expect(cubit.state.admin?.username, 'owner');
      expect(cubit.state.admin?.has(UserPermission.manageUsers), isTrue);
    });

    test('كاشير -> أدمن بلا اسم مستخدم يرجّع خطأ', () async {
      final cubit = await adminCubit();
      await cubit.switchToCashier();

      final error = await cubit.switchToAdmin(
        username: '',
        password: '123456',
      );
      expect(error, 'اكتب اسم المستخدم.');
    });

    test('أدمن -> كاشير -> أدمن يحافظ على نفس الحساب', () async {
      final cubit = await adminCubit();
      final ownerId = cubit.state.admin!.id;

      await cubit.switchToCashier();
      expect(cubit.state.admin?.id, ownerId);

      await cubit.switchToAdmin(username: 'owner', password: '123456');
      expect(cubit.state.admin?.id, ownerId);
      expect(cubit.state.admin?.role, UserRole.superAdmin);
    });

    test('التبديل لكاشير ثم تسجيل الخروج ثم الدخول يعيد للكاشير ويمكن التبديل للأدمن',
        () async {
      final cubit = await adminCubit();
      await cubit.switchToCashier();
      expect(cubit.state.admin?.role, UserRole.cashier);

      await cubit.logout();
      await cubit.login('owner', '123456');
      expect(cubit.state.admin?.role, UserRole.cashier);

      final error = await cubit.switchToAdmin(
        username: 'owner',
        password: '123456',
      );
      expect(error, isNull);
      expect(cubit.state.admin?.role, UserRole.superAdmin);
    });
  });

  group('PasswordUtils - PBKDF2', () {
    test('hash ينتج صيغة pbkdf2_sha256 مقبولة ويعمل معها verify', () {
      final stored = PasswordUtils.hash('secret');
      final parts = stored.split(r'$');
      expect(parts.length, 4);
      expect(parts[0], 'pbkdf2_sha256');
      expect(int.parse(parts[1]), PasswordUtils.iterations);

      expect(PasswordUtils.verify('secret', stored), isTrue);
      expect(PasswordUtils.verify('wrong', stored), isFalse);
      expect(PasswordUtils.needsRehash(stored), isFalse);
    });

    test('كل عملية hash تنتج ملحًا مختلفًا', () {
      final a = PasswordUtils.hash('secret');
      final b = PasswordUtils.hash('secret');
      expect(a, isNot(b));
    });

    test('verify يدعم الصيغة القديمة salt$sha256', () {
      const salt = 'bGVnYWN5LXNhbHQ=';
      final legacyStored = '$salt\$${_legacySha256(salt, 'oldpass')}';
      expect(PasswordUtils.verify('oldpass', legacyStored), isTrue);
      expect(PasswordUtils.verify('wrong', legacyStored), isFalse);
      expect(PasswordUtils.needsRehash(legacyStored), isTrue);
    });

    test('الدخول بمعرّف قديم يُرحّل كلمة السر إلى PBKDF2', () async {
      final repository = FakeStoreRepository();
      const legacyPassword = 'oldpass';
      // محاكاة الصيغة القديمة: salt$sha256(salt:password)
      final salt = 'bGVnYWN5LXNhbHQ=';
      final legacyHash = _legacySha256(salt, legacyPassword);
      await repository.addAdmin(Admin(
        username: 'legacyuser',
        passwordHash: '$salt\$$legacyHash',
        role: UserRole.superAdmin,
      ));

      final cubit = AuthCubit(repository);
      await cubit.login('legacyuser', legacyPassword);
      expect(cubit.state.status, AuthStatus.authenticated);

      final admins = await repository.getAdmins();
      final stored = admins.first.passwordHash;
      expect(PasswordUtils.needsRehash(stored), isFalse,
          reason: 'يجب أن تُرحَّل كلمة السر إلى PBKDF2');
      expect(PasswordUtils.verify(legacyPassword, stored), isTrue);
    });
  });
}

/// محاكاة الصيغة القديمة SHA-256 (salt:password) المستخدمة قبل PBKDF2.
String _legacySha256(String salt, String password) {
  final bytes = utf8.encode('$salt:$password');
  return sha256.convert(bytes).toString();
}
