import '../../../../domain/models/customer.dart';

abstract interface class CustomerRepository {
  Future<List<Customer>> getCustomers();

  Future<int> addCustomer(Customer customer);

  Future<void> updateCustomer(Customer customer);

  Future<void> deleteCustomer(int id);

  Future<Customer?> getCustomer(int id);

  Future<Customer?> getCustomerByPhone(String phone);

  Future<void> addLoyaltyPoints(int customerId, int points);
}
