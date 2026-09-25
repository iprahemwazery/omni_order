import '../../../../domain/models/employee.dart';
import '../../../../domain/models/product.dart';
import '../../../../domain/models/store_settings.dart';
import '../../../../domain/models/summaries.dart';
import '../../../../domain/repositories/store_repository.dart';
import '../../domain/repositories/home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  const HomeRepositoryImpl(this._storeRepository);

  final StoreRepository _storeRepository;

  @override
  Future<SalesTotals> getSalesTotals() => _storeRepository.getSalesTotals();

  @override
  Future<List<Product>> getProducts() => _storeRepository.getProducts();

  @override
  Future<ExpenseTotals> getExpenseTotals() =>
      _storeRepository.getExpenseTotals();

  @override
  Future<List<Employee>> getActiveEmployees() =>
      _storeRepository.getActiveEmployees();

  @override
  Future<StoreSettings> getSettings() => _storeRepository.getSettings();
}
