import '../../../../domain/models/order.dart';
import '../../../../domain/models/rider_transaction.dart';

abstract interface class DeliveryRepository {
  Future<List<RestaurantOrder>> getActiveDeliveryOrders();

  Future<RestaurantOrder?> getOrder(int id);

  Future<void> updateOrderStatus(
    int orderId,
    OrderStatus status, {
    String note = '',
  });

  Future<int> addRiderTransaction(RiderTransaction transaction);
}
