import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/employee.dart';
import '../../../domain/models/order.dart';
import '../../../domain/models/rider_transaction.dart';
import '../../../domain/repositories/store_repository.dart';
import '../domain/usecases/rider_balance_usecases.dart';

class RiderBalanceState {
  final List<Employee> riders;
  final Map<int, double> balances;
  final Map<int, List<RiderTransaction>> transactions;
  final Map<int, List<RestaurantOrder>> outstandingOrders;
  final bool loading;
  final String? error;

  const RiderBalanceState({
    this.riders = const [],
    this.balances = const {},
    this.transactions = const {},
    this.outstandingOrders = const {},
    this.loading = false,
    this.error,
  });

  RiderBalanceState copyWith({
    List<Employee>? riders,
    Map<int, double>? balances,
    Map<int, List<RiderTransaction>>? transactions,
    Map<int, List<RestaurantOrder>>? outstandingOrders,
    bool? loading,
    String? error,
  }) {
    return RiderBalanceState(
      riders: riders ?? this.riders,
      balances: balances ?? this.balances,
      transactions: transactions ?? this.transactions,
      outstandingOrders: outstandingOrders ?? this.outstandingOrders,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class RiderBalanceCubit extends Cubit<RiderBalanceState> {
  RiderBalanceCubit(
    this._repository, {
    GetRiderBalanceData? getRiderBalanceData,
    RecordRiderSettlement? recordRiderSettlement,
    RecordRiderAdvance? recordRiderAdvance,
  }) : _getRiderBalanceData = getRiderBalanceData,
       _recordRiderSettlement = recordRiderSettlement,
       _recordRiderAdvance = recordRiderAdvance,
       super(const RiderBalanceState());

  final StoreRepository _repository;
  final GetRiderBalanceData? _getRiderBalanceData;
  final RecordRiderSettlement? _recordRiderSettlement;
  final RecordRiderAdvance? _recordRiderAdvance;

  Future<void> init() async {
    emit(state.copyWith(loading: true));
    try {
      if (_getRiderBalanceData != null) {
        final data = await _getRiderBalanceData();
        emit(
          RiderBalanceState(
            riders: data.riders,
            balances: data.balances,
            transactions: data.transactions,
            outstandingOrders: data.outstandingOrders,
          ),
        );
        return;
      }
      final employees = await _repository.getEmployees();
      final riders = employees
          .where((e) => e.role == EmployeeRole.delivery && e.isActive)
          .toList();

      final balances = <int, double>{};
      final transactions = <int, List<RiderTransaction>>{};
      final outstanding = <int, List<RestaurantOrder>>{};

      for (final rider in riders) {
        final id = rider.id!;
        balances[id] = await _repository.getRiderBalance(id);
        transactions[id] = await _repository.getRiderTransactions(id);
        outstanding[id] = await _repository.getRiderOutstandingOrders(id);
      }

      emit(
        RiderBalanceState(
          riders: riders,
          balances: balances,
          transactions: transactions,
          outstandingOrders: outstanding,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          loading: false,
          error: 'تعذر تحميل بيانات المندوبين: $e',
        ),
      );
    }
  }

  Future<void> addSettlement(
    int riderId,
    double amount, {
    String note = '',
  }) async {
    try {
      if (_recordRiderSettlement != null) {
        await _recordRiderSettlement(riderId, amount, note: note);
      } else {
        await _repository.addRiderTransaction(
          RiderTransaction(
            riderId: riderId,
            type: RiderTransactionType.settlement,
            amount: amount,
            note: note,
          ),
        );
      }
      await init();
    } catch (e) {
      emit(state.copyWith(error: 'تعذر تسجيل التسديد: $e'));
    }
  }

  Future<void> addAdvance(
    int riderId,
    double amount, {
    String note = '',
  }) async {
    try {
      if (_recordRiderAdvance != null) {
        await _recordRiderAdvance(riderId, amount, note: note);
      } else {
        await _repository.addRiderTransaction(
          RiderTransaction(
            riderId: riderId,
            type: RiderTransactionType.advance,
            amount: amount,
            note: note,
          ),
        );
      }
      await init();
    } catch (e) {
      emit(state.copyWith(error: 'تعذر تسجيل السلفة: $e'));
    }
  }
}
