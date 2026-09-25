import '../../../../domain/models/employee.dart';
import '../../../../domain/models/product.dart';
import '../../../../domain/models/store_settings.dart';
import '../../../../domain/models/summaries.dart';

abstract interface class HomeRepository {
  Future<SalesTotals> getSalesTotals();

  Future<List<Product>> getProducts();

  Future<ExpenseTotals> getExpenseTotals();

  Future<List<Employee>> getActiveEmployees();

  Future<StoreSettings> getSettings();
}
