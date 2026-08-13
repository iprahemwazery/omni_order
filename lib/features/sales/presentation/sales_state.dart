import 'package:equatable/equatable.dart';

import '../../../../domain/models/sale.dart';

/// حالة سجل المبيعات والملخصات.
class SalesState extends Equatable {
  const SalesState({
    this.sales = const [],
    this.loading = false,
    this.error,
  });

  final List<Sale> sales;
  final bool loading;
  final String? error;

  /// الفواتير النشطة (باستثناء المرتجعات — لا تُحتسب في الإيرادات).
  List<Sale> get activeSales => sales.where((s) => !s.refunded).toList();

  double revenueOn(DateTime day) => activeSales
      .where((s) =>
          s.createdAt.year == day.year &&
          s.createdAt.month == day.month &&
          s.createdAt.day == day.day)
      .fold(0.0, (sum, s) => sum + s.total);

  double get totalRevenue => activeSales.fold(0.0, (sum, s) => sum + s.total);

  double get monthRevenue {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    return activeSales
        .where((s) => !s.createdAt.isBefore(monthStart))
        .fold(0.0, (sum, s) => sum + s.total);
  }

  // ---- الفواتير الآجلة تُعدّ مديونية وليست ربحًا محققًا ----

  List<Sale> get _deferredSales =>
      activeSales.where((s) => s.paymentMethod == 'آجل').toList();

  double deferredOn(DateTime day) => _deferredSales
      .where((s) =>
          s.createdAt.year == day.year &&
          s.createdAt.month == day.month &&
          s.createdAt.day == day.day)
      .fold(0.0, (sum, s) => sum + s.total);

  double get monthDeferred {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    return _deferredSales
        .where((s) => !s.createdAt.isBefore(monthStart))
        .fold(0.0, (sum, s) => sum + s.total);
  }

  double get totalDeferred => _deferredSales.fold(0.0, (sum, s) => sum + s.total);

  /// إيرادات اليوم المحققة نقدًا/محفظة/تحويل (بدون الآجل).
  double cashRevenueOn(DateTime day) => revenueOn(day) - deferredOn(day);

  double get monthCashRevenue => monthRevenue - monthDeferred;

  double get totalCashRevenue => totalRevenue - totalDeferred;

  SalesState copyWith({
    List<Sale>? sales,
    bool? loading,
    String? error,
  }) {
    return SalesState(
      sales: sales ?? this.sales,
      loading: loading ?? this.loading,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [sales, loading, error];
}
