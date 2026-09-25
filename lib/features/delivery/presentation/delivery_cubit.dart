import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/order.dart';
import '../../../domain/models/rider_transaction.dart';
import '../../../domain/repositories/store_repository.dart';
import '../domain/usecases/delivery_usecases.dart';

class DeliveryState {
  final List<RestaurantOrder> activeOrders;
  final bool loading;
  final String? error;

  const DeliveryState({
    this.activeOrders = const [],
    this.loading = false,
    this.error,
  });

  DeliveryState copyWith({
    List<RestaurantOrder>? activeOrders,
    bool? loading,
    String? error,
  }) {
    return DeliveryState(
      activeOrders: activeOrders ?? this.activeOrders,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class DeliveryCubit extends Cubit<DeliveryState> {
  DeliveryCubit(
    this._repository, {
    GetActiveDeliveryOrders? getActiveDeliveryOrders,
    UpdateDeliveryStatus? updateDeliveryStatus,
    CompleteDelivery? completeDelivery,
  }) : _getActiveDeliveryOrders = getActiveDeliveryOrders,
       _updateDeliveryStatus = updateDeliveryStatus,
       _completeDelivery = completeDelivery,
       super(const DeliveryState());

  final StoreRepository _repository;
  final GetActiveDeliveryOrders? _getActiveDeliveryOrders;
  final UpdateDeliveryStatus? _updateDeliveryStatus;
  final CompleteDelivery? _completeDelivery;

  Future<void> init() async {
    emit(state.copyWith(loading: true));
    try {
      final orders =
          await (_getActiveDeliveryOrders?.call() ??
              _repository.getActiveDeliveryOrders());
      emit(DeliveryState(activeOrders: orders));
    } catch (e) {
      emit(
        state.copyWith(loading: false, error: 'تعذر تحميل طلبات التوصيل: $e'),
      );
    }
  }

  Future<void> updateOrderStatus(int orderId, OrderStatus status) async {
    final isComplete =
        status == OrderStatus.delivered || status == OrderStatus.handedOver;
    if (isComplete && _completeDelivery != null) {
      await _completeDelivery(orderId, status);
    } else {
      if (isComplete) {
        await _repository.updateOrderStatus(orderId, status);
        final order = await _repository.getOrder(orderId);
        if (order != null && order.riderId != null && order.total > 0) {
          await _repository.addRiderTransaction(
            RiderTransaction(
              riderId: order.riderId!,
              type: RiderTransactionType.orderCollection,
              amount: order.total,
              orderId: order.id,
              note: 'أوردر #$orderId',
            ),
          );
        }
      } else if (_updateDeliveryStatus != null) {
        await _updateDeliveryStatus(orderId, status);
      } else {
        await _repository.updateOrderStatus(orderId, status);
      }
    }

    await init();
  }
}
