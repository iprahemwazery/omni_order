import '../../../../domain/models/order.dart';
import '../../../../domain/models/order_item.dart';
import '../../../../domain/models/restaurant_table.dart';
import '../../../../domain/repositories/store_repository.dart';
import '../../domain/repositories/waiter_repository.dart';

class WaiterRepositoryImpl implements WaiterRepository {
  const WaiterRepositoryImpl(this._storeRepository);

  final StoreRepository _storeRepository;

  @override
  Future<List<RestaurantTable>> getTables() => _storeRepository.getTables();

  @override
  Future<RestaurantTable?> getTable(int id) => _storeRepository.getTable(id);

  @override
  Future<int> createOrder({
    required RestaurantOrder order,
    required List<OrderItem> items,
  }) {
    return _storeRepository.createOrder(order: order, items: items);
  }
}
