import '../../../../domain/models/employee.dart';
import '../../../../domain/models/order.dart';
import '../../../../domain/models/rider_transaction.dart';

abstract interface class RiderBalanceRepository {
  Future<List<Employee>> getDeliveryPersons();

  Future<List<RiderTransaction>> getRiderTransactions(int riderId);

  Future<double> getRiderBalance(int riderId);

  Future<int> addRiderTransaction(RiderTransaction transaction);

  Future<List<RestaurantOrder>> getRiderOutstandingOrders(int riderId);
}
