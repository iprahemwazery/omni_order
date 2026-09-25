/// طبقة الأخطاء الموحدة (Core).
///
/// العقد بين الطبقات:
/// - طبقة البيانات ترمي [AppException] عندما تعرف رسالة صالحة لعرضها
///   على المستخدم (مثلًا "لم يتم فتح قاعدة البيانات بعد.")، أو أي استثناء
///   تقني آخر (SqfliteException، SocketException...).
/// - طبقات الأعلى تحوّل ما التقطته إلى [Failure] عبر [Failure.from] ثم
///   تعرض `message` (عربي جاهز للعرض) وتسجّل `cause` التقني فقط.
library;

/// استثناء يعرفه التطبيق ويحمل رسالة عربية آمنة للعرض.
class AppException implements Exception {
  const AppException(this.userMessage, {this.cause});

  final String userMessage;

  /// الخطأ التقني الأصلي إن وُجد (للتسجيل فقط).
  final Object? cause;

  @override
  String toString() => 'AppException($userMessage)';
}

/// تمثيل محايد لخطأ داخل حدود التطبيق (لا يتسرب نوعه التقني للعرض).
sealed class Failure implements Exception {
  const Failure(this.message, {this.cause});

  /// رسالة عربية جاهزة للعرض على المستخدم.
  final String message;

  /// الخطأ التقني الأصلي (للتسجيل فقط، لا يُعرض للمستخدم).
  final Object? cause;

  @override
  String toString() => '$runtimeType($message)';

  /// يحوّل أي خطأ ملتقط إلى [Failure] مناسب حسب نوعه،
  /// مع رسالة احتياطية للأخطاء غير المعروفة.
  factory Failure.from(Object error, {String fallback = unexpectedMessage}) {
    if (error is Failure) return error;
    if (error is AppException) return UnknownFailure(error.userMessage, cause: error.cause ?? error);
    if (_isNetworkError(error)) {
      return const NetworkFailure(networkMessage);
    }
    if (_isStorageError(error)) {
      return CacheFailure('تعذر الوصول إلى البيانات المحلية.', cause: error);
    }
    if (error is FormatException) {
      return ValidationFailure('البيانات المدخلة غير صالحة.', cause: error);
    }
    return UnknownFailure(fallback, cause: error);
  }

  static const String networkMessage =
      'تعذر الاتصال بالإنترنت. تأكد من اتصالك وحاول مرة أخرى.';
  static const String unexpectedMessage = 'حدث خطأ غير متوقع. حاول مرة أخرى.';

  static bool _isNetworkError(Object error) {
    // بمقارنة اسم النوع نتجنب استيراد dart:io/dart:async ليبقى الملف
    // صالحًا على كل المنصات (بما فيها الويب).
    const markers = [
      'SocketException',
      'ClientException',
      'TimeoutException',
      'HttpException',
      'ConnectionClosedException',
    ];
    final type = error.runtimeType.toString();
    return markers.any(type.contains);
  }

  static bool _isStorageError(Object error) {
    const markers = ['DatabaseException', 'Sqflite', 'FileSystemException'];
    final type = error.runtimeType.toString();
    return markers.any(type.contains);
  }
}

/// خطأ في التخزين المحلي/قاعدة البيانات.
class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.cause});
}

/// خطأ في الشبكة أو الاتصال بالخدمات البعيدة.
class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.cause});
}

/// خطأ تحقق من مدخلات.
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.cause});
}

/// العنصر المطلوب غير موجود.
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message, {super.cause});
}

/// فشل مصادقة أو نقص صلاحيات.
class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.cause});
}

/// خطأ غير مصنف (رسالة احتياطية).
class UnknownFailure extends Failure {
  const UnknownFailure(super.message, {super.cause});
}

/// يستخرج رسالة عربية آمنة للعرض من أي خطأ ملتقط،
/// مع الرجوع للرسالة الاحتياطية عند الخطأ غير المعروف.
String failureMessage(Object error, String fallback) {
  return Failure.from(error, fallback: fallback).message;
}
