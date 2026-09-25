import '../../../../domain/models/order.dart';
import '../../../../domain/models/order_item.dart';
import '../../../../domain/models/restaurant_table.dart';
import '../repositories/waiter_repository.dart';

class GetWaiterTables {
  const GetWaiterTables(this._repository);

  final WaiterRepository _repository;

  Future<List<RestaurantTable>> call({bool availableOnly = false}) async {
    final tables = await _repository.getTables();
    if (!availableOnly) return tables;
    return tables
        .where((table) => table.status == TableStatus.available)
        .toList(growable: false);
  }
}

class SubmitWaiterOrder {
  const SubmitWaiterOrder(this._repository);

  final WaiterRepository _repository;

  Future<int> call({
    required RestaurantOrder order,
    required List<OrderItem> items,
  }) async {
    final tableId = order.tableId;
    if (tableId == null || tableId <= 0) {
      throw ArgumentError.value(tableId, 'tableId', 'is invalid');
    }
    if (!order.total.isFinite || order.total < 0) {
      throw ArgumentError.value(order.total, 'total', 'must be valid');
    }
    if (items.isEmpty) {
      throw ArgumentError.value(items, 'items', 'must not be empty');
    }

    var calculatedTotal = 0.0;
    for (final item in items) {
      if (item.productId <= 0) {
        throw ArgumentError.value(item.productId, 'productId', 'is invalid');
      }
      if (!item.quantity.isFinite || item.quantity <= 0) {
        throw ArgumentError.value(
          item.quantity,
          'quantity',
          'must be greater than zero',
        );
      }
      if (!item.subtotal.isFinite || item.subtotal < 0) {
        throw ArgumentError.value(item.subtotal, 'subtotal', 'must be valid');
      }
      calculatedTotal += item.subtotal;
    }

    final table = await _repository.getTable(tableId);
    if (table == null) {
      throw StateError('Table $tableId was not found');
    }

    final total = order.total == 0 && calculatedTotal > 0
        ? calculatedTotal
        : order.total;
    return _repository.createOrder(
      order: order.copyWith(
        tableId: tableId,
        hallId: table.hallId,
        status: OrderStatus.pending.name,
        orderType: OrderType.hall.name,
        isTakeaway: false,
        total: total,
      ),
      items: items,
    );
  }
}
