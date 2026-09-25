import '../../../../domain/models/order.dart';
import '../../../../domain/models/order_item.dart';
import '../../../../domain/models/restaurant_table.dart';

abstract interface class WaiterRepository {
  Future<List<RestaurantTable>> getTables();

  Future<RestaurantTable?> getTable(int id);

  Future<int> createOrder({
    required RestaurantOrder order,
    required List<OrderItem> items,
  });
}
