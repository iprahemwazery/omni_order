import 'package:supabase_flutter/supabase_flutter.dart';

/// إعدادات الاتصال بـ Supabase.
///
/// ضع هنا بيانات مشروعك من لوحة Supabase:
/// Project Settings → API → Project URL و anon public key.
abstract final class SupabaseConfig {
  static bool _initialized = false;

  /// من لوحة Supabase: Project Settings → API → Project URL
  static const String url = 'https://zygdpsyajyezqnbxcjrz.supabase.co';

  /// من لوحة Supabase: Project Settings → API → anon public key
  static const String publishableKey =
      'sb_publishable_HY0Hm9S9C0tHqVRoST3Iow_MPztX-89';

  /// هل وُضعت البيانات الفعلية أم لا تزال القيم الافتراضية؟
  static bool get isConfigured =>
      !url.contains('YOUR_PROJECT') && !publishableKey.contains('YOUR_ANON');

  /// هل اكتملت تهيئة Supabase فعليًا (يُستدعى من main)؟
  static bool get isReady => _initialized;

  /// يهيّئ Supabase مرة واحدة عند بدء التطبيق.
  /// يتجاهل التهيئة لو البيانات لم تُعبَّأ بعد حتى لا ينهار التطبيق.
  static Future<void> initialize() async {
    if (!isConfigured || _initialized) return;
    await Supabase.initialize(url: url, publishableKey: publishableKey);
    _initialized = true;
  }
}
