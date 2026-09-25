import '../../../../domain/models/order.dart';
import '../../../../domain/models/restaurant_table.dart';
import '../../../../domain/repositories/store_repository.dart';
import '../../domain/repositories/tables_repository.dart';

class TablesRepositoryImpl implements TablesRepository {
  const TablesRepositoryImpl(this._storeRepository);

  final StoreRepository _storeRepository;

  @override
  Future<List<RestaurantTable>> getTables() => _storeRepository.getTables();

  @override
  Future<List<RestaurantTable>> getTablesByHall(int hallId) =>
      _storeRepository.getTablesByHall(hallId);

  @override
  Future<RestaurantTable?> getTable(int id) => _storeRepository.getTable(id);

  @override
  Future<int> addTable(RestaurantTable table) =>
      _storeRepository.addTable(table);

  @override
  Future<void> updateTable(RestaurantTable table) =>
      _storeRepository.updateTable(table);

  @override
  Future<void> deleteTable(int id) => _storeRepository.deleteTable(id);

  @override
  Future<void> updateTableStatus(
    int tableId,
    TableStatus status, {
    int? orderId,
  }) {
    return _storeRepository.updateTableStatus(
      tableId,
      status,
      orderId: orderId,
    );
  }

  @override
  Future<List<RestaurantOrder>> getTableOrders(int tableId) =>
      _storeRepository.getTableOrders(tableId);

  @override
  Future<double> payTable(int tableId, String paymentMethod) =>
      _storeRepository.payTable(tableId, paymentMethod);
}
