import 'package:equatable/equatable.dart';

import '../../../../domain/models/shift.dart';

/// حالة تقرير الوردية (Z-Report).
class ShiftState extends Equatable {
  const ShiftState({
    this.loading = true,
    this.shift,
    this.report,
    this.error,
  });

  final bool loading;

  /// الوردية المعروضة (مفتوحة أو آخر وردية مغلقة).
  final Shift? shift;

  /// ملخص الوردية المعروضة.
  final ShiftReport? report;

  final String? error;

  bool get hasOpenShift => shift?.isOpen ?? false;

  ShiftState copyWith({
    bool? loading,
    Shift? shift,
    ShiftReport? report,
    String? error,
    bool clearError = false,
  }) {
    return ShiftState(
      loading: loading ?? this.loading,
      shift: shift ?? this.shift,
      report: report ?? this.report,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [loading, shift, report, error];
}
