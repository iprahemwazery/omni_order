import '../../../../domain/models/customer.dart';
import '../repositories/customer_repository.dart';

class GetCustomersUseCase {
  const GetCustomersUseCase(this._repository);

  final CustomerRepository _repository;

  Future<List<Customer>> call() => _repository.getCustomers();
}

class GetCustomerUseCase {
  const GetCustomerUseCase(this._repository);

  final CustomerRepository _repository;

  Future<Customer?> call(int id) {
    if (id <= 0) return Future.value();
    return _repository.getCustomer(id);
  }
}

class FindCustomerByPhoneUseCase {
  const FindCustomerByPhoneUseCase(this._repository);

  final CustomerRepository _repository;

  Future<Customer?> call(String phone) {
    final normalized = phone.trim();
    if (normalized.isEmpty) return Future.value();
    return _repository.getCustomerByPhone(normalized);
  }
}

class CreateCustomerUseCase {
  const CreateCustomerUseCase(this._repository);

  final CustomerRepository _repository;

  Future<int> call(Customer customer) async {
    final normalized = _normalizeCustomer(customer);
    _validateCustomer(normalized);
    await _ensureUnique(_repository, normalized);
    return _repository.addCustomer(normalized);
  }
}

class UpdateCustomerUseCase {
  const UpdateCustomerUseCase(this._repository);

  final CustomerRepository _repository;

  Future<void> call(Customer customer) async {
    if (customer.id == null || customer.id! <= 0) {
      throw ArgumentError('معرف العميل مطلوب.');
    }
    final normalized = _normalizeCustomer(customer);
    _validateCustomer(normalized);
    await _ensureUnique(_repository, normalized);
    return _repository.updateCustomer(normalized);
  }
}

class DeleteCustomerUseCase {
  const DeleteCustomerUseCase(this._repository);

  final CustomerRepository _repository;

  Future<void> call(int id) {
    if (id <= 0) throw ArgumentError('معرف العميل مطلوب.');
    return _repository.deleteCustomer(id);
  }
}

class AddCustomerLoyaltyPointsUseCase {
  const AddCustomerLoyaltyPointsUseCase(this._repository);

  final CustomerRepository _repository;

  Future<void> call({required int customerId, required int points}) async {
    if (customerId <= 0) throw ArgumentError('معرف العميل مطلوب.');
    if (points <= 0) throw ArgumentError('عدد النقاط يجب أن يكون أكبر من صفر.');
    final customer = await _repository.getCustomer(customerId);
    if (customer == null) throw StateError('العميل غير موجود.');
    return _repository.addLoyaltyPoints(customerId, points);
  }
}

Customer _normalizeCustomer(Customer customer) => customer.copyWith(
  name: customer.name.trim(),
  phone: customer.phone.trim(),
  address: customer.address.trim(),
  notes: customer.notes.trim(),
);

void _validateCustomer(Customer customer) {
  if (customer.name.isEmpty) {
    throw ArgumentError('اسم العميل مطلوب.');
  }
  if (customer.balance < 0) {
    throw ArgumentError('رصيد العميل لا يمكن أن يكون سالبًا.');
  }
  if (customer.loyaltyPoints < 0) {
    throw ArgumentError('نقاط الولاء لا يمكن أن تكون سالبة.');
  }
}

Future<void> _ensureUnique(
  CustomerRepository repository,
  Customer customer,
) async {
  final customers = await repository.getCustomers();
  final name = customer.name.toLowerCase();
  final phone = customer.phone;
  final duplicate = customers.any(
    (existing) =>
        existing.id != customer.id &&
        ((existing.name.trim().toLowerCase() == name) ||
            (phone.isNotEmpty && existing.phone == phone)),
  );
  if (duplicate) {
    throw StateError('يوجد عميل بالاسم أو رقم الهاتف نفسه.');
  }
}
