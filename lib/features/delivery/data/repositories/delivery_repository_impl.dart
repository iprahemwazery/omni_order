import '../../../../domain/models/order.dart';
import '../../../../domain/models/rider_transaction.dart';
import '../../../../domain/repositories/store_repository.dart';
import '../../domain/repositories/delivery_repository.dart';

class DeliveryRepositoryImpl implements DeliveryRepository {
  const DeliveryRepositoryImpl(this._storeRepository);

  final StoreRepository _storeRepository;

  @override
  Future<List<RestaurantOrder>> getActiveDeliveryOrders() =>
      _storeRepository.getActiveDeliveryOrders();

  @override
  Future<RestaurantOrder?> getOrder(int id) => _storeRepository.getOrder(id);

  @override
  Future<void> updateOrderStatus(
    int orderId,
    OrderStatus status, {
    String note = '',
  }) {
    return _storeRepository.updateOrderStatus(orderId, status, note: note);
  }

  @override
  Future<int> addRiderTransaction(RiderTransaction transaction) =>
      _storeRepository.addRiderTransaction(transaction);
}
