import 'package:equatable/equatable.dart';

import '../../../../domain/models/admin.dart';

enum AuthStatus {
  /// جارٍ التحقق من وجود أدمن (شاشة التحميل).
  loading,

  /// لا يوجد أي أدمن بعد — أول مرة (شاشة إنشاء الأدمن الأساسي).
  setup,

  /// يوجد أدمن لكن لم يسجل الدخول (شاشة تسجيل الدخول).
  unauthenticated,

  /// نجح الدخول من Supabase وبقي اختيار الدور (أدمن أو كاشير).
  chooseRole,

  /// أدمن مسجل الدخول (الشاشة الرئيسية).
  authenticated,
}

/// حالة تسجيل الدخول وإدارة الأدمن.
class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.loading,
    this.admin,
    this.admins = const [],
    this.pendingEmail,
    this.error,
  });

  final AuthStatus status;
  final Admin? admin;
  final List<Admin> admins;

  /// الإيميل الذي نجح دخوله من Supabase وانتظر اختيار الدور.
  final String? pendingEmail;
  final String? error;

  bool get isSuperAdmin => admin?.isSuperAdmin ?? false;

  AuthState copyWith({
    AuthStatus? status,
    Admin? admin,
    List<Admin>? admins,
    String? pendingEmail,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      admin: admin ?? this.admin,
      admins: admins ?? this.admins,
      pendingEmail: pendingEmail ?? this.pendingEmail,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, admin, admins, pendingEmail, error];
}
