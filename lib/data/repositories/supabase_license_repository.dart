import 'package:omni_order/core/utils/error_utils.dart';
import 'package:omni_order/domain/models/license.dart';
import 'package:omni_order/domain/repositories/license_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'local_license_store.dart';

/// تنفيذ مستودع الترخيص عبر Supabase.
///
/// المرجع الأساسي الوحيد للتحقق هو دالة `activate_or_verify_license`
/// (SECURITY DEFINER). عند نجاح التحقق يُحفظ التفعيل محلياً، وعند فشله
/// (تعطيل/انتهاء/جهاز آخر) يُمسح التفعيل المحلي فوراً — هذا هو Kill-Switch:
/// عند أول اتصال بالإنترنت يُطبق قرار لوحة Supabase فوراً.
///
/// عند غياب الإنترنت يُرجَع التفعيل المحلي الصالح (وضع عدم الاتصال).
class SupabaseLicenseRepository implements LicenseRepository {
  SupabaseLicenseRepository({
    LocalLicenseStore? localStore,
    Future<dynamic> Function(Map<String, dynamic>)? rpcCaller,
  })  : _local = localStore ?? LocalLicenseStore(),
        _rpcCaller = rpcCaller;

  final LocalLicenseStore _local;

  /// قابل للحقن في الاختبارات بدلاً من `Supabase.instance.client`.
  final Future<dynamic> Function(Map<String, dynamic>)? _rpcCaller;

  static const String _noInternetMessage =
      'تعذر الاتصال بالإنترنت. تأكد من اتصالك وحاول مرة أخرى.';

  SupabaseClient get _supabase => Supabase.instance.client;

  Future<dynamic> _callRpc(Map<String, dynamic> params) {
    final caller = _rpcCaller;
    if (caller != null) return caller(params);
    return _supabase.rpc('activate_or_verify_license', params: params);
  }

  @override
  Future<LicenseResult> activateOrVerify({
    required String licenseKey,
    required String deviceId,
  }) async {
    final key = licenseKey.trim();
    try {
      final data = await _callRpc({
        'p_license_key': key,
        'p_device_id': deviceId,
      });

      final map = _asMap(data);
      final success = map['success'] == true;
      if (success) {
        final license = License(
          licenseKey: key,
          deviceId: deviceId,
          activatedAt: _parseDate(map['activated_at']),
          expiresAt: _parseDate(map['expires_at']),
          verifiedAt: _parseDate(map['server_time']) ?? DateTime.now(),
        );
        await _local.save(license);
        return LicenseResult.success(license, online: true);
      }

      // فشل من الخادم: تعطيل / انتهاء / جهاز آخر -> مسح التفعيل المحلي
      // (Kill-Switch) وإرجاع رسالة عربية واضحة.
      await _local.clear();
      final code = map['code'] as String? ?? '';
      return LicenseResult.failure(
        _statusFromCode(code),
        _messageFromCode(code),
      );
    } on Exception catch (e) {
      // مشكلة شبكة: الرجوع للتفعيل المحلي إن وُجد وصالح.
      if (_isNetworkError(e)) {
        final offline = await _local.check(deviceId);
        if (offline.isSuccess) return offline;
        return const LicenseResult(
          status: LicenseResultStatus.error,
          message: _noInternetMessage,
        );
      }
      return LicenseResult(
        status: LicenseResultStatus.error,
        message: safeErrorMessage('حدث خطأ أثناء التحقق من الترخيص', e),
      );
    }
  }

  @override
  Future<LicenseResult> checkStoredActivation(String deviceId) =>
      _local.check(deviceId);

  @override
  Future<void> storeActivation(License license) => _local.save(license);

  @override
  Future<void> clearStoredActivation() => _local.clear();

  // ---- أدوات مساعدة ----

  static Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is List && data.isNotEmpty && data.first is Map) {
      return Map<String, dynamic>.from(data.first as Map);
    }
    return const {};
  }

  static DateTime? _parseDate(Object? value) {
    if (value == null || value.toString().isEmpty) return null;
    return DateTime.tryParse(value.toString());
  }

  /// تحويل كود الخطأ من الخادم إلى رسالة عربية محددة للمستخدم.
  static String _messageFromCode(String code) {
    switch (code) {
      case 'license_inactive':
      case 'DISABLED':
        return 'تم تعطيل هذا الترخيص من قبل الإدارة.';
      case 'license_expired':
      case 'EXPIRED':
        return 'لقد انتهت صلاحية هذا الترخيص.';
      case 'license_other_device':
      case 'DEVICE_MISMATCH':
        return 'هذا الترخيص مستخدم على جهاز آخر ولا يمكن استخدامه هنا.';
      case 'license_not_found':
      case 'NOT_FOUND':
        return 'مفتاح الترخيص غير صحيح أو غير موجود.';
      default:
        return 'مفتاح الترخيص غير صحيح أو غير موجود.';
    }
  }

  static LicenseResultStatus _statusFromCode(String code) {
    switch (code) {
      case 'license_inactive':
      case 'DISABLED':
        return LicenseResultStatus.inactive;
      case 'license_expired':
      case 'EXPIRED':
        return LicenseResultStatus.expired;
      case 'license_other_device':
      case 'DEVICE_MISMATCH':
        return LicenseResultStatus.otherDevice;
      case 'license_not_found':
      case 'NOT_FOUND':
      default:
        return LicenseResultStatus.notFound;
    }
  }

  static bool _isNetworkError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('socketexception') ||
        message.contains('clientexception') ||
        message.contains('timeoutexception') ||
        message.contains('failed to connect') ||
        message.contains('connection refused') ||
        message.contains('connection closed') ||
        message.contains('connection failed') ||
        message.contains('network is unreachable') ||
        message.contains('no route to host') ||
        message.contains('host lookup') ||
        message.contains('no internet connection') ||
        message.contains('network error') ||
        message.contains('unable to connect');
  }
}
