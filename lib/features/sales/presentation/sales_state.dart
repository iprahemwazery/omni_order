import 'package:equatable/equatable.dart';

import '../../../../core/constants/payment_methods.dart';
import '../../../../domain/models/sale.dart';
import '../../../../domain/models/summaries.dart';

/// حالة سجل المبيعات والملخصات.
///
/// [sales] قائمة محدودة لأحدث الفواتير (شاشة السجل)، بينما الأرقام
/// الإجمالية في [totals] محسوبة داخل قاعدة البيانات بـ SQL حتى لا نحمل
/// آلاف السجلات إلى الذاكرة عند ضغط العمليات المرتفع.
class SalesState extends Equatable {
  const SalesState({
    this.sales = const [],
    this.totals = const SalesTotals(),
    this.loading = false,
    this.error,
  });

  final List<Sale> sales;
  final SalesTotals totals;
  final bool loading;
  final String? error;

  // ---- إجماليات من ملخص SQL (اليوم/الشهر/الإجمالي) ----

  double get totalRevenue => totals.total;
  double get totalCashRevenue => totals.totalCash;
  double get totalDeferred => totals.totalDeferred;
  double get monthRevenue => totals.month;
  double get monthCashRevenue => totals.cashMonth;
  double get monthDeferred => totals.deferredMonth;

  /// مبيعات يوم محدد (تُستخدم لليوم الحالي فقط — دائمًا ضمن القائمة الحديثة).
  double revenueOn(DateTime day) => sales
      .where((s) => !s.refunded && _sameDay(s.createdAt, day))
      .fold(0.0, (sum, s) => sum + s.total);

  /// المبيعات الآجلة ليوم محدد.
  double deferredOn(DateTime day) => sales
      .where(
        (s) =>
            !s.refunded &&
            s.paymentMethod == PaymentMethod.deferred &&
            _sameDay(s.createdAt, day),
      )
      .fold(0.0, (sum, s) => sum + s.total);

  /// إيرادات اليوم المحققة نقدًا/محفظة/تحويل (بدون الآجل).
  double cashRevenueOn(DateTime day) => revenueOn(day) - deferredOn(day);

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  SalesState copyWith({
    List<Sale>? sales,
    SalesTotals? totals,
    bool? loading,
    String? error,
  }) {
    return SalesState(
      sales: sales ?? this.sales,
      totals: totals ?? this.totals,
      loading: loading ?? this.loading,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [sales, totals, loading, error];
}
