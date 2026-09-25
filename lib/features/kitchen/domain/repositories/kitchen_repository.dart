import '../../../../domain/models/order.dart';
import '../../../../domain/models/order_item.dart';

abstract interface class KitchenRepository {
  Future<List<RestaurantOrder>> getKitchenOrders();

  Future<RestaurantOrder?> getOrder(int id);

  Future<List<OrderItem>> getOrderItems(int orderId);

  Future<void> updateOrderStatus(
    int orderId,
    OrderStatus status, {
    String note = '',
  });
}
