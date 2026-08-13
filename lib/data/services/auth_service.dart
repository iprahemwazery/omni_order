import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import 'license_service.dart';

/// تسجيل الدخول ببريد إلكتروني وكلمة سر مقفول على جهاز واحد فقط.
/// لو الحساب مفتوح على جهاز معتمد، أي جهاز آخر يُمنع فوراً.
class AuthService {
  AuthService({LicenseService? licenseService, Connectivity? connectivity})
      : _licenseService = licenseService ?? LicenseService(),
        _connectivity = connectivity ?? Connectivity();

  final LicenseService _licenseService;
  final Connectivity _connectivity;

  /// مهلة قصوى لكل عملية شبكة حتى لا يعلق التطبيق عند بطء أو انقطاع النت.
  static const Duration _timeout = Duration(seconds: 20);

  /// رسالة موحّدة عند انقطاع أو غياب الاتصال بالإنترنت.
  static const String noInternetMessage =
      'تعذر الاتصال بالإنترنت. تأكد من اتصالك وحاول مرة أخرى.';

  /// يُقيَّم عند الاستخدام فقط حتى لا ينهار في الاختبارات.
  SupabaseClient get _supabase => Supabase.instance.client;

  /// هل Supabase مهيأ وجاهز للعمل؟
  bool get isReady => SupabaseConfig.isReady;

  /// الجلسة المحفوظة حاليًا في Supabase (التوكن يُخزَّن محليًا تلقائيًا).
  ///
  /// تُستخدم عند فتح التطبيق لاستعادة الجلسة والدخول مباشرة دون إعادة
  /// كتابة البريد وكلمة السر. ترجع `null` بأمان لو لم تكن هناك جلسة
  /// (أو حتى لو لم تكن Supabase مهيأة) حتى لا ينهار التطبيق.
  Session? get currentSession {
    if (!isReady) return null;
    try {
      return _supabase.auth.currentSession;
    } catch (_) {
      return null;
    }
  }

