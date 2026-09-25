import '../../../../domain/models/customer.dart';
import '../../../../domain/repositories/store_repository.dart';
import '../../domain/repositories/customer_repository.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  const CustomerRepositoryImpl(this._storeRepository);

  final StoreRepository _storeRepository;

  @override
  Future<List<Customer>> getCustomers() => _storeRepository.getCustomers();

  @override
  Future<int> addCustomer(Customer customer) =>
      _storeRepository.addCustomer(customer);

  @override
  Future<void> updateCustomer(Customer customer) =>
      _storeRepository.updateCustomer(customer);

  @override
  Future<void> deleteCustomer(int id) => _storeRepository.deleteCustomer(id);

  @override
  Future<Customer?> getCustomer(int id) => _storeRepository.getCustomer(id);

  @override
  Future<Customer?> getCustomerByPhone(String phone) =>
      _storeRepository.getCustomerByPhone(phone);

  @override
  Future<void> addLoyaltyPoints(int customerId, int points) =>
      _storeRepository.addLoyaltyPoints(customerId, points);
}
