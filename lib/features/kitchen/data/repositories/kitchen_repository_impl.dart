import '../../../../domain/models/order.dart';
import '../../../../domain/models/order_item.dart';
import '../../../../domain/repositories/store_repository.dart';
import '../../domain/repositories/kitchen_repository.dart';

class KitchenRepositoryImpl implements KitchenRepository {
  const KitchenRepositoryImpl(this._storeRepository);

  final StoreRepository _storeRepository;

  @override
  Future<List<RestaurantOrder>> getKitchenOrders() =>
      _storeRepository.getKitchenOrders();

  @override
  Future<RestaurantOrder?> getOrder(int id) => _storeRepository.getOrder(id);

  @override
  Future<List<OrderItem>> getOrderItems(int orderId) =>
      _storeRepository.getOrderItems(orderId);

  @override
  Future<void> updateOrderStatus(
    int orderId,
    OrderStatus status, {
    String note = '',
  }) {
    return _storeRepository.updateOrderStatus(orderId, status, note: note);
  }
}
