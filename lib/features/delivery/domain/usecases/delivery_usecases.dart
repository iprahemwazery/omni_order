import '../../../../domain/models/order.dart';
import '../../../../domain/models/rider_transaction.dart';
import '../repositories/delivery_repository.dart';

class GetActiveDeliveryOrders {
  const GetActiveDeliveryOrders(this._repository);

  final DeliveryRepository _repository;

  Future<List<RestaurantOrder>> call() => _repository.getActiveDeliveryOrders();
}

class UpdateDeliveryStatus {
  const UpdateDeliveryStatus(this._repository);

  final DeliveryRepository _repository;

  Future<void> call(int orderId, OrderStatus status, {String note = ''}) async {
    _requirePositiveId(orderId);
    if (!_deliveryStatuses.contains(status)) {
      throw ArgumentError.value(status, 'status', 'is invalid for delivery');
    }
    final order = await _repository.getOrder(orderId);
    if (order == null) {
      throw StateError('Delivery order $orderId was not found');
    }
    if (!order.isDelivery) {
      throw StateError('Order $orderId is not a delivery order');
    }
    if (order.orderStatus == status) return;
    await _repository.updateOrderStatus(orderId, status, note: note.trim());
  }
}

class CompleteDelivery {
  const CompleteDelivery(this._repository);

  final DeliveryRepository _repository;

  Future<void> call(int orderId, OrderStatus status, {String note = ''}) async {
    _requirePositiveId(orderId);
    if (status != OrderStatus.delivered && status != OrderStatus.handedOver) {
      throw ArgumentError.value(
        status,
        'status',
        'must be delivered or handedOver',
      );
    }
    final order = await _repository.getOrder(orderId);
    if (order == null) {
      throw StateError('Delivery order $orderId was not found');
    }
    if (!order.isDelivery) {
      throw StateError('Order $orderId is not a delivery order');
    }
    if (order.orderStatus == status) return;
    if (order.orderStatus == OrderStatus.cancelled) {
      throw StateError('Cancelled order $orderId cannot be completed');
    }

    await _repository.updateOrderStatus(orderId, status, note: note.trim());

    final riderId = order.riderId;
    if (riderId != null && order.total > 0) {
      await _repository.addRiderTransaction(
        RiderTransaction(
          riderId: riderId,
          type: RiderTransactionType.orderCollection,
          amount: order.total,
          orderId: orderId,
          note: 'Order #$orderId',
        ),
      );
    }
  }
}

const _deliveryStatuses = <OrderStatus>{
  OrderStatus.preparing,
  OrderStatus.ready,
  OrderStatus.outForDelivery,
  OrderStatus.delivered,
  OrderStatus.handedOver,
  OrderStatus.cancelled,
};

void _requirePositiveId(int id) {
  if (id <= 0) {
    throw ArgumentError.value(id, 'id', 'must be greater than zero');
  }
}
