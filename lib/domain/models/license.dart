/// نتيجة التحقق من الترخيص.
///
/// الحالات الثلاث الأساسية التي يتعامل معها النظام:
/// - [onlineVerified]: تحقق/تفعيل ناجح عبر الإنترنت (Supabase = المرجع الوحيد).
/// - [offlineVerified]: استرجاع ناجح من التخزين المحلي المشفر (وضع عدم الاتصال).
/// - باقي الحالات: رفض — تعطيل / انتهاء / جهاز مختلف / تلاعب بالتاريخ / خطأ.
enum LicenseResultStatus {
  onlineVerified,
  offlineVerified,
  notFound,
  inactive,
  expired,
  otherDevice,
  timeTampered,
  error,
}

/// ترخيص مفعّل (بيانات التفعيل المحلية أو الناتجة من الخادم).
class License {
  const License({
    required this.licenseKey,
    required this.deviceId,
    this.activatedAt,
    this.expiresAt,
    this.verifiedAt,
  });

  /// مفتاح الترخيص.
  final String licenseKey;

  /// بصمة الجهاز المرتبط بهذا الترخيص.
  final String deviceId;

  /// تاريخ أول تفعيل (من الخادم).
  final DateTime? activatedAt;

  /// تاريخ انتهاء الصلاحية (null = ترخيص دائم).
  final DateTime? expiresAt;

  /// آخر تحقق ناجح عبر الإنترنت (من ساعة الخادم).
  /// يُستخدم لاكتشاف التلاعب بتاريخ الجهاز في وضع عدم الاتصال.
  final DateTime? verifiedAt;

  bool get isExpired {
    final expiry = expiresAt;
    return expiry != null && !DateTime.now().isBefore(expiry);
  }

  License copyWith({
    String? licenseKey,
    String? deviceId,
    DateTime? activatedAt,
    DateTime? expiresAt,
    DateTime? verifiedAt,
    bool clearActivatedAt = false,
    bool clearExpiresAt = false,
    bool clearVerifiedAt = false,
  }) {
    return License(
      licenseKey: licenseKey ?? this.licenseKey,
      deviceId: deviceId ?? this.deviceId,
      activatedAt: clearActivatedAt ? null : (activatedAt ?? this.activatedAt),
      expiresAt: clearExpiresAt ? null : (expiresAt ?? this.expiresAt),
      verifiedAt: clearVerifiedAt ? null : (verifiedAt ?? this.verifiedAt),
    );
  }
}

/// نتيجة عملية تفعيل أو تحقق من الترخيص، تتضمن حالة [status] ورسالة
/// عربية جاهزة للمستخدم ([message]) وبيانات الترخيص عند النجاح.
class LicenseResult {
  const LicenseResult({
    required this.status,
    this.message,
    this.license,
  });

  final LicenseResultStatus status;
  final String? message;
  final License? license;

  /// هل الترخيص صالح (أونلاين أو أوفلاين)؟
  bool get isSuccess =>
      status == LicenseResultStatus.onlineVerified ||
      status == LicenseResultStatus.offlineVerified;

  factory LicenseResult.success(License license, {required bool online}) =>
      LicenseResult(
        status: online
            ? LicenseResultStatus.onlineVerified
            : LicenseResultStatus.offlineVerified,
        license: license,
      );

  factory LicenseResult.failure(LicenseResultStatus status, String message) =>
      LicenseResult(status: status, message: message);
}
