import 'package:equatable/equatable.dart';
import 'package:omni_order/domain/models/license.dart';

/// مراحل حالة الترخيص في الواجهة:
/// - [checking]: جارٍ التحقق من التفعيل المحلي.
/// - [notActivated]: لا يوجد تفعيل صالح -> تُعرض شاشة إدخال المفتاح.
/// - [granted]: الترخيص صالح (أونلاين أو أوفلاين) -> يُكمل التطبيق.
/// - [rejected]: الرفض مع رسالة عربية محددة (معطل/انتهى/جهاز آخر/تلاعب).
enum LicenseStage { checking, notActivated, granted, rejected }

/// حالة الترخيص المعروضة في شاشة التفعيل.
class LicenseState extends Equatable {
  const LicenseState({
    this.stage = LicenseStage.checking,
    this.license,
    this.message,
  });

  final LicenseStage stage;
  final License? license;

  /// رسالة عربية جاهزة للمستخدم (تُعرض في شاشة التفعيل).
  final String? message;

  /// هل الترخيص صالح ويُسمح بالاستخدام؟
  bool get isGranted => stage == LicenseStage.granted;

  @override
  List<Object?> get props => [stage, license, message];
}
