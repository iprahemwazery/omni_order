import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/customer.dart';
import '../../../domain/repositories/store_repository.dart';
import '../domain/usecases/customer_usecases.dart';

class CustomersState {
  final List<Customer> customers;
  final bool loading;
  final String? error;

  const CustomersState({
    this.customers = const [],
    this.loading = false,
    this.error,
  });

  CustomersState copyWith({
    List<Customer>? customers,
    bool? loading,
    String? error,
  }) {
    return CustomersState(
      customers: customers ?? this.customers,
      loading: loading ?? this.loading,
      error: error,
    );
  }

  int get totalLoyaltyPoints =>
      customers.fold<int>(0, (s, c) => s + c.loyaltyPoints);
}

class CustomersCubit extends Cubit<CustomersState> {
  CustomersCubit(
    this._repository, {
    GetCustomersUseCase? getCustomers,
    CreateCustomerUseCase? createCustomer,
    UpdateCustomerUseCase? updateCustomer,
    DeleteCustomerUseCase? deleteCustomer,
    AddCustomerLoyaltyPointsUseCase? addLoyaltyPoints,
  }) : _getCustomers = getCustomers,
       _createCustomer = createCustomer,
       _updateCustomer = updateCustomer,
       _deleteCustomer = deleteCustomer,
       _addLoyaltyPoints = addLoyaltyPoints,
       super(const CustomersState());

  final StoreRepository _repository;
  final GetCustomersUseCase? _getCustomers;
  final CreateCustomerUseCase? _createCustomer;
  final UpdateCustomerUseCase? _updateCustomer;
  final DeleteCustomerUseCase? _deleteCustomer;
  final AddCustomerLoyaltyPointsUseCase? _addLoyaltyPoints;

  Future<void> init() async {
    emit(state.copyWith(loading: true));
    try {
      final customers =
          await (_getCustomers?.call() ?? _repository.getCustomers());
      emit(CustomersState(customers: customers));
    } catch (e) {
      emit(state.copyWith(loading: false, error: 'تعذر تحميل العملاء: $e'));
    }
  }

  Future<String?> addCustomer(Customer customer) async {
    final trimmed = customer.name.trim();
    if (trimmed.isEmpty) return 'اكتب اسم العميل.';
    final exists = state.customers.any((c) => c.name.trim() == trimmed);
    if (exists) return 'العميل "$trimmed" موجود بالفعل.';
    if (_createCustomer != null) {
      await _createCustomer(customer);
    } else {
      await _repository.addCustomer(customer);
    }
    await init();
    return null;
  }

  Future<String?> updateCustomer(Customer customer) async {
    final trimmed = customer.name.trim();
    if (trimmed.isEmpty) return 'اكتب اسم العميل.';
    final exists = state.customers.any(
      (c) => c.id != customer.id && c.name.trim() == trimmed,
    );
    if (exists) return 'العميل "$trimmed" موجود بالفعل.';
    if (_updateCustomer != null) {
      await _updateCustomer(customer);
    } else {
      await _repository.updateCustomer(customer);
    }
    await init();
    return null;
  }

  Future<void> deleteCustomer(int id) async {
    if (_deleteCustomer != null) {
      await _deleteCustomer(id);
    } else {
      await _repository.deleteCustomer(id);
    }
    await init();
  }

  Future<void> addLoyaltyPoints(int customerId, int points) async {
    if (_addLoyaltyPoints != null) {
      await _addLoyaltyPoints(customerId: customerId, points: points);
    } else {
      await _repository.addLoyaltyPoints(customerId, points);
    }
    await init();
  }
}
