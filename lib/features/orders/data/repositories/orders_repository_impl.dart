import '../../../../domain/models/order.dart';
import '../../../../domain/models/order_item.dart';
import '../../../../domain/repositories/store_repository.dart';
import '../../domain/repositories/orders_repository.dart';

class OrdersRepositoryImpl implements OrdersRepository {
  const OrdersRepositoryImpl(this._storeRepository);

  final StoreRepository _storeRepository;

  @override
  Future<List<RestaurantOrder>> getOrders({
    int? limit,
    OrderStatus? status,
    OrderType? orderType,
  }) {
    return _storeRepository.getOrders(
      limit: limit,
      status: status?.name,
      orderType: orderType?.name,
    );
  }

  @override
  Future<RestaurantOrder?> getOrder(int id) => _storeRepository.getOrder(id);

  @override
  Future<List<OrderItem>> getOrderItems(int orderId) =>
      _storeRepository.getOrderItems(orderId);

  @override
  Future<int> createOrder({
    required RestaurantOrder order,
    required List<OrderItem> items,
  }) {
    return _storeRepository.createOrder(order: order, items: items);
  }

  @override
  Future<void> updateOrderStatus(
    int orderId,
    OrderStatus status, {
    String note = '',
  }) {
    return _storeRepository.updateOrderStatus(orderId, status, note: note);
  }

  @override
  Future<void> cancelOrder(int orderId) =>
      _storeRepository.cancelOrder(orderId);
}
