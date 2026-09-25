import '../../../../domain/models/employee.dart';
import '../../../../domain/models/order.dart';
import '../../../../domain/models/rider_transaction.dart';
import '../../../../domain/repositories/store_repository.dart';
import '../../domain/repositories/rider_balance_repository.dart';

class RiderBalanceRepositoryImpl implements RiderBalanceRepository {
  const RiderBalanceRepositoryImpl(this._storeRepository);

  final StoreRepository _storeRepository;

  @override
  Future<List<Employee>> getDeliveryPersons() =>
      _storeRepository.getDeliveryPersons();

  @override
  Future<List<RiderTransaction>> getRiderTransactions(int riderId) =>
      _storeRepository.getRiderTransactions(riderId);

  @override
  Future<double> getRiderBalance(int riderId) =>
      _storeRepository.getRiderBalance(riderId);

  @override
  Future<int> addRiderTransaction(RiderTransaction transaction) =>
      _storeRepository.addRiderTransaction(transaction);

  @override
  Future<List<RestaurantOrder>> getRiderOutstandingOrders(int riderId) =>
      _storeRepository.getRiderOutstandingOrders(riderId);
}
