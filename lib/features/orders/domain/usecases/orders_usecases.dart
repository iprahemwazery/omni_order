import '../../../../domain/models/order.dart';
import '../../../../domain/models/order_item.dart';
import '../repositories/orders_repository.dart';

class OrderDetails {
  const OrderDetails({required this.order, required this.items});

  final RestaurantOrder order;
  final List<OrderItem> items;
}

class GetOrders {
  const GetOrders(this._repository);

  final OrdersRepository _repository;

  Future<List<RestaurantOrder>> call({
    int? limit,
    OrderStatus? status,
    OrderType? orderType,
  }) {
    if (limit != null && limit <= 0) {
      throw ArgumentError.value(limit, 'limit', 'must be greater than zero');
    }
    return _repository.getOrders(
      limit: limit,
      status: status,
      orderType: orderType,
    );
  }
}

class GetOrderDetails {
  const GetOrderDetails(this._repository);

  final OrdersRepository _repository;

  Future<OrderDetails> call(int orderId) async {
    _requirePositiveId(orderId);
    final order = await _repository.getOrder(orderId);
    if (order == null) {
      throw StateError('Order $orderId was not found');
    }
    final items = await _repository.getOrderItems(orderId);
    return OrderDetails(order: order, items: items);
  }
}

class CreateOrder {
  const CreateOrder(this._repository);

  final OrdersRepository _repository;

  Future<int> call({
    required RestaurantOrder order,
    required List<OrderItem> items,
  }) {
    if (!order.total.isFinite || order.total < 0) {
      throw ArgumentError.value(order.total, 'total', 'must be valid');
    }
    if (!OrderType.values.any((value) => value.name == order.orderType)) {
      throw ArgumentError.value(order.orderType, 'orderType', 'is invalid');
    }
    if (items.isEmpty) {
      throw ArgumentError.value(items, 'items', 'must not be empty');
    }
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
    }
    return _repository.createOrder(
      order: order.copyWith(
        status: OrderStatus.pending.name,
        total: order.total,
      ),
      items: items,
    );
  }
}

class UpdateOrderStatus {
  const UpdateOrderStatus(this._repository);

  final OrdersRepository _repository;

  Future<void> call(int orderId, OrderStatus status, {String note = ''}) async {
    _requirePositiveId(orderId);
    final order = await _repository.getOrder(orderId);
    if (order == null) {
      throw StateError('Order $orderId was not found');
    }
    if (order.orderStatus == status) return;
    await _repository.updateOrderStatus(orderId, status, note: note.trim());
  }
}

class CancelOrder {
  const CancelOrder(this._repository);

  final OrdersRepository _repository;

  Future<void> call(int orderId) async {
    _requirePositiveId(orderId);
    final order = await _repository.getOrder(orderId);
    if (order == null) {
      throw StateError('Order $orderId was not found');
    }
    if (order.orderStatus == OrderStatus.cancelled) return;
    await _repository.cancelOrder(orderId);
  }
}

void _requirePositiveId(int id) {
  if (id <= 0) {
    throw ArgumentError.value(id, 'id', 'must be greater than zero');
  }
}
