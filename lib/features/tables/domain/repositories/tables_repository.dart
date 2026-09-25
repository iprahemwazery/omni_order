import '../../../../domain/models/order.dart';
import '../../../../domain/models/restaurant_table.dart';

abstract interface class TablesRepository {
  Future<List<RestaurantTable>> getTables();

  Future<List<RestaurantTable>> getTablesByHall(int hallId);

  Future<RestaurantTable?> getTable(int id);

  Future<int> addTable(RestaurantTable table);

  Future<void> updateTable(RestaurantTable table);

  Future<void> deleteTable(int id);

  Future<void> updateTableStatus(
    int tableId,
    TableStatus status, {
    int? orderId,
  });

  Future<List<RestaurantOrder>> getTableOrders(int tableId);

  Future<double> payTable(int tableId, String paymentMethod);
}
