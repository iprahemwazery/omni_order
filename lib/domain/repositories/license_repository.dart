import '../models/license.dart';

/// مستودع الترخيص — مسؤول عن التحقق من مفتاح الترخيص وربطه بجهاز واحد،
/// وحفظ التفعيل محلياً بشكل مشفر ليعمل التطبيق في وضع عدم الاتصال.
abstract interface class LicenseRepository {
  /// يتحقق من المفتاح عبر دالة `activate_or_verify_license` في Supabase:
  /// - مفتاح جديد بدون جهاز -> يُربط بهذا الجهاز (تفعيل أول).
  /// - مفتاح مرتبط بنفس الجهاز -> تحقق ناجح.
  /// - مفتاح مرتبط بجهاز آخر -> رفض صريح.
  ///
  /// عند النجاح يُحفظ التفعيل محلياً تلقائياً. عند الفشل (تعطيل/انتهاء/
  /// جهاز آخر) يُمسح التفعيل المحلي (Kill-Switch عند أول اتصال).
  /// عند غياب الإنترنت يُرجَع التفعيل المحلي إن كان صالحاً.
  Future<LicenseResult> activateOrVerify({
    required String licenseKey,
    required String deviceId,
  });

  /// يقرأ التفعيل المشفر محلياً ويطابق بصمة الجهاز وتاريخ الصلاحية
  /// وتاريخ آخر تحقق (اكتشاف التلاعب بالتاريخ) — وضع عدم الاتصال.
  Future<LicenseResult> checkStoredActivation(String deviceId);

  /// يحفظ بيانات التفعيل مشفرة داخل flutter_secure_storage.
  Future<void> storeActivation(License license);

  /// يمسح التفعيل المحلي (يُستخدم عند فشل التحقق الأونلاين).
  Future<void> clearStoredActivation();
}
