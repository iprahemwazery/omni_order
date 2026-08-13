import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/password_utils.dart';
import '../../../../data/services/auth_service.dart';
import '../../../../domain/models/admin.dart';
import '../../../../domain/repositories/store_repository.dart';
import 'auth_state.dart';

/// يدير تسجيل الدخول والجلسة الحالية وإدارة المستخدمين والصلاحيات.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository, {AuthService? authService})
      : _authService = authService ?? AuthService(),
        super(const AuthState());

  final StoreRepository _repository;
  final AuthService _authService;

  /// يتحقق عند فتح التطبيق: إن كان Supabase مفعّلًا -> يستعيد الجلسة
  /// المحفوظة (التوكن) ويدخل مباشرة، أو يعرض شاشة تسجيل الدخول.
  /// وإلا فحسب وجود مستخدمين محليين (إعداد أول مرة أو دخول محلي).
  Future<void> init() async {
    try {
      if (_authService.isReady) {
        await _restoreSession();
        return;
      }
      final admins = await _repository.getAdmins();
      if (admins.isEmpty) {
        emit(const AuthState(status: AuthStatus.setup));
      } else {
        emit(const AuthState(status: AuthStatus.unauthenticated));
      }
    } catch (e) {
      emit(const AuthState(status: AuthStatus.unauthenticated, error: 'تعذر فتح قاعدة البيانات'));
    }
  }

  /// يستعيد الجلسة المحفوظة من Supabase: لو في جلسة (التوكن محفوظ محليًا)
  /// يُعاد فتح التطبيق مباشرة على الشاشة الرئيسية بنفس دور المستخدم.
  Future<void> _restoreSession() async {
    try {
      final session = _authService.currentSession;
      final email = session?.user.email;
      if (email == null || email.isEmpty) {
        emit(const AuthState(status: AuthStatus.unauthenticated));
        return;
      }

      // نعيد استخدام نفس الأدمن المحلي بدوره المحفوظ (أدمن/كاشير).
      final existing = await _repository.getAdminByUsername(email);
      if (existing != null) {
        emit(AuthState(status: AuthStatus.authenticated, admin: existing));
        return;
      }

      // لو قاعدة البيانات المحلية اتُهيأت بعد آخر دخول: ننشئ الأدمن مرتبطًا
      // بنفس البريد حتى يفتح التطبيق مباشرة.
      final admin = await _adminForEmail(email, role: UserRole.superAdmin);
      emit(AuthState(status: AuthStatus.authenticated, admin: admin));
    } catch (_) {
      emit(const AuthState(status: AuthStatus.unauthenticated));
    }
  }

  // ---- تسجيل الدخول ----

  /// تسجيل الدخول: عبر Supabase (بريد + كلمة سر + جهاز واحد فقط) إن كان مفعّلًا،
  /// ثم يطلب اختيار الدور (أدمن/كاشير). وإلا يعود لتسجيل الدخول المحلي القديم.
  Future<String?> login(String email, String password) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return 'اكتب البريد الإلكتروني.';
    if (password.isEmpty) return 'اكتب كلمة السر.';

    if (_authService.isReady) {
      final licenseError = await _authService.loginSingleDevice(
        email: trimmed,
        password: password,
      );
      if (licenseError != null) return licenseError;

      emit(AuthState(status: AuthStatus.chooseRole, pendingEmail: trimmed));
      return null;
    }

    final admin = await _repository.getAdminByUsername(trimmed);
    if (admin == null || !PasswordUtils.verify(password, admin.passwordHash)) {
      return 'اسم المستخدم أو كلمة السر غير صحيحة.';
    }
    emit(AuthState(status: AuthStatus.authenticated, admin: admin));
    return null;
  }

  /// هل لا يوجد أي أدمن محلي بعد؟ (أول تشغيل — سيُطلب إنشاء الأدمن).
  Future<bool> needsAdminCreation() async {
    final admins = await _repository.getAdmins();
    return admins.isEmpty;
  }

  /// هل لا يوجد أي حساب بصلاحيات أدمن حاليًا؟ (كل الحسابات كاشير فقط)
  /// تُستخدم لمعرفة ما إذا كان التبديل إلى أدمن يحتاج إنشاء حساب جديد.
  Future<bool> needsAdminAccount() async {
    final admins = await _repository.getAdmins();
    return !admins.any((a) => a.role != UserRole.cashier);
  }

  /// الدخول كأدمن: اسم مستخدم + كلمة سر. لو مفيش أدمن خالص يتم الإنشاء
  /// (زي الفكرة القديمة)، وإلا يتم التحقق من البيانات.
  Future<String?> loginAsAdmin({
    required String username,
    required String password,
    String confirmPassword = '',
  }) async {
    final email = state.pendingEmail;
    if (email == null) return 'جلسة منتهية. أعد تسجيل الدخول.';
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

  /// الدخول ككاشير مباشرة (بدون بيانات إضافية) — كاشير مرتبط بالإيميل.
  Future<String?> loginAsCashier() async {
    final email = state.pendingEmail;
    if (email == null) return 'جلسة منتهية. أعد تسجيل الدخول.';

    final admin = await _adminForEmail(email, role: UserRole.cashier);
    emit(AuthState(status: AuthStatus.authenticated, admin: admin));
    return null;
  }

  // ---- تبديل الدور من داخل التطبيق ----

  /// تحويل من أدمن/سوبر أدمن إلى كاشير مباشرة (بدون كلمة سر).
  Future<String?> switchToCashier() async {
    final current = state.admin;
    if (current == null) return 'لا توجد جلسة نشطة. أعد تسجيل الدخول.';
    if (current.role == UserRole.cashier) return null;

    final admin = await _adminForEmail(current.username, role: UserRole.cashier);
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

  /// يعيد الأدمن المحلي المقابل لهذا البريد بالدور المختار، أو ينشئه
  /// تلقائيًا عند أول تسجيل دخول عبر Supabase.
  Future<Admin> _adminForEmail(String email, {required UserRole role}) async {
    final existing = await _repository.getAdminByUsername(email);
    if (existing != null) {
      final updated = existing.copyWith(role: role);
      await _repository.updateAdmin(updated);
      return updated;
    }

    // كلمة سر عشوائية: الدخول أصبح عبر Supabase وليس عبر كلمة السر المحلية.
    final randomHash = PasswordUtils.hash(
      '$email-${DateTime.now().microsecondsSinceEpoch}',
    );
    final id = await _repository.addAdmin(Admin(
      username: email,
      passwordHash: randomHash,
      role: role,
    ));
    return Admin(
      id: id,
      username: email,
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
