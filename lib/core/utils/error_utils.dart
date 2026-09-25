import 'package:flutter/foundation.dart';

import '../errors/failures.dart';

/// يسجّل تفاصيل الخطأ التقنية في السجل (للأخطاء أثناء التطوير)،
/// ويعيد رسالة عربية آمنة للمستخدم: رسالة [Failure]/[AppException] إن كانت
/// الخطأ من نوع معروف، وإلا الرسالة الاحتياطية الممررة.
String safeErrorMessage(String fallback, Object error) {
  debugPrint('OmniOrder error: $error');
  return failureMessage(error, fallback);
}
