import '../../../../domain/models/order.dart';
import '../../../../domain/models/order_item.dart';

abstract interface class OrdersRepository {
  Future<List<RestaurantOrder>> getOrders({
    int? limit,
    OrderStatus? status,
    OrderType? orderType,
  });

  Future<RestaurantOrder?> getOrder(int id);

  Future<List<OrderItem>> getOrderItems(int orderId);

  Future<int> createOrder({
    required RestaurantOrder order,
    required List<OrderItem> items,
  });

  Future<void> updateOrderStatus(
    int orderId,
    OrderStatus status, {
    String note = '',
  });

  Future<void> cancelOrder(int orderId);
}
