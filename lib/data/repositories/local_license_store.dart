import 'dart:convert';

import 'package:omni_order/core/utils/error_utils.dart';
import 'package:omni_order/domain/models/license.dart';

import '../services/secure_store.dart';

/// التخزين المحلي المشفر لبيانات التفعيل (Offline Persistence).
///
/// يخزن داخل flutter_secure_storage:
///   license_key + device_id + activated_at + expires_at + verified_at
///
/// يوفّر التحقق المحلي في وضع عدم الاتصال مع حماية من التلاعب:
/// - مطابقة بصمة الجهاز المخزنة مع الحالية.
/// - التحقق من تاريخ انتهاء الصلاحية.
/// - كشف التلاعب بتاريخ الجهاز: لو تاريخ الجهاز الحالي أقدم من آخر تحقق
///   ناجح أونلاين ([verifiedAt])، يُرفض الفتح ويُطلب الاتصال بالإنترنت.
class LocalLicenseStore {
  LocalLicenseStore({SecureStore? store}) : _store = store ?? FlutterSecureStore();

  static const String storageKey = 'omni_order_license_v1';

  final SecureStore _store;

  /// يقرأ التفعيل المحلي ويتحقق من صلاحيته لوضع عدم الاتصال.
  Future<LicenseResult> check(String deviceId) async {
    try {
      final raw = await _store.read(storageKey);
      if (raw == null || raw.trim().isEmpty) {
        return LicenseResult.failure(
          LicenseResultStatus.notFound,
          'لا يوجد ترخيص مفعّل على هذا الجهاز.',
        );
      }

      final map = _decode(raw);
      final storedDeviceId = map['device_id'] as String? ?? '';

      // مطابقة البصمة: الترخيص مرتبط بجهاز آخر.
      if (storedDeviceId != deviceId) {
        return LicenseResult.failure(
          LicenseResultStatus.otherDevice,
          'هذا الترخيص مستخدم على جهاز آخر.',
        );
      }

      final now = DateTime.now();

      // حماية من التلاعب بالتاريخ: لو تاريخ الجهاز أقدم من آخر تحقق
      // ناجح عبر الإنترنت، فالجهاز مُعاد ضبطه للوراء -> نرفض الفتح.
      final verifiedAt = _parseDate(map['verified_at']);
      if (verifiedAt != null && now.isBefore(verifiedAt)) {
        return LicenseResult.failure(
          LicenseResultStatus.timeTampered,
          'يبدو أن تاريخ الجهاز تم تعديله. اتصل بالإنترنت للتحقق من الترخيص.',
        );
      }

      // انتهاء الصلاحية في وضع عدم الاتصال.
      final expiresAt = _parseDate(map['expires_at']);
      if (expiresAt != null && now.isAfter(expiresAt)) {
        return LicenseResult.failure(
          LicenseResultStatus.expired,
          'لقد انتهت صلاحية هذا الترخيص.',
        );
      }

      return LicenseResult.success(
        License(
          licenseKey: map['license_key'] as String? ?? '',
          deviceId: storedDeviceId,
          activatedAt: _parseDate(map['activated_at']),
          expiresAt: expiresAt,
          verifiedAt: verifiedAt,
        ),
        online: false,
      );
    } catch (e) {
      return LicenseResult(
        status: LicenseResultStatus.error,
        message: safeErrorMessage('تعذر قراءة الترخيص المحلي', e),
      );
    }
  }

  /// يحفظ بيانات التفعيل مشفرة محلياً.
  Future<void> save(License license) async {
    await _store.write(
      storageKey,
      jsonEncode({
        'license_key': license.licenseKey,
        'device_id': license.deviceId,
        'activated_at': _encodeDate(license.activatedAt),
        'expires_at': _encodeDate(license.expiresAt),
        'verified_at': _encodeDate(license.verifiedAt),
      }),
    );
  }

  /// يمسح التفعيل المحلي.
  Future<void> clear() async {
    await _store.delete(storageKey);
  }

  static Map<String, dynamic> _decode(String raw) =>
      jsonDecode(raw) as Map<String, dynamic>;

  static String? _encodeDate(DateTime? date) => date?.toIso8601String();

  static DateTime? _parseDate(Object? value) {
    if (value == null || value.toString().isEmpty) return null;
    return DateTime.tryParse(value.toString());
  }
}
