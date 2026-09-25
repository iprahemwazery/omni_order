import '../../../../domain/models/order.dart';
import '../../../../domain/models/order_item.dart';
import '../repositories/kitchen_repository.dart';

class GetKitchenOrders {
  const GetKitchenOrders(this._repository);

  final KitchenRepository _repository;

  Future<List<RestaurantOrder>> call() async {
    final orders = await _repository.getKitchenOrders();
    return orders
        .where(
          (order) => const {
            OrderStatus.pending,
            OrderStatus.preparing,
            OrderStatus.ready,
          }.contains(order.orderStatus),
        )
        .toList(growable: false);
  }
}

class GetKitchenOrderItems {
  const GetKitchenOrderItems(this._repository);

  final KitchenRepository _repository;

  Future<List<OrderItem>> call(int orderId) {
    _requirePositiveId(orderId);
    return _repository.getOrderItems(orderId);
  }
}

class UpdateKitchenOrderStatus {
  const UpdateKitchenOrderStatus(this._repository);

  final KitchenRepository _repository;

  Future<void> call(int orderId, OrderStatus status, {String note = ''}) async {
    _requirePositiveId(orderId);
    if (!_kitchenStatuses.contains(status)) {
      throw ArgumentError.value(status, 'status', 'is invalid for kitchen');
    }
    final order = await _repository.getOrder(orderId);
    if (order == null) {
      throw StateError('Kitchen order $orderId was not found');
    }
    if (order.orderStatus == status) return;
    if (!_canTransition(order.orderStatus, status)) {
      throw StateError(
        'Cannot change order $orderId from ${order.orderStatus.name} to ${status.name}',
      );
    }
    await _repository.updateOrderStatus(orderId, status, note: note.trim());
  }
}

const _kitchenStatuses = <OrderStatus>{
  OrderStatus.preparing,
  OrderStatus.ready,
  OrderStatus.served,
  OrderStatus.cancelled,
};

bool _canTransition(OrderStatus from, OrderStatus to) {
  if (to == OrderStatus.cancelled) {
    return from == OrderStatus.pending ||
        from == OrderStatus.preparing ||
        from == OrderStatus.ready;
  }
  switch (from) {
    case OrderStatus.pending:
      return to == OrderStatus.preparing;
    case OrderStatus.preparing:
      return to == OrderStatus.ready;
    case OrderStatus.ready:
      return to == OrderStatus.served;
    case OrderStatus.served:
    case OrderStatus.outForDelivery:
    case OrderStatus.delivered:
    case OrderStatus.handedOver:
    case OrderStatus.awaitingPayment:
    case OrderStatus.paid:
    case OrderStatus.cancelled:
      return false;
  }
}

void _requirePositiveId(int id) {
  if (id <= 0) {
    throw ArgumentError.value(id, 'id', 'must be greater than zero');
  }
}
