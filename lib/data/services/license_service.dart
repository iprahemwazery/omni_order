import 'package:omni_order/core/config/supabase_config.dart';
import 'package:omni_order/domain/models/license.dart';
import 'package:omni_order/domain/repositories/license_repository.dart';

import '../repositories/supabase_license_repository.dart';
import 'device_fingerprint_service.dart';

/// خدمة الترخيص — نقطة التنسيق بين بصمة الجهاز ومستودع الترخيص (Supabase).
///
/// توفر عمليات رفيعة المستوى:
/// - [activateOrVerify]: تحقق/تفعيل أونلاين عبر RPC (وحفظ محلي عند النجاح).
/// - [checkOffline]: تحقق محلي من التفعيل المشفر (وضع عدم الاتصال).
/// - [clearLicense]: مسح التفعيل المحلي.
class LicenseService {
  LicenseService({
    LicenseRepository? repository,
    DeviceFingerprintService? fingerprintService,
  })  : _repository = repository ?? SupabaseLicenseRepository(),
        _fingerprint = fingerprintService ?? DeviceFingerprintService();

  final LicenseRepository _repository;
  final DeviceFingerprintService _fingerprint;

  /// هل Supabase مهيأ وجاهز للعمل؟ (البوابة الأمنية مفعّلة فقط عندها).
  bool get isReady => SupabaseConfig.isReady;

  /// بصمة الجهاز الحالي (SHA-256 للمعرّف الأصلي).
  Future<String> getDeviceId() => _fingerprint.getDeviceFingerprint();

  /// تحقق/تفعيل عبر الإنترنت باستدعاء RPC، مع بصمة الجهاز الحالية.
  /// عند النجاح يُحفظ التفعيل محلياً تلقائياً.
  Future<LicenseResult> activateOrVerify(String licenseKey) async {
    final deviceId = await _fingerprint.getDeviceFingerprint();
    return _repository.activateOrVerify(
      licenseKey: licenseKey,
      deviceId: deviceId,
    );
  }

  /// تحقق محلي (وضع عدم الاتصال) من التفعيل المشفر وبصمة الجهاز الحالية.
  Future<LicenseResult> checkOffline() async {
    final deviceId = await _fingerprint.getDeviceFingerprint();
    return _repository.checkStoredActivation(deviceId);
  }

  /// مسح التفعيل المحلي.
  Future<void> clearLicense() => _repository.clearStoredActivation();
}
