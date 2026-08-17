import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:omni_order/data/services/license_service.dart';

import 'license_state.dart';

/// يدير حالة الترخيص ويتعامل مع الحالات الثلاث:
/// - Online Verified: تحقق/تفعيل ناجح عبر الإنترنت.
/// - Offline Verified: استرجاع صالح من التخزين المحلي المشفر.
/// - Invalid/Expired/Mismatch: رفض مع رسالة عربية واضحة.
class LicenseCubit extends Cubit<LicenseState> {
  LicenseCubit(this._service) : super(const LicenseState());

  final LicenseService _service;

  /// يفحص عند فتح التطبيق: إن وُجد تفعيل محلي صالح -> يُسمح بالدخول
  /// مباشرة (Offline Verified). وإلا تُعرض شاشة إدخال مفتاح الترخيص.
  Future<void> init() async {
    // بدون Supabase مهيأ (وضع التطوير) تُفتح البوابة مباشرة دون ترخيص.
    if (!_service.isReady) {
      emit(const LicenseState(stage: LicenseStage.granted));
      return;
    }

    final result = await _service.checkOffline();
    if (result.isSuccess) {
      emit(LicenseState(stage: LicenseStage.granted, license: result.license));
    } else {
      emit(const LicenseState(stage: LicenseStage.notActivated));
    }
  }

  /// تفعيل/تحقق أونلاين عبر دالة RPC في Supabase.
  /// يُرجع `null` عند النجاح أو رسالة عربية عند الفشل.
  Future<String?> activate(String licenseKey) async {
    final result = await _service.activateOrVerify(licenseKey);
    if (result.isSuccess) {
      emit(LicenseState(stage: LicenseStage.granted, license: result.license));
      return null;
    }
    emit(
      LicenseState(
        stage: LicenseStage.rejected,
        message: result.message,
      ),
    );
    return result.message;
  }

  /// إعادة التحقق من التفعيل المحلي (مثلاً بعد إيقاف الترخيص عن بُعد).
  Future<void> recheck() => init();
}
