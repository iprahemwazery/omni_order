import '../../../../domain/models/order.dart';
import '../../../../domain/models/restaurant_table.dart';
import '../repositories/tables_repository.dart';

class GetTables {
  const GetTables(this._repository);

  final TablesRepository _repository;

  Future<List<RestaurantTable>> call({int? hallId}) async {
    if (hallId != null) {
      _requirePositiveId(hallId);
      return _repository.getTablesByHall(hallId);
    }
    return _repository.getTables();
  }
}

class GetTable {
  const GetTable(this._repository);

  final TablesRepository _repository;

  Future<RestaurantTable?> call(int tableId) {
    _requirePositiveId(tableId);
    return _repository.getTable(tableId);
  }
}

class AddTable {
  const AddTable(this._repository);

  final TablesRepository _repository;

  Future<int> call(RestaurantTable table) {
    _validateTable(table);
    return _repository.addTable(table);
  }
}

class UpdateTable {
  const UpdateTable(this._repository);

  final TablesRepository _repository;

  Future<void> call(RestaurantTable table) {
    _validateTable(table, requireId: true);
    return _repository.updateTable(table);
  }
}

class DeleteTable {
  const DeleteTable(this._repository);

  final TablesRepository _repository;

  Future<void> call(int tableId) {
    _requirePositiveId(tableId);
    return _repository.deleteTable(tableId);
  }
}

class UpdateTableStatus {
  const UpdateTableStatus(this._repository);

  final TablesRepository _repository;

  Future<void> call(int tableId, TableStatus status, {int? orderId}) {
    _requirePositiveId(tableId);
    if (orderId != null) _requirePositiveId(orderId);
    return _repository.updateTableStatus(tableId, status, orderId: orderId);
  }
}

class GetTableOrders {
  const GetTableOrders(this._repository);

  final TablesRepository _repository;

  Future<List<RestaurantOrder>> call(int tableId) {
    _requirePositiveId(tableId);
    return _repository.getTableOrders(tableId);
  }
}

class PayTable {
  const PayTable(this._repository);

  final TablesRepository _repository;

  Future<double> call(int tableId, String paymentMethod) {
    _requirePositiveId(tableId);
    final method = paymentMethod.trim();
    if (method.isEmpty) {
      throw ArgumentError.value(
        paymentMethod,
        'paymentMethod',
        'must not be empty',
      );
    }
    return _repository.payTable(tableId, method);
  }
}

void _validateTable(RestaurantTable table, {bool requireId = false}) {
  if (requireId) _requirePositiveId(table.id ?? 0);
  if (table.hallId <= 0) {
    throw ArgumentError.value(table.hallId, 'hallId', 'is invalid');
  }
  if (table.number <= 0) {
    throw ArgumentError.value(table.number, 'number', 'is invalid');
  }
  if (table.capacity <= 0) {
    throw ArgumentError.value(table.capacity, 'capacity', 'is invalid');
  }
}

void _requirePositiveId(int id) {
  if (id <= 0) {
    throw ArgumentError.value(id, 'id', 'must be greater than zero');
  }
}
