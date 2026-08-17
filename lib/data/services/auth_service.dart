import 'package:omni_order/core/config/supabase_config.dart';

import 'license_service.dart';

/// بوابة الترخيص أمام تسجيل دخول الأدمن/الموظفين المحلي.
///
/// بعد الاستبدال الكامل لنظام Supabase Auth (Email & Password)، لم يعد هناك
/// أي جلسة أو بريد إلكتروني: البوابة الوحيدة هي تفعيل مفتاح الترخيص عبر
/// [LicenseService] (يُديرها [LicenseCubit])، ثم يدخل المستخدم باسمه وكلمة
/// السر المحلية (أدمن/كاشير) مباشرة.
class AuthService {
  AuthService({LicenseService? licenseService})
      : _license = licenseService ?? LicenseService();

  final LicenseService _license;

  /// هل Supabase مهيأ؟ (بوابة الترخيص مفعّلة عندها فقط).
  bool get isReady => SupabaseConfig.isReady;

  /// رسالة موحّدة عند انقطاع أو غياب الاتصال بالإنترنت.
  static const String noInternetMessage =
      'تعذر الاتصال بالإنترنت. تأكد من اتصالك وحاول مرة أخرى.';

  /// هل يوجد تفعيل محلي صالح على هذا الجهاز؟ (وضع عدم الاتصال)
  ///
  /// يُرجع `null` عند وجود تفعيل صالح، أو رسالة عربية واضحة عند غيابه
  /// (أو تعطله/انتهائه/تلاعب بتاريخ الجهاز).
  Future<String?> checkOfflineActivation() async {
    if (!isReady) return null; // وضع التطوير: بدون بوابة ترخيص.
    final result = await _license.checkOffline();
    return result.isSuccess ? null : result.message;
  }

  /// تسجيل الخروج لا يمسح الترخيص من الجهاز (يبقى مفعّلًا على نفس الجهاز).
  Future<void> logout() async {}
}
