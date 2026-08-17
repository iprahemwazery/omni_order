import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/password_utils.dart';
import '../../../../data/services/auth_service.dart';
import '../../../../domain/models/admin.dart';
import '../../../../domain/repositories/store_repository.dart';
import 'auth_state.dart';

/// يدير بوابة الترخيص وتسجيل الدخول المحلي (أدمن/كاشير) وإدارة المستخدمين.
///
/// التدفق بعد الاستبدال الكامل:
///   1. عند فتح التطبيق يتحقق من التفعيل المحلي ([init]).
///   2. لا يوجد تفعيل -> شاشة إدخال مفتاح الترخيص ([AuthStatus.activation])
///      (التفعيل نفسه يديره LicenseCubit ثم يُستدعى [onLicenseGranted]).
///   3. بعد ضمان الترخيص -> إعداد أول مرة أو تسجيل الدخول المحلي.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository, {AuthService? authService})
      : _authService = authService ?? AuthService(),
        super(const AuthState());

  final StoreRepository _repository;
  final AuthService _authService;

  /// يتحقق عند فتح التطبيق: بوابة الترخيص أولاً، ثم حسب وجود المستخدمين
  /// المحليين (إعداد أول مرة أو شاشة تسجيل الدخول).
  Future<void> init() async {
    try {
      // 1) بوابة الترخيص: هل يوجد تفعيل محلي صالح على هذا الجهاز؟
      if (_authService.isReady) {
        final licenseError = await _authService.checkOfflineActivation();
        if (licenseError != null) {
          emit(const AuthState(status: AuthStatus.activation));
          return;
        }
      }

      // 2) الدخول المحلي حسب وجود أدمن.
      await _resolveLocalEntry();
    } catch (_) {
      emit(const AuthState(status: AuthStatus.unauthenticated));
    }
  }

  /// يُستدعى بعد نجاح تفعيل مفتاح الترخيص (من LicenseCubit) لاستكمال
  /// الدخول المحلي (إعداد أول مرة أو شاشة تسجيل الدخول).
  Future<String?> onLicenseGranted() async {
    try {
      if (_authService.isReady) {
        final licenseError = await _authService.checkOfflineActivation();
        if (licenseError != null) {
          emit(
            const AuthState(status: AuthStatus.activation),
          );
          return licenseError;
        }
      }
      await _resolveLocalEntry();
      return null;
    } catch (_) {
      emit(const AuthState(status: AuthStatus.activation));
      return 'تعذر التحقق من الترخيص. حاول مرة أخرى.';
    }
  }

  /// تحديد الدخول المحلي: لا يوجد أدمن -> إعداد أول مرة، وإلا تسجيل الدخول.
  Future<void> _resolveLocalEntry() async {
    final admins = await _repository.getAdmins();
    if (admins.isEmpty) {
      emit(const AuthState(status: AuthStatus.setup));
    } else {
      emit(const AuthState(status: AuthStatus.unauthenticated));
    }
  }

  // ---- تسجيل الدخول المحلي (بعد ضمان الترخيص) ----

  /// تسجيل الدخول باسم المستخدم وكلمة السر المحلية (أدمن/كاشير).
  Future<String?> login(String username, String password) async {
    final trimmed = username.trim();
    if (trimmed.isEmpty) return 'اكتب اسم المستخدم.';
    if (password.isEmpty) return 'اكتب كلمة السر.';

    final admin = await _repository.getAdminByUsername(trimmed);
    if (admin == null || !PasswordUtils.verify(password, admin.passwordHash)) {
      return 'اسم المستخدم أو كلمة السر غير صحيحة.';
    }

    // ترحيل كلمات السر المخزّنة بالصيغة القديمة (SHA-256) إلى PBKDF2.
    var loggedIn = admin;
    if (PasswordUtils.needsRehash(admin.passwordHash)) {
      loggedIn = admin.copyWith(passwordHash: PasswordUtils.hash(password));
      await _repository.updateAdmin(loggedIn);
    }
    emit(AuthState(status: AuthStatus.authenticated, admin: loggedIn));
    return null;
  }

  /// هل لا يوجد أي حساب بصلاحيات أدمن حاليًا؟ (كل الحسابات كاشير فقط)
  /// تُستخدم عند التبديل إلى أدمن لمعرفة ما إذا كان يلزم إنشاء حساب جديد.
  Future<bool> needsAdminAccount() async {
    final admins = await _repository.getAdmins();
    return !admins.any((a) => a.role != UserRole.cashier);
  }

  // ---- تبديل الدور من داخل التطبيق ----

  /// تحويل من أدمن/سوبر أدمن إلى كاشير مباشرة (بدون كلمة سر).
  Future<String?> switchToCashier() async {
    final current = state.admin;
    if (current == null) return 'لا توجد جلسة نشطة. أعد تسجيل الدخول.';
    if (current.role == UserRole.cashier) return null;

    final admin = await _adminByUsername(
      current.username,
      role: UserRole.cashier,
    );
    emit(AuthState(status: AuthStatus.authenticated, admin: admin));
    return null;
  }

  /// تحويل من كاشير إلى أدمن: يلزم اسم المستخدم وكلمة السر.
  Future<String?> switchToAdmin({
    required String username,
    required String password,
    String confirmPassword = '',
  }) async {
    final current = state.admin;
    if (current == null) return 'لا توجد جلسة نشطة. أعد تسجيل الدخول.';
    if (current.role != UserRole.cashier) return null;

    return _authenticateAdmin(
      username: username,
      password: password,
      confirmPassword: confirmPassword,
    );
  }

  /// التحقق من بيانات أدمن محلي والدخول به، أو إنشاء الأدمن الأساسي عند
  /// أول دخول كأدمن. لو كان هذا الحساب قد حُوّل إلى كاشير، يُعاد لصلاحياته.
  Future<String?> _authenticateAdmin({
    required String username,
    required String password,
    String confirmPassword = '',
  }) async {
    final trimmed = username.trim();
    if (trimmed.isEmpty) return 'اكتب اسم المستخدم.';
    if (password.isEmpty) return 'اكتب كلمة السر.';

    final admins = await _repository.getAdmins();
    final existing = await _repository.getAdminByUsername(trimmed);

    if (existing == null) {
      // لا يُنشأ أدمن جديد بعد وجود حساب أدمن/كاشير من قبل.
      final hasAdminAccount = admins.any((a) => a.role != UserRole.cashier);
      if (hasAdminAccount) return 'اسم المستخدم أو كلمة السر غير صحيحة.';
      if (password != confirmPassword) return 'كلمتا السر غير متطابقتين.';

      final hash = PasswordUtils.hash(password);
      final id = await _repository.addAdmin(Admin(
        username: trimmed,
        passwordHash: hash,
        role: UserRole.superAdmin,
      ));
      emit(AuthState(
        status: AuthStatus.authenticated,
        admin: Admin(
          id: id,
          username: trimmed,
          passwordHash: hash,
          role: UserRole.superAdmin,
        ),
      ));
      return null;
    }

    if (!PasswordUtils.verify(password, existing.passwordHash)) {
      return 'اسم المستخدم أو كلمة السر غير صحيحة.';
    }

    // لو كان الحساب محوّلًا إلى كاشير، نعيده إلى صلاحيات الأدمن.
    final restored = existing.role == UserRole.cashier
        ? existing.copyWith(role: UserRole.superAdmin)
        : existing;
    if (!identical(restored, existing)) {
      await _repository.updateAdmin(restored);
    }
    emit(AuthState(status: AuthStatus.authenticated, admin: restored));
    return null;
  }

  /// يعيد الأدمن المحلي المقابل لهذا الاسم بالدور المختار، أو ينشئه
  /// تلقائيًا عند أول تحويل لدور لم يُسجَّل من قبل.
  Future<Admin> _adminByUsername(String username,
      {required UserRole role}) async {
    final existing = await _repository.getAdminByUsername(username);
    if (existing != null) {
      final updated = existing.copyWith(role: role);
      await _repository.updateAdmin(updated);
      return updated;
    }

    // كلمة سر عشوائية: الدخول يتم من شاشة الدخول بكلمة السر المحلية.
    final randomHash = PasswordUtils.hash(
      '$username-${DateTime.now().microsecondsSinceEpoch}',
    );
    final id = await _repository.addAdmin(Admin(
      username: username,
      passwordHash: randomHash,
      role: role,
    ));
    return Admin(
      id: id,
      username: username,
      passwordHash: randomHash,
      role: role,
    );
  }

  Future<void> logout() async {
    emit(const AuthState(status: AuthStatus.unauthenticated));
    await _authService.logout();
    await _loadUsers();
  }

  // ---- الإعداد الأول ----

  /// إنشاء الأدمن الأساسي (أول مستخدم) — يملك كل الصلاحيات.
  Future<String?> setupOwner({
    required String username,
    required String password,
    required String confirmPassword,
  }) async {
    final error = _validateCredentials(username, password, confirmPassword);
    if (error != null) return error;

    final id = await _repository.addAdmin(Admin(
      username: username.trim(),
      passwordHash: PasswordUtils.hash(password),
      role: UserRole.superAdmin,
    ));
    emit(AuthState(
      status: AuthStatus.authenticated,
      admin: Admin(
        id: id,
        username: username.trim(),
        passwordHash: PasswordUtils.hash(password),
        role: UserRole.superAdmin,
      ),
    ));
    return null;
  }

  // ---- إدارة المستخدمين ----

  Future<void> _loadUsers() async {
    try {
      final admins = await _repository.getAdmins();
      emit(state.copyWith(admins: admins));
    } catch (_) {
      // تجاهل فشل التحميل — تظهر القائمة فارغة.
    }
  }

  Future<void> loadUsers() => _loadUsers();

  /// إنشاء مستخدم جديد (أدمن أو كاشير).
  Future<String?> createUser({
    required String username,
    required String password,
    required String confirmPassword,
    UserRole role = UserRole.cashier,
  }) async {
    if (!state.isSuperAdmin) return 'لا تملك صلاحية إدارة المستخدمين.';
    if (role == UserRole.superAdmin) return 'لا يمكن إنشاء أدمن أساسي من هنا.';

    final error = _validateCredentials(username, password, confirmPassword);
    if (error != null) return error;

    final trimmed = username.trim();
    final existing = await _repository.getAdminByUsername(trimmed);
    if (existing != null) return 'اسم المستخدم موجود من قبل.';

    await _repository.addAdmin(Admin(
      username: trimmed,
      passwordHash: PasswordUtils.hash(password),
      role: role,
    ));
    await _loadUsers();
    return null;
  }

  /// تغيير دور مستخدم (أدمن <-> كاشير). فقط الأدمن الأساسي.
  Future<String?> updateRole(Admin user, UserRole role) async {
    final current = state.admin;
    if (current == null || !current.isSuperAdmin) {
      return 'لا تملك صلاحية إدارة المستخدمين.';
    }
    if (current.id == user.id) return 'لا يمكن تغيير دورك أنت.';
    if (role == UserRole.superAdmin) return 'لا يمكن تعيين أدمن أساسي من هنا.';

    final superAdmins =
        await _repository.getAdmins().then((a) => a.where((x) => x.isSuperAdmin).length);
    if (user.isSuperAdmin && superAdmins <= 1) {
      return 'لا يمكن تغيير دور آخر أدمن أساسي.';
    }

    await _repository.updateAdmin(user.copyWith(role: role));
    await _loadUsers();
    return null;
  }

  /// حذف مستخدم. فقط الأدمن الأساسي، ولا يمكن حذف النفس أو آخر أدمن أساسي.
  Future<String?> deleteUser(Admin user) async {
    final current = state.admin;
    if (current == null || !current.isSuperAdmin) {
      return 'لا تملك صلاحية إدارة المستخدمين.';
    }
    if (user.id == current.id) return 'لا يمكنك حذف حسابك الحالي.';

    final superAdmins =
        await _repository.getAdmins().then((a) => a.where((x) => x.isSuperAdmin).length);
    if (user.isSuperAdmin && superAdmins <= 1) {
      return 'لا يمكن حذف آخر أدمن أساسي.';
    }

    await _repository.deleteAdmin(user.id!);
    await _loadUsers();
    return null;
  }

  String? _validateCredentials(
    String username,
    String password,
    String confirmPassword,
  ) {
    if (username.trim().length < 3) return 'اسم المستخدم يجب أن يكون 3 أحرف على الأقل.';
    if (password.length < 4) return 'كلمة السر يجب أن تكون 4 رموز على الأقل.';
    if (password != confirmPassword) return 'كلمتا السر غير متطابقتين.';
    return null;
  }
}
