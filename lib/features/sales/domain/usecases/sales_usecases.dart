import '../../../../domain/models/sale.dart';
import '../../../../domain/models/sale_item.dart';
import '../../../../domain/models/summaries.dart';
import '../repositories/sales_repository.dart';

class GetSalesUseCase {
  const GetSalesUseCase(this._repository);

  final SalesRepository _repository;

  Future<List<Sale>> call({int? limit}) {
    if (limit != null && limit <= 0) {
      throw ArgumentError.value(limit, 'limit', 'Must be positive');
    }
    return _repository.getSales(limit: limit);
  }
}

class GetSaleUseCase {
  const GetSaleUseCase(this._repository);

  final SalesRepository _repository;

  Future<Sale?> call(int id) {
    if (id <= 0) throw ArgumentError.value(id, 'id', 'Must be positive');
    return _repository.getSale(id);
  }
}

class GetSaleItemsUseCase {
  const GetSaleItemsUseCase(this._repository);

  final SalesRepository _repository;

  Future<List<SaleItem>> call(int saleId) {
    if (saleId <= 0) {
      throw ArgumentError.value(saleId, 'saleId', 'Must be positive');
    }
    return _repository.getSaleItems(saleId);
  }
}

class CreateSaleUseCase {
  const CreateSaleUseCase(this._repository);

  final SalesRepository _repository;

  Future<int> call({required Sale sale, required List<SaleItem> items}) async {
    if (!sale.total.isFinite || sale.total < 0) {
      throw ArgumentError.value(sale.total, 'total', 'Cannot be negative');
    }
    if (items.isEmpty) {
      throw ArgumentError.value(items, 'items', 'Cannot be empty');
    }
    for (final item in items) {
      if (item.productId <= 0) {
        throw ArgumentError.value(
          item.productId,
          'productId',
          'Must be positive',
        );
      }
      if (!item.quantity.isFinite || item.quantity <= 0) {
        throw ArgumentError.value(
          item.quantity,
          'quantity',
          'Must be positive',
        );
      }
    }
    return _repository.createSale(sale: sale, items: items);
  }
}

class GetSalesTotalsUseCase {
  const GetSalesTotalsUseCase(this._repository);

  final SalesRepository _repository;

  Future<SalesTotals> call() => _repository.getSalesTotals();
}

class GetDailySalesTotalsUseCase {
  const GetDailySalesTotalsUseCase(this._repository);

  final SalesRepository _repository;

  Future<List<DailySaleTotals>> call(int days) {
    if (days <= 0) {
      throw ArgumentError.value(days, 'days', 'Must be positive');
    }
    return _repository.getDailySalesTotals(days);
  }
}

class GetSalesOnDateUseCase {
  const GetSalesOnDateUseCase(this._repository);

  final SalesRepository _repository;

  Future<List<Sale>> call(DateTime day) => _repository.getSalesOn(day);
}

class GetDayHistoryUseCase {
  const GetDayHistoryUseCase(this._repository);

  final SalesRepository _repository;

  Future<List<DayHistoryEntry>> call() => _repository.getDayHistory();
}

class GetProfitAnalyticsUseCase {
  const GetProfitAnalyticsUseCase(this._repository);

  final SalesRepository _repository;

  Future<ProfitAnalytics> call() => _repository.getProfitAnalytics();
}

class GetTopProductsUseCase {
  const GetTopProductsUseCase(this._repository);

  final SalesRepository _repository;

  Future<List<TopProduct>> call({int limit = 5}) {
    if (limit <= 0) {
      throw ArgumentError.value(limit, 'limit', 'Must be positive');
    }
    return _repository.getTopProducts(limit: limit);
  }
}

class GetDeferredSalesUseCase {
  const GetDeferredSalesUseCase(this._repository);

  final SalesRepository _repository;

  Future<List<Sale>> call() => _repository.getDeferredSales();
}

class SettleSaleUseCase {
  const SettleSaleUseCase(this._repository);

  final SalesRepository _repository;

  Future<void> call({
    required int saleId,
    required String paymentMethod,
    required double amountTendered,
  }) {
    if (saleId <= 0) {
      throw ArgumentError.value(saleId, 'saleId', 'Must be positive');
    }
    final normalizedMethod = paymentMethod.trim();
    if (normalizedMethod.isEmpty) {
      throw ArgumentError.value(
        paymentMethod,
        'paymentMethod',
        'Cannot be empty',
      );
    }
    if (!amountTendered.isFinite || amountTendered < 0) {
      throw ArgumentError.value(
        amountTendered,
        'amountTendered',
        'Cannot be negative',
      );
    }
    return _repository.settleSale(
      saleId: saleId,
      paymentMethod: normalizedMethod,
      amountTendered: amountTendered,
    );
  }
}

class RefundSaleUseCase {
  const RefundSaleUseCase(this._repository);

  final SalesRepository _repository;

  Future<void> call(int saleId) {
    if (saleId <= 0) {
      throw ArgumentError.value(saleId, 'saleId', 'Must be positive');
    }
    return _repository.refundSale(saleId);
  }
}
