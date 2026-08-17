import 'package:flutter/foundation.dart';

/// يسجّل تفاصيل الخطأ التقنية في السجل (للأخطاء أثناء التطوير)،
/// ويعيد رسالة عربية ثابتة لا تكشف تفاصيل داخلية للمستخدم.
String safeErrorMessage(String fallback, Object error) {
  debugPrint('OmniOrder error: $error');
  return fallback;
}
