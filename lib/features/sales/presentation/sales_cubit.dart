import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/error_utils.dart';
import '../../../../domain/models/sale.dart';
import '../../../../domain/models/sale_item.dart';
import '../../../../domain/models/summaries.dart';
import '../../../../domain/repositories/store_repository.dart';
import '../domain/usecases/sales_usecases.dart';
import 'sales_state.dart';

/// يدير سجل المبيعات والملخصات وبنود الفواتير.
class SalesCubit extends Cubit<SalesState> {
  SalesCubit(
    this._repository, {
    GetSalesUseCase? getSales,
    GetSalesTotalsUseCase? getSalesTotals,
    GetSaleItemsUseCase? getSaleItems,
    RefundSaleUseCase? refundSale,
    SettleSaleUseCase? settleSale,
    GetDailySalesTotalsUseCase? getDailySalesTotals,
    GetSalesOnDateUseCase? getSalesOnDate,
    GetDayHistoryUseCase? getDayHistory,
    GetProfitAnalyticsUseCase? getProfitAnalytics,
    GetTopProductsUseCase? getTopProducts,
    GetDeferredSalesUseCase? getDeferredSales,
  }) : _getSales = getSales,
       _getSalesTotals = getSalesTotals,
       _getSaleItems = getSaleItems,
       _refundSale = refundSale,
       _settleSale = settleSale,
       _getDailySalesTotals = getDailySalesTotals,
       _getSalesOnDate = getSalesOnDate,
       _getDayHistory = getDayHistory,
       _getProfitAnalytics = getProfitAnalytics,
       _getTopProducts = getTopProducts,
       _getDeferredSales = getDeferredSales,
       super(const SalesState(loading: true));

  final StoreRepository _repository;
  final GetSalesUseCase? _getSales;
  final GetSalesTotalsUseCase? _getSalesTotals;
  final GetSaleItemsUseCase? _getSaleItems;
  final RefundSaleUseCase? _refundSale;
  final SettleSaleUseCase? _settleSale;
  final GetDailySalesTotalsUseCase? _getDailySalesTotals;
  final GetSalesOnDateUseCase? _getSalesOnDate;
  final GetDayHistoryUseCase? _getDayHistory;
  final GetProfitAnalyticsUseCase? _getProfitAnalytics;
  final GetTopProductsUseCase? _getTopProducts;
  final GetDeferredSalesUseCase? _getDeferredSales;

  /// عدد الفواتير المحمّلة في ذاكرة شاشة "المبيعات السابقة".
  static const int historyLimit = 500;

  Future<void> init() async {
    emit(const SalesState(loading: true));
    await refresh();
  }

  Future<void> refresh() async {
    try {
      final results = await Future.wait<Object>([
        _getSales?.call(limit: historyLimit) ??
            _repository.getSales(limit: historyLimit),
        _getSalesTotals?.call() ?? _repository.getSalesTotals(),
      ]);
      final sales = results[0] as List<Sale>;
      final totals = results[1] as SalesTotals;
      emit(SalesState(sales: sales, totals: totals));
    } catch (e) {
      emit(state.copyWith(error: safeErrorMessage('تعذر تحميل المبيعات', e)));
    }
  }

  /// بنود فاتورة معيّنة (تُحمَّل عند عرض الفاتورة).
  Future<List<SaleItem>> saleItemsOf(int saleId) async =>
      await (_getSaleItems?.call(saleId) ?? _repository.getSaleItems(saleId));

  /// ملخص المبيعات محسوبًا داخل قاعدة البيانات (تُستخدم في التقارير).
  Future<SalesTotals> salesTotals() async =>
      await (_getSalesTotals?.call() ?? _repository.getSalesTotals());

  /// أعلى الأصناف مبيعًا — تجميع GROUP BY داخل قاعدة البيانات.
  Future<List<TopProduct>> topProducts({int limit = 5}) =>
      _getTopProducts?.call(limit: limit) ??
      _repository.topProducts(limit: limit);

  /// تحليل الربح (البيع المحقق وتكلفة البضاعة) — استعلام SQL واحد.
  Future<ProfitAnalytics> profitAnalytics() =>
      _getProfitAnalytics?.call() ?? _repository.getProfitAnalytics();

  /// فواتير يوم واحد (تقرير اليوم المنفصل).
  Future<List<Sale>> salesOn(DateTime day) =>
      _getSalesOnDate?.call(day) ?? _repository.getSalesOn(day);

  /// أيام "الأيام السابقة" التي تحتوي بيانات.
  Future<List<DayHistoryEntry>> dayHistory() =>
      _getDayHistory?.call() ?? _repository.getDayHistory();

  /// إجماليات يومية لرسم اتجاه المبيعات.
  Future<List<DailySaleTotals>> dailySalesTotals(int days) =>
      _getDailySalesTotals?.call(days) ?? _repository.getDailySalesTotals(days);

  /// مرتجع فاتورة: يعيد المخزون ويمحو أثرها على المديونية ثم يعيد التحميل.
  /// تُستدعى بعده إعادة تحميل [ProductsCubit] و [SalesCubit] من الواجهة.
  Future<String?> refundSale(Sale sale) async {
    if (sale.refunded) return 'هذه الفاتورة مرتجع بالفعل.';
    if (sale.id == null) return 'لا يمكن إرجاع هذه الفاتورة.';
    try {
      if (_refundSale != null) {
        await _refundSale(sale.id!);
      } else {
        await _repository.refundSale(sale.id!);
      }
      await refresh();
      return null;
    } catch (e) {
      return safeErrorMessage('تعذر تسجيل المرتجع', e);
    }
  }

  /// سداد فاتورة آجلة: يغيّر طريقة الدفع ويحدّث المبلغ المدفوع ثم يعيد التحميل.
  Future<String?> settleSale({
    required Sale sale,
    required String paymentMethod,
    required double amountTendered,
  }) async {
    if (sale.id == null) return 'لا يمكن سداد هذه الفاتورة.';
    try {
      if (_settleSale != null) {
        await _settleSale(
          saleId: sale.id!,
          paymentMethod: paymentMethod,
          amountTendered: amountTendered,
        );
      } else {
        await _repository.settleSale(
          saleId: sale.id!,
          paymentMethod: paymentMethod,
          amountTendered: amountTendered,
        );
      }
      await refresh();
      return null;
    } catch (e) {
      return safeErrorMessage('تعذر سداد الفاتورة', e);
    }
  }

  /// جلب الفواتير الآجلة (الغير مسددة).
  Future<List<Sale>> getDeferredSales() =>
      _getDeferredSales?.call() ?? _repository.getDeferredSales();
}