  /// فحص سريع لوجود اتصال بالإنترنت قبل محاولة الدخول.
  /// لو فشل الفحص نفسه نسمح بالمحاولة ولا نمنع الدخول.
  Future<bool> _hasInternet() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.isNotEmpty && !results.contains(ConnectivityResult.none);
    } catch (_) {
      return true;
    }
  }

  /// دخول بحساب واحد على جهاز واحد فقط.
  ///
  /// يُرجع `null` عند النجاح، أو رسالة عربية واضحة عند الفشل.
  Future<String?> loginSingleDevice({
    required String email,
    required String password,
  }) async {
    if (!isReady) {
      return 'لم يتم تهيئة Supabase بعد. ضع بيانات مشروعك في lib/core/config/supabase_config.dart';
    }

    // لو مفيش إنترنت نخبر المستخدم فورًا بدل انتظار فشل الاتصال.
    if (!await _hasInternet()) {
      return noInternetMessage;
    }

    try {
      return await _performSingleDeviceLogin(
        email: email,
        password: password,
      ).timeout(_timeout);
    } on TimeoutException {
      await _safeSignOut();
      return noInternetMessage;
    } on AuthException catch (e) {
      // أشهر سبب: بيانات الدخول غير صحيحة.
      if (e.message.contains('Invalid login credentials')) {
        return 'بيانات الدخول غير صحيحة';
      }
      if (_isNetworkError(e)) {
        await _safeSignOut();
        return noInternetMessage;
      }
      return 'فشل تسجيل الدخول: ${e.message}';
    } on PostgrestException catch (e) {
      // أشهر الأسباب: جدول licenses غير موجود، RLS بدون بوليصات،
      // أو اسم/نوع عمود مختلف عن المتوقع.
      if (_isNetworkError(e)) return noInternetMessage;
      return 'خطأ في جدول الترخيص (${e.code ?? 'بدون كود'}): ${e.message}';
    } catch (e) {
      await _safeSignOut();
      if (_isNetworkError(e)) return noInternetMessage;
      return 'حدث خطأ أثناء فحص الحساب: $e';
    }
  }

  /// تنفيذ تسجيل الدخول الفعلي + فحص الترخيص (يُغلَّف بمهلة زمنية).
  Future<String?> _performSingleDeviceLogin({
    required String email,
    required String password,
  }) async {
    // 1. بصمة الجهاز الحالي الذي يحاول الدخول الآن (HWID).
    final currentDeviceId = await _licenseService.getDeviceFingerprint();

    // 2. تسجيل دخول مبدئي في Supabase للتحقق من صحة الباسورد والإيميل
    //    ويُخزَّن التوكن محليًا تلقائيًا للدخول المباشر لاحقًا.
    final authResponse = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = authResponse.user;
    if (user == null) {
      await _supabase.auth.signOut();
      return 'بيانات الدخول غير صحيحة';
    }

    // 3. قراءة حالة الترخيص والجلسة الحالية للحساب من جدول licenses.
    final license = await _supabase
        .from('licenses')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    // لو مفيش ترخيص سابق: ننشئ ترخيصاً جديداً ونعتمد هذا الجهاز لأول مرة.
    if (license == null) {
      await _supabase.from('licenses').insert({
        'user_id': user.id,
        'device_id': currentDeviceId,
        'is_active': true,
        'is_logged_in': true,
        'expires_at': DateTime.now()
            .add(const Duration(days: 365))
            .toIso8601String(),
      });
      return null; // نجاح الدخول بالجهاز الأول
    }

    // 4. استخراج بيانات الجلسة المسجلة في السيرفر.
    final isLoggedIn = license['is_logged_in'] as bool? ?? false;
    final activeDeviceId = license['device_id'] as String? ?? '';
    final isActive = license['is_active'] as bool? ?? false;
    final expiresAt =
        DateTime.tryParse(license['expires_at'] as String? ?? '');

    // فحص صلاحية الاشتراك.
    if (!isActive) {
      await _supabase.auth.signOut();
      return 'تم إيقاف الترخيص لهذا الحساب من قبل الإدارة.';
    }

    if (expiresAt == null || expiresAt.isBefore(DateTime.now())) {
      await _supabase.auth.signOut();
      return 'انتهت فترة الاشتراك الخاصة بك.';
    }

    // الشرط الأساسي لمنع الجهاز الثاني:
    // إذا كان الحساب مستخدماً حالياً والجهاز الحالي ليس هو الجهاز المعتمد.
    if (isLoggedIn && activeDeviceId != currentDeviceId) {
      // ننهي الجلسة الجديدة فوراً لمنع دخول الجهاز الثاني.
      await _supabase.auth.signOut();
      return 'عذراً، هذا الحساب مفتوح حالياً ومستخدم على جهاز آخر! لا يمكن الدخول من هذا الجهاز.';
    }

    // 5. نفس الجهاز أو الحساب كان مغلقاً: نسمح بالدخول ونثبت الجهاز.
    await _supabase.from('licenses').update({
      'device_id': currentDeviceId,
      'is_logged_in': true,
    }).eq('user_id', user.id);

    return null; // تم الدخول بنجاح
  }

  /// تسجيل الخروج الرسمي من داخل التطبيق.
  ///
  /// ضروري لإعادة فتح الحساب: بعد إغلاق الجهاز الأول،
  /// يسمح بالدخول من أي جهاز آخر.
  Future<void> logout() async {
    if (!isReady) return;
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _supabase.from('licenses').update({
          'is_logged_in': false,
        }).eq('user_id', user.id);
      }
    } catch (_) {
      // لا تمنع فشل تحديث الحالة من إتمام تسجيل الخروج.
    }
    await _safeSignOut();
  }

  Future<void> _safeSignOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (_) {
      // تجاهل أخطاء تسجيل الخروج.
    }
  }

  /// هل هذا الخطأ ناتج عن مشكلة شبكة/انقطاع إنترنت؟
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
