import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';

class LicenseService {
  /// يُقيَّم عند الاستخدام فقط حتى لا ينهار في الاختبارات.
  SupabaseClient get _supabase => Supabase.instance.client;

  /// هل Supabase مهيأ وجاهز للعمل؟
  bool get isReady => SupabaseConfig.isReady;

  /// تسجيل الخروج من Supabase Auth.
  Future<void> signOut() async {
    if (!isReady) return;
    try {
      await _supabase.auth.signOut();
    } catch (_) {
      // تجاهل أخطاء تسجيل الخروج.
    }
  }

  // 1. جلب بصمة الجهاز الفريدة (HWID)
  Future<String> getDeviceFingerprint() async {
    final deviceInfo = DeviceInfoPlugin();
    String rawId = '';

    if (Platform.isWindows) {
      final win = await deviceInfo.windowsInfo;
      rawId =
          '${win.deviceId}-${win.numberOfCores}-${win.systemMemoryInMegabytes}';
    } else if (Platform.isAndroid) {
      final android = await deviceInfo.androidInfo;
      rawId = android.id;
    } else if (Platform.isLinux) {
      final linux = await deviceInfo.linuxInfo;
      rawId = linux.machineId ?? linux.id;
    }

    return sha256.convert(utf8.encode(rawId)).toString();
  }

  // 2. التحقق وتسجيل الترخيص
  Future<String?> loginAndVerifyLicense({
    required String email,
    required String password,
  }) async {
    try {
      if (!isReady) {
        return "لم يتم تهيئة Supabase بعد. ضع بيانات مشروعك في lib/core/config/supabase_config.dart";
      }

      // أ- تسجيل الدخول في Supabase Auth
      final authResponse = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = authResponse.user;
      if (user == null) return "بيانات الدخول غير صحيحة";

      final deviceId = await getDeviceFingerprint();

      // ب- الاستعلام عن ترخيص هذا الجهاز
      final response = await _supabase
          .from('licenses')
          .select()
          .eq('user_id', user.id)
          .eq('device_id', deviceId)
          .maybeSingle();

      // ج- لو الجهاز جديد، نسجله لأول مرة تلقائياً (ترخيص لمدة سنة)
      if (response == null) {
        await _supabase.from('licenses').insert({
          'user_id': user.id,
          'device_id': deviceId,
          'is_active': true,
          'expires_at': DateTime.now()
              .add(const Duration(days: 365))
              .toIso8601String(),
        });
        return null; // نجاح التفعيل لأول مرة
      }

      // د- التأكد من حالة وصلاحية الترخيص
      final isActive = response['is_active'] as bool;
      final expiresAt = DateTime.parse(response['expires_at']);

      if (!isActive) {
        return "تم إيقاف الترخيص لهذا الجهاز من قبل الإدارة.";
      }

      if (expiresAt.isBefore(DateTime.now())) {
        return "لقد انتهت فترة الاشتراك الخاصة بك.";
      }

      return null; // الترخيص ساري بنجاح
    } on AuthException catch (e) {
      return 'فشل تسجيل الدخول: ${e.message}';
    } on PostgrestException catch (e) {
      // أشهر الأسباب: جدول licenses غير موجود، RLS بدون بوليصات،
      // أو اسم/نوع عمود مختلف عن المتوقع.
      return 'خطأ في جدول الترخيص (${e.code ?? 'بدون كود'}): ${e.message}';
    } catch (e) {
      return 'حدث خطأ غير متوقع: $e';
    }
  }
}
