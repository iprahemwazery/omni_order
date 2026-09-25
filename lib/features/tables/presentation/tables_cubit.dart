import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/hall.dart';
import '../../../domain/models/order.dart';
import '../../../domain/models/restaurant_table.dart';
import '../../../domain/repositories/store_repository.dart';
import '../../halls/domain/usecases/halls_usecases.dart';
import '../domain/usecases/tables_usecases.dart';

class TablesState {
  final List<RestaurantTable> tables;
  final List<Hall> halls;
  final int? selectedHallId;
  final bool loading;
  final String? error;

  const TablesState({
    this.tables = const [],
    this.halls = const [],
    this.selectedHallId,
    this.loading = false,
    this.error,
  });

  List<RestaurantTable> get filteredTables => selectedHallId == null
      ? tables
      : tables.where((t) => t.hallId == selectedHallId).toList();

  int get availableCount =>
      tables.where((t) => t.status == TableStatus.available).length;
  int get occupiedCount =>
      tables.where((t) => t.status == TableStatus.occupied).length;
  int get reservedCount =>
      tables.where((t) => t.status == TableStatus.reserved).length;

  TablesState copyWith({
    List<RestaurantTable>? tables,
    List<Hall>? halls,
    int? selectedHallId,
    bool? loading,
    String? error,
  }) {
    return TablesState(
      tables: tables ?? this.tables,
      halls: halls ?? this.halls,
      selectedHallId: selectedHallId ?? this.selectedHallId,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class TablesCubit extends Cubit<TablesState> {
  TablesCubit(
    this._repository, {
    GetTables? getTables,
    GetHalls? getHalls,
    GetTableOrders? getTableOrders,
    PayTable? payTable,
  }) : _getTables = getTables,
       _getHalls = getHalls,
       _getTableOrders = getTableOrders,
       _payTable = payTable,
       super(const TablesState());

  final StoreRepository _repository;
  final GetTables? _getTables;
  final GetHalls? _getHalls;
  final GetTableOrders? _getTableOrders;
  final PayTable? _payTable;

  Future<void> init() async {
    emit(state.copyWith(loading: true));
    try {
      final tables = await (_getTables?.call() ?? _repository.getTables());
      final halls = await (_getHalls?.call() ?? _repository.getHalls());
      emit(TablesState(tables: tables, halls: halls));
    } catch (e) {
      emit(state.copyWith(loading: false, error: 'تعذر تحميل الترابيزات: $e'));
    }
  }

  void selectHall(int? hallId) {
    emit(state.copyWith(selectedHallId: hallId));
  }

  Future<int> addTable({
    required int hallId,
    required int number,
    int capacity = 4,
  }) async {
    final table = RestaurantTable(
      hallId: hallId,
      number: number,
      capacity: capacity,
    );
    final id = await _repository.addTable(table);
    await init();
    return id;
  }

  Future<void> updateTable(RestaurantTable table) async {
    await _repository.updateTable(table);
    await init();
  }

  Future<void> deleteTable(int id) async {
    await _repository.deleteTable(id);
    await init();
  }

  Future<void> updateStatus(
    int tableId,
    TableStatus status, {
    int? orderId,
  }) async {
    await _repository.updateTableStatus(tableId, status, orderId: orderId);
    await init();
  }

  Future<List<RestaurantOrder>> getTableOrders(int tableId) async {
    return await (_getTableOrders?.call(tableId) ??
        _repository.getTableOrders(tableId));
  }

  Future<double> payTable(int tableId, String paymentMethod) async {
    if (_payTable != null) {
      final total = await _payTable(tableId, paymentMethod);
      await init();
      return total;
    }
    final total = await _repository.payTable(tableId, paymentMethod);
    await init();
    return total;
  }
}
