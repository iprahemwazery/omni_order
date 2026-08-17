import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/error_utils.dart';
import '../../../../domain/repositories/store_repository.dart';
import 'shift_state.dart';

/// يدير وردية الكاشير: تحميل تقرير الوردية الحالية، بدء وردية جديدة،
/// وإغلاق الوردية بعد انتهاء المناوبة.
class ShiftCubit extends Cubit<ShiftState> {
  ShiftCubit(this._repository) : super(const ShiftState());

  final StoreRepository _repository;

  /// يحمّل الوردية الحالية (أو آخر وردية مغلقة) وتقريرها.
  Future<void> init(String cashierName) async {
    emit(const ShiftState(loading: true));
    await _load(cashierName);
  }

  /// يبدأ وردية مفتوحة الآن (إن لم تكن موجودة) ويعرض تقريرها.
  Future<String?> startShift(String cashierName) async {
    try {
      final shift = await _repository.ensureOpenShift(cashierName);
      final report = await _repository.getShiftReport(shift);
      emit(ShiftState(loading: false, shift: shift, report: report));
      return null;
    } catch (e) {
      return safeErrorMessage('تعذر بدء الوردية', e);
    }
  }

  Future<void> _load(String cashierName) async {
    try {
      final shift = await _repository.getLatestShift(cashierName);
      if (shift == null) {
        emit(const ShiftState(loading: false));
        return;
      }
      final report = await _repository.getShiftReport(shift);
      emit(ShiftState(loading: false, shift: shift, report: report));
    } catch (e) {
      emit(
        const ShiftState(loading: false).copyWith(
          error: safeErrorMessage('تعذر تحميل تقرير الوردية', e),
        ),
      );
    }
  }

  /// يُغلق الوردية المفتوحة ويعرض تقريرها النهائي. يعيد null عند النجاح.
  Future<String?> closeShift() async {
    final current = state.shift;
    if (current == null || current.closedAt != null) return null;
    try {
      final closed = await _repository.closeShift(current.cashierName);
      if (closed != null) {
        final report = await _repository.getShiftReport(closed);
        emit(ShiftState(loading: false, shift: closed, report: report));
        return null;
      }
      return 'لا توجد وردية مفتوحة للإغلاق.';
    } catch (e) {
      return safeErrorMessage('تعذر إغلاق الوردية', e);
    }
  }
}
