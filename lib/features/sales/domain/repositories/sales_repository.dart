import '../../../../domain/models/sale.dart';
import '../../../../domain/models/sale_item.dart';
import '../../../../domain/models/summaries.dart';

abstract interface class SalesRepository {
  Future<List<Sale>> getSales({int? limit});
  Future<Sale?> getSale(int id);
  Future<List<SaleItem>> getSaleItems(int saleId);
  Future<SalesTotals> getSalesTotals();
  Future<List<DailySaleTotals>> getDailySalesTotals(int days);
  Future<List<Sale>> getSalesOn(DateTime day);
  Future<List<DayHistoryEntry>> getDayHistory();
  Future<ProfitAnalytics> getProfitAnalytics();
  Future<List<TopProduct>> getTopProducts({int limit = 5});
  Future<int> createSale({required Sale sale, required List<SaleItem> items});
  Future<List<Sale>> getDeferredSales();
  Future<void> settleSale({
    required int saleId,
    required String paymentMethod,
    required double amountTendered,
  });
  Future<void> refundSale(int saleId);
}
