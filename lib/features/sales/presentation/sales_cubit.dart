import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/error_utils.dart';
import '../../../../domain/models/sale.dart';
import '../../../../domain/models/sale_item.dart';
import '../../../../domain/models/summaries.dart';
import '../../../../domain/repositories/store_repository.dart';
import 'sales_state.dart';

/// يدير سجل المبيعات والملخصات وبنود الفواتير.
class SalesCubit extends Cubit<SalesState> {
  SalesCubit(this._repository) : super(const SalesState(loading: true));

  final StoreRepository _repository;

  /// عدد الفواتير المحمّلة في ذاكرة شاشة "المبيعات السابقة".
  static const int historyLimit = 500;

  Future<void> init() async {
    emit(const SalesState(loading: true));
    await refresh();
  }

  Future<void> refresh() async {
    try {
      final results = await Future.wait<Object>([
        _repository.getSales(limit: historyLimit),
        _repository.getSalesTotals(),
      ]);
      final sales = results[0] as List<Sale>;
      final totals = results[1] as SalesTotals;
      emit(SalesState(sales: sales, totals: totals));
    } catch (e) {
      emit(state.copyWith(error: safeErrorMessage('تعذر تحميل المبيعات', e)));
    }
  }

  /// بنود فاتورة معيّنة (تُحمَّل عند عرض الفاتورة).
  Future<List<SaleItem>> saleItemsOf(int saleId) =>
      _repository.getSaleItems(saleId);

  /// ملخص المبيعات محسوبًا داخل قاعدة البيانات (تُستخدم في التقارير).
  Future<SalesTotals> salesTotals() => _repository.getSalesTotals();

  /// أعلى الأصناف مبيعًا — تجميع GROUP BY داخل قاعدة البيانات.
  Future<List<TopProduct>> topProducts({int limit = 5}) =>
      _repository.topProducts(limit: limit);

  /// تحليل الربح (البيع المحقق وتكلفة البضاعة) — استعلام SQL واحد.
  Future<ProfitAnalytics> profitAnalytics() => _repository.getProfitAnalytics();

  /// فواتير يوم واحد (تقرير اليوم المنفصل).
  Future<List<Sale>> salesOn(DateTime day) => _repository.getSalesOn(day);

  /// أيام "الأيام السابقة" التي تحتوي بيانات.
  Future<List<DayHistoryEntry>> dayHistory() => _repository.getDayHistory();

  /// إجماليات يومية لرسم اتجاه المبيعات.
  Future<List<DailySaleTotals>> dailySalesTotals(int days) =>
      _repository.getDailySalesTotals(days);

  /// مرتجع فاتورة: يعيد المخزون ويمحو أثرها على المديونية ثم يعيد التحميل.
  /// تُستدعى بعده إعادة تحميل [ProductsCubit] و [CustomersCubit] من الواجهة.
  Future<String?> refundSale(Sale sale) async {
    if (sale.refunded) return 'هذه الفاتورة مرتجع بالفعل.';
    if (sale.id == null) return 'لا يمكن إرجاع هذه الفاتورة.';
    try {
      await _repository.refundSale(sale.id!);
      await refresh();
      return null;
    } catch (e) {
      return safeErrorMessage('تعذر تسجيل المرتجع', e);
    }
  }
}
