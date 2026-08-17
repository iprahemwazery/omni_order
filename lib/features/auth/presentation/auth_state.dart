import 'package:equatable/equatable.dart';

import '../../../../domain/models/admin.dart';

enum AuthStatus {
  /// جارٍ التحقق من الترخيص وحالة الأدمن (شاشة التحميل).
  loading,

  /// لا يوجد ترخيص مفعّل — تُعرض شاشة إدخال مفتاح الترخيص (البوابة الأولى).
  activation,

  /// لا يوجد أي أدمن بعد — أول مرة (شاشة إنشاء الأدمن الأساسي).
  setup,

  /// يوجد أدمن لكن لم يسجل الدخول (شاشة تسجيل الدخول المحلية).
  unauthenticated,

  /// أدمن مسجل الدخول (الشاشة الرئيسية).
  authenticated,
}

/// حالة تسجيل الدخول وإدارة الأدمن.
class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.loading,
    this.admin,
    this.admins = const [],
    this.error,
  });

  final AuthStatus status;
  final Admin? admin;
  final List<Admin> admins;

  /// رسالة خطأ عربية (تظهر في شاشة التفعيل/الدخول).
  final String? error;

  bool get isSuperAdmin => admin?.isSuperAdmin ?? false;

  AuthState copyWith({
    AuthStatus? status,
    Admin? admin,
    List<Admin>? admins,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      admin: admin ?? this.admin,
      admins: admins ?? this.admins,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, admin, admins, error];
}
