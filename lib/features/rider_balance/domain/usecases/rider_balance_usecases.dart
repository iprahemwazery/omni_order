import '../../../../domain/models/employee.dart';
import '../../../../domain/models/order.dart';
import '../../../../domain/models/rider_transaction.dart';
import '../repositories/rider_balance_repository.dart';

class RiderBalanceData {
  const RiderBalanceData({
    required this.riders,
    required this.balances,
    required this.transactions,
    required this.outstandingOrders,
  });

  final List<Employee> riders;
  final Map<int, double> balances;
  final Map<int, List<RiderTransaction>> transactions;
  final Map<int, List<RestaurantOrder>> outstandingOrders;
}

class GetRiderBalanceData {
  const GetRiderBalanceData(this._repository);

  final RiderBalanceRepository _repository;

  Future<RiderBalanceData> call() async {
    final riders = (await _repository.getDeliveryPersons())
        .where((rider) => rider.id != null)
        .toList(growable: false);
    final balances = <int, double>{};
    final transactions = <int, List<RiderTransaction>>{};
    final outstandingOrders = <int, List<RestaurantOrder>>{};

    for (final rider in riders) {
      final riderId = rider.id!;
      balances[riderId] = await _repository.getRiderBalance(riderId);
      transactions[riderId] = await _repository.getRiderTransactions(riderId);
      outstandingOrders[riderId] = await _repository.getRiderOutstandingOrders(
        riderId,
      );
    }

    return RiderBalanceData(
      riders: riders,
      balances: balances,
      transactions: transactions,
      outstandingOrders: outstandingOrders,
    );
  }
}

class GetRiderBalance {
  const GetRiderBalance(this._repository);

  final RiderBalanceRepository _repository;

  Future<double> call(int riderId) {
    _requirePositiveId(riderId);
    return _repository.getRiderBalance(riderId);
  }
}

class GetRiderTransactions {
  const GetRiderTransactions(this._repository);

  final RiderBalanceRepository _repository;

  Future<List<RiderTransaction>> call(int riderId) {
    _requirePositiveId(riderId);
    return _repository.getRiderTransactions(riderId);
  }
}

class GetRiderOutstandingOrders {
  const GetRiderOutstandingOrders(this._repository);

  final RiderBalanceRepository _repository;

  Future<List<RestaurantOrder>> call(int riderId) {
    _requirePositiveId(riderId);
    return _repository.getRiderOutstandingOrders(riderId);
  }
}

class RecordRiderSettlement {
  const RecordRiderSettlement(this._repository);

  final RiderBalanceRepository _repository;

  Future<int> call(int riderId, double amount, {String note = ''}) {
    return _recordTransaction(
      _repository,
      riderId: riderId,
      type: RiderTransactionType.settlement,
      amount: amount,
      note: note,
    );
  }
}

class RecordRiderAdvance {
  const RecordRiderAdvance(this._repository);

  final RiderBalanceRepository _repository;

  Future<int> call(int riderId, double amount, {String note = ''}) {
    return _recordTransaction(
      _repository,
      riderId: riderId,
      type: RiderTransactionType.advance,
      amount: amount,
      note: note,
    );
  }
}

Future<int> _recordTransaction(
  RiderBalanceRepository repository, {
  required int riderId,
  required RiderTransactionType type,
  required double amount,
  required String note,
}) {
  _requirePositiveId(riderId);
  if (!amount.isFinite || amount <= 0) {
    throw ArgumentError.value(amount, 'amount', 'must be greater than zero');
  }
  return repository.addRiderTransaction(
    RiderTransaction(
      riderId: riderId,
      type: type,
      amount: amount,
      note: note.trim(),
    ),
  );
}

void _requirePositiveId(int id) {
  if (id <= 0) {
    throw ArgumentError.value(id, 'id', 'must be greater than zero');
  }
}
