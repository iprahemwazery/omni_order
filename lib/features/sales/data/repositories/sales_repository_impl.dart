import '../../../../domain/models/sale.dart';
import '../../../../domain/models/sale_item.dart';
import '../../../../domain/models/summaries.dart';
import '../../../../domain/repositories/store_repository.dart';
import '../../domain/repositories/sales_repository.dart';

class SalesRepositoryImpl implements SalesRepository {
  SalesRepositoryImpl(this._storeRepository);

  final StoreRepository _storeRepository;

  @override
  Future<List<Sale>> getSales({int? limit}) =>
      _storeRepository.getSales(limit: limit);

  @override
  Future<Sale?> getSale(int id) => _storeRepository.getSale(id);

  @override
  Future<List<SaleItem>> getSaleItems(int saleId) =>
      _storeRepository.getSaleItems(saleId);

  @override
  Future<SalesTotals> getSalesTotals() => _storeRepository.getSalesTotals();

  @override
  Future<List<DailySaleTotals>> getDailySalesTotals(int days) =>
      _storeRepository.getDailySalesTotals(days);

  @override
  Future<List<Sale>> getSalesOn(DateTime day) =>
      _storeRepository.getSalesOn(day);

  @override
  Future<List<DayHistoryEntry>> getDayHistory() =>
      _storeRepository.getDayHistory();

  @override
  Future<ProfitAnalytics> getProfitAnalytics() =>
      _storeRepository.getProfitAnalytics();

  @override
  Future<List<TopProduct>> getTopProducts({int limit = 5}) =>
      _storeRepository.topProducts(limit: limit);

  @override
  Future<int> createSale({required Sale sale, required List<SaleItem> items}) =>
      _storeRepository.createSale(sale: sale, items: items);

  @override
  Future<List<Sale>> getDeferredSales() => _storeRepository.getDeferredSales();

  @override
  Future<void> settleSale({
    required int saleId,
    required String paymentMethod,
    required double amountTendered,
  }) => _storeRepository.settleSale(
    saleId: saleId,
    paymentMethod: paymentMethod,
    amountTendered: amountTendered,
  );

  @override
  Future<void> refundSale(int saleId) => _storeRepository.refundSale(saleId);
}
