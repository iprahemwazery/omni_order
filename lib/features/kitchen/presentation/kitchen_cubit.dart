import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/order.dart';
import '../../../domain/repositories/store_repository.dart';
import '../domain/usecases/kitchen_usecases.dart';

class KitchenState {
  final List<RestaurantOrder> orders;
  final bool loading;
  final String? error;
  final int newOrderCount;

  const KitchenState({
    this.orders = const [],
    this.loading = false,
    this.error,
    this.newOrderCount = 0,
  });

  KitchenState copyWith({
    List<RestaurantOrder>? orders,
    bool? loading,
    String? error,
    int? newOrderCount,
  }) {
    return KitchenState(
      orders: orders ?? this.orders,
      loading: loading ?? this.loading,
      error: error,
      newOrderCount: newOrderCount ?? this.newOrderCount,
    );
  }
}

class KitchenCubit extends Cubit<KitchenState> {
  KitchenCubit(
    this._repository, {
    GetKitchenOrders? getKitchenOrders,
    UpdateKitchenOrderStatus? updateKitchenOrderStatus,
  }) : _getKitchenOrders = getKitchenOrders,
       _updateKitchenOrderStatus = updateKitchenOrderStatus,
       super(const KitchenState());

  final StoreRepository _repository;
  final GetKitchenOrders? _getKitchenOrders;
  final UpdateKitchenOrderStatus? _updateKitchenOrderStatus;
  Timer? _refreshTimer;
  int _previousOrderCount = 0;

  static const Duration _refreshInterval = Duration(seconds: 5);

  Future<void> init() async {
    emit(state.copyWith(loading: true));
    try {
      final orders =
          await (_getKitchenOrders?.call() ?? _repository.getKitchenOrders());
      _previousOrderCount = orders.length;
      emit(KitchenState(orders: orders));
    } catch (e) {
      emit(
        state.copyWith(loading: false, error: 'تعذر تحميل طلبات المطبخ: $e'),
      );
    }
  }

  void startAutoRefresh() {
    stopAutoRefresh();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) async {
      try {
        final orders =
            await (_getKitchenOrders?.call() ?? _repository.getKitchenOrders());
        final newCount = orders.length - _previousOrderCount;
        _previousOrderCount = orders.length;
        emit(
          KitchenState(
            orders: orders,
            newOrderCount: newCount > 0 ? newCount : 0,
          ),
        );
      } catch (_) {}
    });
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  void clearNewOrderNotification() {
    emit(state.copyWith(newOrderCount: 0));
  }

  Future<void> updateOrderStatus(int orderId, OrderStatus status) async {
    if (_updateKitchenOrderStatus != null) {
      await _updateKitchenOrderStatus(
        orderId,
        status,
        note: _statusNote(status),
      );
    } else {
      await _repository.updateOrderStatus(
        orderId,
        status,
        note: _statusNote(status),
      );
    }
    await init();
  }

  String _statusNote(OrderStatus status) {
    switch (status) {
      case OrderStatus.preparing:
        return 'بدأت التحضير في المطبخ';
      case OrderStatus.ready:
        return 'الطلب جاهز للتقديم';
      case OrderStatus.served:
        return 'تم التقديم للعميل';
      case OrderStatus.cancelled:
        return 'تم إلغاء الطلب';
      default:
        return '';
    }
  }

  @override
  Future<void> close() {
    stopAutoRefresh();
    return super.close();
  }
}
