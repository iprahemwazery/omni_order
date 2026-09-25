import '../../../../domain/models/employee.dart';
import '../../../../domain/models/product.dart';
import '../../../../domain/models/store_settings.dart';
import '../../../../domain/models/summaries.dart';
import '../repositories/home_repository.dart';

class HomeDashboard {
  const HomeDashboard({
    required this.sales,
    required this.products,
    required this.expenses,
    required this.employees,
    required this.settings,
  });

  final SalesTotals sales;
  final List<Product> products;
  final ExpenseTotals expenses;
  final List<Employee> employees;
  final StoreSettings settings;

  int get productCount => products.length;

  int get activeEmployeeCount => employees.length;

  List<Product> get outOfStock =>
      products.where((product) => product.stock <= 0).toList(growable: false);

  List<Product> get lowStock => products
      .where(
        (product) =>
            product.stock > 0 &&
            product.lowStockThreshold > 0 &&
            product.stock <= product.lowStockThreshold,
      )
      .toList(growable: false);

  double get netToday => sales.today - expenses.today;
}

class GetHomeDashboardUseCase {
  const GetHomeDashboardUseCase(this._repository);

  final HomeRepository _repository;

  Future<HomeDashboard> call() async {
    final sales = await _repository.getSalesTotals();
    final products = await _repository.getProducts();
    final expenses = await _repository.getExpenseTotals();
    final employees = await _repository.getActiveEmployees();
    final settings = await _repository.getSettings();
    return HomeDashboard(
      sales: sales,
      products: products,
      expenses: expenses,
      employees: employees,
      settings: settings,
    );
  }
}

class GetHomeSettingsUseCase {
  const GetHomeSettingsUseCase(this._repository);

  final HomeRepository _repository;

  Future<StoreSettings> call() => _repository.getSettings();
}
