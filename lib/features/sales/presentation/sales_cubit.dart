import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/models/sale.dart';
import '../../../../domain/repositories/store_repository.dart';
import '../../../../domain/models/sale_item.dart';
import 'sales_state.dart';

/// مخرجات "الأعلى مبيعًا": الاسم + الكمية + الإيرادات.
typedef TopProduct = ({String name, double quantity, double revenue});

/// يدير سجل المبيعات والملخصات وبنود الفواتير.
class SalesCubit extends Cubit<SalesState> {
  SalesCubit(this._repository) : super(const SalesState(loading: true));

  final StoreRepository _repository;

  Future<void> init() async {
    emit(const SalesState(loading: true));
    await refresh();
  }

  Future<void> refresh() async {
    try {
      final sales = await _repository.getSales();
      emit(SalesState(sales: sales));
    } catch (e) {
      emit(state.copyWith(error: 'تعذر تحميل المبيعات: $e'));
    }
  }

  /// بنود فاتورة معيّنة (تُحمَّل عند عرض الفاتورة).
  Future<List<SaleItem>> saleItemsOf(int saleId) =>
      _repository.getSaleItems(saleId);

  /// كل بنود الفواتير (تُستخدم لحساب تكلفة البضاعة في التقارير).
  Future<List<SaleItem>> allSaleItems() => _repository.getAllSaleItems();

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
      return 'تعذر تسجيل المرتجع: $e';
    }
  }

  /// أعلى الأصناف مبيعًا بالكمية — استعلام واحد على كل البنود.
  Future<List<TopProduct>> topProducts({int limit = 5}) async {
    final items = await _repository.getAllSaleItems();
    final totals = <String, (double, double)>{};
    for (final item in items) {
      final current = totals[item.name] ?? (0.0, 0.0);
      totals[item.name] = (
        current.$1 + item.quantity,
        current.$2 + item.subtotal,
      );
    }
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.$1.compareTo(a.value.$1));
    return [
      for (final entry in sorted.take(limit))
        (name: entry.key, quantity: entry.value.$1, revenue: entry.value.$2),
    ];
  }
}
